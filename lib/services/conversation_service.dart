import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:asl_app/utils/app_config.dart';

import 'session_manager.dart';

/// Coordinates conversation IDs between local state and the backend API.
///
/// This keeps speech/ASL streams and review history tied to the same session.
class ConversationService {
  ConversationService._();

  static final ConversationService instance = ConversationService._();
  // Use AppConfig.baseUrl for all runtime endpoints.

  String? _activeConversationId;
  String? _activeAccessorId;

  String? get activeConversationId => _activeConversationId;

  Map<String, String> _accessorHeaders(String accessorId) => {
    'X-User-Id': accessorId,
    'X-Firebase-Uid': accessorId,
    'X-Conversation-UUID': accessorId,
  };

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
    _activeAccessorId = null;
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
    final conversationUuid = await SessionManager.instance
        .getConversationUuid();
    final body = customId == null
        ? <String, dynamic>{'conversation_uuid': conversationUuid}
        : {'conversation_id': customId, 'conversation_uuid': conversationUuid};

    final resp = await http.post(
      AppConfig.httpUri('/conversations'),
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
    _activeAccessorId = conversationUuid;
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
    final conversationUuid = await SessionManager.instance
        .getConversationUuid();
    if (!forceNew &&
        _activeConversationId != null &&
        _activeConversationId!.isNotEmpty &&
        _activeAccessorId == conversationUuid) {
      return _activeConversationId!;
    }

    try {
      return createConversation();
    } catch (_) {
      if (!allowLocalFallback) {
        rethrow;
      }
      final id = createLocalConversationId();
      _activeAccessorId = conversationUuid;
      return id;
    }
  }

  /// Finalizes a conversation so the backend can persist and index it.
  ///
  /// Parameter:
  /// - [conversationId]: Session identifier to finalize.
  ///
  /// Throws an [Exception] if the finalize request fails.
  Future<void> finalizeConversation(String conversationId) async {
    final conversationUuid = await SessionManager.instance
        .getConversationUuid();
    final resp = await http.post(
      AppConfig.httpUri('/speech/finalize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'conversation_id': conversationId,
        'conversation_uuid': conversationUuid,
      }),
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
    final conversationUuid = await SessionManager.instance
        .getConversationUuid();
    final resp = await http.get(
      AppConfig.httpUri(
        '/conversations/$id',
      ).replace(queryParameters: {'conversation_uuid': conversationUuid}),
      headers: _accessorHeaders(conversationUuid),
    );
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
    final conversationUuid = await SessionManager.instance
        .getConversationUuid();
    final resp = await http.get(
      AppConfig.httpUri('/conversations').replace(
        queryParameters: {
          'limit': '$limit',
          'conversation_uuid': conversationUuid,
        },
      ),
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
