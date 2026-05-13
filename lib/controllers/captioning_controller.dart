import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/caption.dart';
import '../models/speaker_profile.dart';
import '../services/speaker_label_mapper.dart';

/// Controller that manages group captioning sessions.
///
/// Responsibilities:
/// - Requesting microphone permission and starting/stopping audio capture.
/// - Opening and maintaining the WebSocket connection to the captioning backend.
/// - Streaming base64-encoded PCM audio chunks as `audio_chunk` events.
/// - Parsing incoming WebSocket events (e.g. `final_transcript`) and
///   converting them into `Caption` model instances exposed via `captions`.
/// - Finalizing a session by posting to the `/speech/finalize` endpoint.
class CaptioningController extends ChangeNotifier {
  static const bool _verboseCaptionLogs = true;
  static const String _wsUrl = 'wss://aslappserver.onrender.com/speech/ws';
  static const String _finalizeUrl =
      'https://aslappserver.onrender.com/speech/finalize';

  final AudioRecorder _audioRecorder = AudioRecorder();
  final SpeakerLabelMapper _labelMapper = SpeakerLabelMapper();

  final List<SpeakerProfile>? _speakers;
  final String? _seedConversationId;
  final WebSocketChannel? _seedChannel;
  final Stream? _seedBroadcastStream;

  final List<Caption> _captions = <Caption>[];

  WebSocketChannel? _webSocketChannel;
  bool _isRecording = false;
  bool _hasPermission = false;
  bool _isConnecting = false;
  bool _isEndingSession = false;
  bool _isDisposed = false;
  String _conversationId = '';
  String? _errorMessage;
  int? _genericSpeakerCount;

  int _chunkCount = 0;
  int _rxMessageCount = 0;
  int _finalTranscriptCount = 0;
  int _nonTranscriptEventCount = 0;

  CaptioningController({
    List<SpeakerProfile>? speakers,
    String? conversationId,
    WebSocketChannel? channel,
    Stream? broadcastStream,
  }) : _speakers = speakers,
       _seedConversationId = conversationId,
       _seedChannel = channel,
       _seedBroadcastStream = broadcastStream;

  bool get hasPreconnectedChannel => _seedChannel != null;
  UnmodifiableListView<Caption> get captions => UnmodifiableListView(_captions);
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  bool get isConnecting => _isConnecting;
  bool get isEndingSession => _isEndingSession;
  String get conversationId => _conversationId;
  String? get errorMessage => _errorMessage;

