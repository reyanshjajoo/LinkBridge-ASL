import 'dart:convert';

import 'package:http/http.dart' as http;

class ConversationService {
  ConversationService._();

  static final ConversationService instance = ConversationService._();
  static const String _baseUrl = 'https://aslappserver.onrender.com';

  String? _activeConversationId;

  String? get activeConversationId => _activeConversationId;

  void setActiveConversationId(String id) {
    _activeConversationId = id;
  }

  void clearActiveConversationId() {
    _activeConversationId = null;
  }

  String createLocalConversationId() {
    final id = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    _activeConversationId = id;
    return id;
  }

  Future<String> createConversation({String? customId}) async {
    final body = customId == null
        ? <String, dynamic>{}
        : {'conversation_id': customId};

    final resp = await http.post(
      Uri.parse('$_baseUrl/conversations'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (resp.statusCode != 201) {
      throw Exception('Failed to create conversation (${resp.statusCode})');
    }

    final payload = jsonDecode(resp.body) as Map<String, dynamic>;
    final id = payload['conversation_id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Conversation response missing conversation_id');
    }

    _activeConversationId = id;
    return id;
  }

  Future<String> getOrCreateConversation({
    bool forceNew = false,
    bool allowLocalFallback = false,
  }) async {
    if (!forceNew &&
        _activeConversationId != null &&
        _activeConversationId!.isNotEmpty) {
      return _activeConversationId!;
    }

    try {
      return createConversation();
    } catch (_) {
      if (!allowLocalFallback) {
        rethrow;
      }
      return createLocalConversationId();
    }
  }

  Future<void> finalizeConversation(String conversationId) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/speech/finalize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'conversation_id': conversationId}),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Failed to finalize conversation (${resp.statusCode})');
    }
  }

  Future<Map<String, dynamic>> fetchConversation(String id) async {
    final resp = await http.get(Uri.parse('$_baseUrl/conversations/$id'));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw Exception('Conversation not found (${resp.statusCode})');
  }

  Future<List<Map<String, dynamic>>> listConversations({int limit = 20}) async {
    final resp = await http.get(
      Uri.parse(
        '$_baseUrl/conversations',
      ).replace(queryParameters: {'limit': '$limit'}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to load conversations (${resp.statusCode})');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final conversations = body['conversations'];
    if (conversations is List) {
      return conversations.whereType<Map<String, dynamic>>().toList();
    }

    return [];
  }
}
