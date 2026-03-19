import 'dart:convert';

import 'package:http/http.dart' as http;

/// Coordinates conversation IDs between local state and the backend API.
///
/// This keeps speech/ASL streams and review history tied to the same session.
class ConversationService {
  ConversationService._();

  static final ConversationService instance = ConversationService._();
  static const String _baseUrl = 'https://aslappserver.onrender.com';

  String? _activeConversationId;

  String? get activeConversationId => _activeConversationId;

  /// Marks a conversation ID as the active session for subsequent calls.
  ///
  /// Parameter:
  /// - [id]: Existing conversation identifier.
  void setActiveConversationId(String id) {
    _activeConversationId = id;
  }

  /// Clears the currently active conversation from local state.
  void clearActiveConversationId() {
    _activeConversationId = null;
  }

  /// Creates a local fallback conversation ID when the API is unavailable.
  ///
  /// Returns a timestamp-based ID and stores it as active.
  String createLocalConversationId() {
    final id = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    _activeConversationId = id;
    return id;
  }

  /// Requests a new conversation from the backend.
  ///
  /// Parameters:
  /// - [customId]: Optional server-side conversation ID override.
  ///
  /// Returns the created conversation ID.
  /// Throws an [Exception] when the API response is invalid.
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

  /// Returns an existing active conversation or creates a new one.
  ///
  /// Parameters:
  /// - [forceNew]: When true, always creates a fresh conversation.
  /// - [allowLocalFallback]: When true, uses a local ID if API creation fails.
  ///
  /// Returns a usable conversation ID for downstream streaming APIs.
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

  /// Finalizes a conversation so the backend can persist and index it.
  ///
  /// Parameter:
  /// - [conversationId]: Session identifier to finalize.
  ///
  /// Throws an [Exception] if the finalize request fails.
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

  /// Fetches one conversation and its metadata from the backend.
  ///
  /// Parameter:
  /// - [id]: Conversation identifier.
  ///
  /// Returns a decoded JSON map for that conversation.
  Future<Map<String, dynamic>> fetchConversation(String id) async {
    final resp = await http.get(Uri.parse('$_baseUrl/conversations/$id'));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw Exception('Conversation not found (${resp.statusCode})');
  }

  /// Lists recent conversations for caption history screens.
  ///
  /// Parameter:
  /// - [limit]: Maximum number of conversations to return.
  ///
  /// Returns a list of conversation maps. Invalid payloads return an empty list
  /// to keep the history view resilient to schema drift.
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