  void _notify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_speakers != null) {
      for (final profile in _speakers) {
        if (profile.speakerLabel != null) {
          _labelMapper.registerLabel(profile.speakerLabel!, profile.name);
        }
      }
    }

    if (hasPreconnectedChannel) {
      await _initializePreconnectedSession();
    } else {
      await requestMicrophonePermission();
      _generateConversationId();
    }
  }

  /// Ensure microphone permission and pre-register any supplied speakers.
  /// Call this once before starting a session.

  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      _hasPermission = status == PermissionStatus.granted;


  /// Start a captioning session.
  ///
  /// The `selectSpeakerCount` callback is invoked when named-speaker mode
  /// is required and must return an integer number of speakers (or `null`
  /// to cancel).
      if (!_hasPermission) {
        _setError('Microphone permission is required for group captioning');
        return false;
      }


  /// End the current captioning session and finalize on the server.
      _notify();
      return true;
    } catch (e) {
      _setError('Failed to request microphone permission: $e');
      return false;
    }
  }

  Future<void> _initializePreconnectedSession() async {
    final hasMicPermission = await requestMicrophonePermission();
    if (!hasMicPermission) {
      return;
    }

    _webSocketChannel = _seedChannel;
    _conversationId = _seedConversationId ?? '';

    (_seedBroadcastStream ?? _webSocketChannel!.stream).listen(
      _handleWebSocketMessage,
      onError: _handleWebSocketError,
      onDone: _handleWebSocketDone,
    );

    await _startAudioCapture();
  }

  void _generateConversationId() {
    _conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
    if (_verboseCaptionLogs) {
      print('[Session] Generated conversation_id=$_conversationId');
    }
    _notify();
  }

  Future<void> startSession({
    required Future<int?> Function() selectSpeakerCount,
  }) async {
    if (_isEndingSession) {
      return;
    }

    if (!_hasPermission) {
      final hasMicPermission = await requestMicrophonePermission();
      if (!hasMicPermission) {
        return;
      }
    }

    if (!hasPreconnectedChannel && _genericSpeakerCount == null) {
      final selectedCount = await selectSpeakerCount();
      if (selectedCount == null) {
        return;
      }
      _genericSpeakerCount = selectedCount;
      for (int i = 1; i <= selectedCount; i++) {
        _labelMapper.registerLabel('Speaker_$i', 'Speaker $i');
      }
    }

    await _connectWebSocket();
    if (_webSocketChannel == null) {
      return;
    }

    await _startAudioCapture();
  }

  Future<void> endSession() async {
    await _terminateSession();
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  Future<void> _connectWebSocket() async {
    if (_webSocketChannel != null) {
      return;
    }

    _isConnecting = true;
    _errorMessage = null;
    _notify();

    try {
      final uri = _buildWebSocketUri(_wsUrl, <String, String>{
        'conversation_id': _conversationId,
        if (_genericSpeakerCount != null)
          'num_speakers': _genericSpeakerCount.toString(),
      });

      if (_verboseCaptionLogs) {
        print('[WS] Connecting to: $uri');
        print(
          '[WS] Connect params: conversation_id=$_conversationId num_speakers=$_genericSpeakerCount hasPreconnected=$hasPreconnectedChannel',
        );
      }

      _webSocketChannel = WebSocketChannel.connect(uri);
      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );

      _isConnecting = false;
      _notify();
    } catch (e) {
      _isConnecting = false;
      _setError('Failed to connect to server: $e');
    }
  }

  Uri _buildWebSocketUri(String rawUrl, Map<String, String> queryParameters) {
    final parsed = Uri.parse(rawUrl);
    final normalizedScheme = switch (parsed.scheme) {
      'ws' || 'wss' => parsed.scheme,
      'http' => 'ws',
      'https' => 'wss',
      _ => throw ArgumentError(
        'Unsupported WebSocket URL scheme: ${parsed.scheme}.',
      ),
    };

    final mergedQuery = <String, String>{
      ...parsed.queryParameters,
      ...queryParameters,
    };

    if (parsed.hasPort && parsed.port > 0) {
      return parsed.replace(
        scheme: normalizedScheme,
        port: parsed.port,
        queryParameters: mergedQuery,
      );
    }

    return parsed.replace(
      scheme: normalizedScheme,
      queryParameters: mergedQuery,
    );
  }

  void _handleWebSocketMessage(dynamic message) {
    _rxMessageCount++;
    final raw = message?.toString() ?? '';

    if (_verboseCaptionLogs) {
      print(
        '[WS] RX #$_rxMessageCount raw_type=${message.runtimeType} raw_len=${raw.length} raw_preview=${raw.length > 140 ? raw.substring(0, 140) : raw}',
      );
    }

    try {
      final data = json.decode(raw);
      final event = data is Map<String, dynamic> ? data['event'] : null;
      if (_verboseCaptionLogs && data is Map<String, dynamic>) {
        print('[WS] Parsed event=$event keys=${data.keys.toList()}');
      }

      if (data is Map<String, dynamic> && data['event'] == 'final_transcript') {
        _finalTranscriptCount++;
        final rawSpeaker = data['speaker'] ?? 'Unknown';
        final displayName = _labelMapper.resolve(rawSpeaker);
        final text = (data['text'] ?? '').toString();

        if (_verboseCaptionLogs) {
          print(
            '[Caption] final_transcript #$_finalTranscriptCount speaker_raw=$rawSpeaker speaker_mapped=$displayName text_len=${text.length} text="$text"',
          );
        }

        _captions.add(
          Caption(text: text, speaker: displayName, receivedAt: DateTime.now()),
        );
        _notify();
      } else {
        _nonTranscriptEventCount++;
        if (_verboseCaptionLogs) {
          print(
            '[WS] Non-transcript event #$_nonTranscriptEventCount event=$event payload=$data',
          );
        }
      }
    } catch (e) {
      print('[WS] Error parsing WebSocket message: $e raw=$raw');
    }
  }

  void _handleWebSocketError(Object error) {
    print('[WS] Error: $error');
    unawaited(_terminateSession(errorMessage: 'Connection error: $error'));
  }

  void _handleWebSocketDone() {
    print('[WS] Connection closed (onDone)');
    if (_isEndingSession) {
      return;
    }
    unawaited(_terminateSession(errorMessage: 'Session ended by server.'));
  }

  Future<void> _startAudioCapture() async {
    if (!_hasPermission) {
      _setError('Microphone permission not granted');
      return;
    }

    try {
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          bitRate: 256000,
          numChannels: 1,
        ),
      );

      _isRecording = true;
      _notify();

      _streamAudioToServer(stream);
    } catch (e) {
      print('[Audio] Failed to start: $e');
      _setError('Failed to start audio capture: $e');
    }
  }

  Future<void> _stopAudioCapture() async {
    try {
      await _audioRecorder.stop();
    } catch (e) {
      print('[Audio] Error stopping audio capture: $e');
    }
    _isRecording = false;
    _notify();
  }

  void _streamAudioToServer(Stream<Uint8List> audioStream) {
    if (_webSocketChannel == null) {
      print('[Audio] Cannot stream: WebSocket is null');
      return;
    }

    _chunkCount = 0;
    audioStream.listen(
      (Uint8List audioData) {
        if (_webSocketChannel != null && audioData.isNotEmpty) {
          final base64Audio = base64.encode(audioData);
          _webSocketChannel!.sink.add(
            json.encode(<String, dynamic>{'event': 'audio_chunk', 'data': base64Audio}),
          );
          _chunkCount++;

          if (_verboseCaptionLogs) {
            final stats = _analyzePcmChunk(audioData);
            print(
              '[Audio] Sent chunk #$_chunkCount bytes=${audioData.length} b64_len=${base64Audio.length} samples=${stats['samples']} rms=${stats['rms']} peak=${stats['peak']} mean_abs=${stats['meanAbs']} zero_samples=${stats['zeroSamples']} preview_b64=${base64Audio.substring(0, math.min(24, base64Audio.length))}',
            );
          }
        }
      },
      onError: (Object error) {
        print('[Audio] Stream error: $error');
      },
      onDone: () {
        print('[Audio] Stream ended. Total chunks sent: $_chunkCount');
      },
    );
  }

  Map<String, String> _analyzePcmChunk(Uint8List bytes) {
    if (bytes.length < 2) {
      return <String, String>{
        'samples': '0',
        'rms': '0.00',
        'peak': '0',
        'meanAbs': '0.00',
        'zeroSamples': '0',
      };
    }

    final data = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    double sumSquares = 0;
    double sumAbs = 0;
    int peak = 0;
    int zeroSamples = 0;

    for (int i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little);
      final absSample = sample.abs();
      if (absSample > peak) {
        peak = absSample;
      }
      if (sample == 0) {
        zeroSamples++;
      }
      sumSquares += sample * sample;
      sumAbs += absSample;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    final meanAbs = sumAbs / sampleCount;
    return <String, String>{
      'samples': '$sampleCount',
      'rms': rms.toStringAsFixed(2),
      'peak': '$peak',
      'meanAbs': meanAbs.toStringAsFixed(2),
      'zeroSamples': '$zeroSamples',
    };
  }

  Future<void> _closeWebSocket() async {
    if (_webSocketChannel == null) {
      return;
    }

    try {
      await _webSocketChannel!.sink.close().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('[WS] Close timed out after 3s');
        },
      );
    } catch (e) {
      print('[WS] Error closing WebSocket: $e');
    }
    _webSocketChannel = null;
  }

  Future<void> _finalizeSession() async {
    try {
      final response = await http
          .post(
            Uri.parse(_finalizeUrl),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: json.encode(<String, dynamic>{
              'conversation_id': _conversationId,
              'captions': _captions.map((Caption c) => c.toJson()).toList(),
              'speaker_map': _labelMapper.registry,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        print('[Session] Finalize failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[Session] Error finalizing session: $e');
    }
  }

  Future<void> _terminateSession({String? errorMessage}) async {
    if (_isEndingSession) {
      return;
    }

    _isEndingSession = true;
    _notify();

    try {
      if (_webSocketChannel != null) {
        try {
          _webSocketChannel!.sink.add(json.encode(<String, dynamic>{'event': 'end'}));
          print(
            '[Session] Sent end event. chunks_sent=$_chunkCount ws_rx=$_rxMessageCount transcripts=$_finalTranscriptCount non_transcript_events=$_nonTranscriptEventCount',
          );
        } catch (e) {
          print('[Session] Failed to send end event: $e');
        }
      }

      await _stopAudioCapture();
      await _closeWebSocket();
      await _finalizeSession();
    } finally {
      _isRecording = false;
      _isConnecting = false;
      _genericSpeakerCount = null;
      if (errorMessage != null) {
        _errorMessage = errorMessage;
      }
      _isEndingSession = false;
      _notify();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_terminateSession());
    _audioRecorder.dispose();
    super.dispose();
  }
}
