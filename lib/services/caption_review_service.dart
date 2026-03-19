import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class CaptionReviewService {
  static const String _baseUrl =
      'https://aslappserver.onrender.com'; // Update with your backend URL

  // Retrieve full conversation and return chronological messages.
  static Future<List<ChatMessage>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/$conversationId'),
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
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/conversations',
        ).replace(queryParameters: {'limit': '$limit'}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawConversations = data['conversations'];
        if (rawConversations is! List) {
          return [];
        }

        return rawConversations
            .whereType<Map<String, dynamic>>()
            .map(_normalizeConversation)
            .toList();
      }
    } catch (e) {
      print('Error retrieving conversation list: $e');
    }

    return [];
  }

  static Map<String, dynamic> _normalizeConversation(Map<String, dynamic> raw) {
    final id = raw['conversation_id'] ?? raw['id'] ?? '';
    final createdAt = raw['created_at'] ?? raw['timestamp'] ?? '';
    final messageCount = raw['message_count'] ?? raw['caption_count'] ?? 0;
    final title = raw['title'] ?? raw['name'] ?? 'Conversation $id';

    return {
      ...raw,
      'id': id,
      'title': title,
      'created_at': createdAt,
      'message_count': messageCount,
    };
  }
}
