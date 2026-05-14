// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asl_app/utils/app_config.dart';
import '../models/chat_message.dart';
import 'session_manager.dart';

class CaptionReviewService {
  // Use `AppConfig.baseUrl` for runtime endpoints.

  static Map<String, String> _accessorHeaders(String accessorId) => {
    'X-User-Id': accessorId,
    'X-Firebase-Uid': accessorId,
    'X-Conversation-UUID': accessorId,
  };

  // Retrieve full conversation and return chronological messages.
  static Future<List<ChatMessage>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final conversationUuid = await SessionManager.instance
          .getConversationUuid();
      final response = await http.get(
        AppConfig.httpUri(
          '/conversations/$conversationId',
        ).replace(queryParameters: {'conversation_uuid': conversationUuid}),
        headers: _accessorHeaders(conversationUuid),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawMessages = data['messages'];

        if (rawMessages is! List) {
          return [];
        }

        return rawMessages
            .whereType<Map<String, dynamic>>()
            .map(ChatMessage.fromJson)
            .toList();
      }
    } catch (e) {
      print('Error retrieving conversation: $e');
    }

    return [];
  }

  // Get list of all conversations.
  static Future<List<Map<String, dynamic>>> getConversationList({
    int limit = 20,
  }) async {
    try {
      final conversationUuid = await SessionManager.instance
          .getConversationUuid();
      final response = await http.get(
        AppConfig.httpUri('/conversations').replace(
          queryParameters: {
            'limit': '$limit',
            'conversation_uuid': conversationUuid,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawConversations = data['conversations'];
        if (rawConversations is! List) {
          return [];
        }

        final normalized = rawConversations
            .whereType<Map<String, dynamic>>()
            .map(_normalizeConversation)
            .toList();

        final enriched = await Future.wait(normalized.map(_enrichConversation));

        return enriched;
      }
    } catch (e) {
      print('Error retrieving conversation list: $e');
    }

    return [];
  }

  static Map<String, dynamic> _normalizeConversation(Map<String, dynamic> raw) {
    final id = raw['conversation_id'] ?? raw['id'] ?? '';
    final createdAt = _extractTimestamp(raw);
    final messageCount = _extractMessageCount(raw);
    final title =
        raw['display_name'] ??
        raw['title'] ??
        raw['name'] ??
        'Conversation $id';

    return {
      ...raw,
      'id': id,
      'title': title,
      'created_at': createdAt,
      'message_count': messageCount,
    };
  }

  static int _extractMessageCount(Map<String, dynamic> raw) {
    final direct = raw['message_count'] ?? raw['caption_count'];
    if (direct is int) {
      return direct;
    }
    if (direct is String) {
      return int.tryParse(direct) ?? 0;
    }

    final messages = raw['messages'];
    if (messages is List) {
      return messages.length;
    }

    return 0;
  }

  static String _extractTimestamp(Map<String, dynamic> raw) {
    final createdAt = raw['created_at'];
    if (createdAt != null && createdAt.toString().isNotEmpty) {
      return createdAt.toString();
    }

    final updatedAt = raw['updated_at'];
    if (updatedAt != null && updatedAt.toString().isNotEmpty) {
      return updatedAt.toString();
    }

    final fallback = raw['timestamp'];
    if (fallback != null && fallback.toString().isNotEmpty) {
      return fallback.toString();
    }

    return '';
  }

  static Future<Map<String, dynamic>> _enrichConversation(
    Map<String, dynamic> conversation,
  ) async {
    final id = (conversation['id'] ?? '').toString();
    if (id.isEmpty) {
      return conversation;
    }

    try {
      final conversationUuid = await SessionManager.instance
          .getConversationUuid();
      final response = await http.get(
        AppConfig.httpUri(
          '/conversations/$id/messages',
        ).replace(queryParameters: {'conversation_uuid': conversationUuid}),
        headers: _accessorHeaders(conversationUuid),
      );
      if (response.statusCode != 200) {
        return conversation;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final messages = data['messages'];
      if (messages is! List) {
        return conversation;
      }

      final messageCount = messages.length;
      String createdAt = (conversation['created_at'] ?? '').toString();
      String title = (conversation['title'] ?? '').toString();
      if ((createdAt.isEmpty || createdAt == 'null') && messages.isNotEmpty) {
        final first = messages.first;
        if (first is Map<String, dynamic>) {
          final firstCreatedAt = first['created_at'];
          if (firstCreatedAt != null && firstCreatedAt.toString().isNotEmpty) {
            createdAt = firstCreatedAt.toString();
          }
        }
      }

      if ((title.isEmpty ||
              title == 'null' ||
              title.startsWith('Conversation ')) &&
          messages.isNotEmpty) {
        title = _deriveTitleFromMessages(messages);
      }

      return {
        ...conversation,
        'title': title,
        'message_count': messageCount,
        'created_at': createdAt,
      };
    } catch (_) {
      return conversation;
    }
  }

  static String _deriveTitleFromMessages(List<dynamic> messages) {
    for (final item in messages) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final text = item['text']?.toString().trim() ?? '';
      if (text.isEmpty) {
        continue;
      }

      return text.replaceAll(RegExp(r'\s+'), ' ');
    }

    return 'Untitled Conversation';
  }
}
