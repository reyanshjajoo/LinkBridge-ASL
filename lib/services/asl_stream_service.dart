import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat_message.dart';

/// Manages the ASL recognition WebSocket lifecycle and parsed message stream.
class AslStreamService {
  static const String _aslWsUrl = 'wss://aslappserver.onrender.com/asl/ws';
  static const int _maxMessages = 100;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final List<ChatMessage> _messages = [];
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  bool get isConnected => _channel != null;

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// Opens a WebSocket connection for ASL frame streaming.
  ///
  /// Parameters:
  /// - [conversationId]: Conversation context expected by the server.
  ///
  /// Returns when the channel is connected and listeners are attached.
  Future<void> connect({required String conversationId}) async {
    if (isConnected) {
      return;
    }

    final uri = Uri.parse(
      _aslWsUrl,
    ).replace(queryParameters: {'conversation_id': conversationId});

    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    _subscription = channel.stream.listen(
      _handleRawMessage,
      onDone: () {
        _channel = null;
      },
      onError: (_) {
        _channel = null;
      },
    );
  }

  /// Sends one camera frame to the ASL backend.
  ///
  /// Parameter:
  /// - [bytes]: Raw bytes from the latest camera frame.
  ///
  /// Frames are base64-encoded because the backend expects JSON payloads.
  void sendFrameBytes(Uint8List bytes) {
    final channel = _channel;
    if (channel == null || bytes.isEmpty) {
      return;
    }

    final encoded = base64.encode(bytes);
    channel.sink.add(
      jsonEncode({'event': 'frame', 'image': encoded, 'data': encoded}),
    );
  }

  /// Handles raw channel messages and emits normalized [ChatMessage] objects.
  void _handleRawMessage(dynamic raw) {
    final payload = _decodePayload(raw);
    if (payload == null) {
      return;
    }

    if (payload['event'] != 'asl_result') {
      return;
    }

    final text = _extractResultText(payload);
    if (text.isEmpty) {
      return;
    }

    final message = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      type: ChatMessage.typeAsl,
      speaker: null,
      createdAt: DateTime.now(),
    );

    _messages.add(message);
    if (_messages.length > _maxMessages) {
      _messages.removeAt(0);
    }

    _messageController.add(message);
  }

  /// Decodes a raw socket event into a JSON map when possible.
  ///
  /// Returns null for malformed payloads so callers can fail soft and keep
  /// the stream alive.
  Map<String, dynamic>? _decodePayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// Extracts recognized text from backend payload variants.
  ///
  /// Returns a trimmed non-empty value from text or word, or an empty
  /// string when neither key is usable.
  String _extractResultText(Map<String, dynamic> payload) {
    final text = payload['text'];
    if (text is String && text.trim().isNotEmpty) {
      return text.trim();
    }

    final word = payload['word'];
    if (word is String && word.trim().isNotEmpty) {
      return word.trim();
    }

    return '';
  }

  /// Clears in-memory message history kept for quick UI replay.
  void clearMessages() {
    _messages.clear();
  }

  /// Closes the WebSocket channel and cancels active subscriptions.
  ///
  /// Safe to call multiple times.
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;
  }

  /// Releases all service resources.
  ///
  /// Call this when the owning screen is disposed.
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
  }
}
