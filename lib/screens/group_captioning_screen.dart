import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'caption_review_screen.dart';

class Caption {
  final String text;
  final String speaker;
  final DateTime receivedAt;
  final String source;

  Caption({
    required this.text,
    required this.speaker,
    required this.receivedAt,
    this.source = 'speech',
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'speaker': speaker,
      'receivedAt': receivedAt.toIso8601String(),
      'source': source,
    };
  }

  factory Caption.fromJson(Map<String, dynamic> json) {
    return Caption(
      text: json['text'],
      speaker: json['speaker'],
      receivedAt: DateTime.parse(json['receivedAt']),
      source: json['source'] ?? 'speech',
    );
  }
}

class GroupCaptioningScreen extends StatefulWidget {
  const GroupCaptioningScreen({super.key});

  @override
  State<GroupCaptioningScreen> createState() => _GroupCaptioningScreenState();
}

class _GroupCaptioningScreenState extends State<GroupCaptioningScreen> {
  // Phase 1: Audio Capture
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _hasPermission = false;

  // Phase 2: WebSocket Connection
  WebSocketChannel? _webSocketChannel;
  static const String _wsUrl =
      'wss://aslappserver.onrender.com/speech/ws'; // Update with your backend URL
  static const String _finalizeUrl =
      'https://aslappserver.onrender.com/speech/finalize'; // Update with your backend URL

  // Phase 5: Caption State Management
  final List<Caption> _captions = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _conversationId = '';

  // Phase 9: Error Handling
  String? _errorMessage;
  bool _isConnecting = false;
  bool _isEndingSession = false;

  void _showHelpOverlay() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('How to use Group Captioning'),
          content: const Text(
            '1. Make sure your microphone is allowed.\n'
            '2. Tap “Start Captioning” to connect and begin streaming audio.\n'
            '3. As people speak, live captions will appear in the list below.\n'
            '4. Use “End” to stop the session and finalize it.\n'
            '5. Tap the history button (clock icon) in the bottom-right to view past sessions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
    _generateConversationId();
  }

  @override
  void dispose() {
    _stopSession();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      setState(() {
        _hasPermission = status == PermissionStatus.granted;
      });

      if (!_hasPermission) {
        _showError('Microphone permission is required for group captioning');
      }
    } catch (e) {
      _showError('Failed to request microphone permission: $e');
    }
  }

  void _generateConversationId() {
    _conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Phase 2: Live Connection Setup
  Future<void> _connectWebSocket() async {
    if (_webSocketChannel != null) return;

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final uri = _buildWebSocketUri(_wsUrl, {
        'conversation_id': _conversationId,
      });
      print('[WS] Connecting to: $uri');
      _webSocketChannel = WebSocketChannel.connect(uri);
      print('[WS] WebSocketChannel created, waiting for stream...');

      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
      print('[WS] Stream listener attached');

      setState(() {
        _isConnecting = false;
      });
      print('[WS] Connection setup complete');
    } catch (e) {
      print('[WS] Connection error: $e');
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to connect to server: $e';
      });
    }
  }

  Uri _buildWebSocketUri(
    String rawUrl,
    Map<String, String> queryParameters,
  ) {
    final parsed = Uri.parse(rawUrl);

    final normalizedScheme = switch (parsed.scheme) {
      'ws' || 'wss' => parsed.scheme,
      'http' => 'ws',
      'https' => 'wss',
      _ => throw ArgumentError(
        'Unsupported WebSocket URL scheme: ${parsed.scheme}. Use ws, wss, http, or https.',
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

  // Phase 4: Receiving Live Captions
  void _handleWebSocketMessage(dynamic message) {
    print('[WS] Received message: $message');
    try {
      final data = json.decode(message);

      if (data['event'] == 'final_transcript') {
        final caption = Caption(
          text: data['text'] ?? '',
          speaker: data['speaker'] ?? 'Unknown',
          receivedAt: DateTime.now(),
        );

        setState(() {
          _captions.add(caption);
        });

        if (_autoScroll) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleWebSocketError(error) {
    print('[WS] Error: $error');
    unawaited(_terminateSession(errorMessage: 'Connection error: $error'));
  }

  void _handleWebSocketDone() {
    print('[WS] Connection closed (onDone)');
    if (_isEndingSession) return;
    unawaited(_terminateSession(errorMessage: 'Session ended by server.'));
  }

  // Phase 1: Audio Capture
  Future<void> _startAudioCapture() async {
    if (!_hasPermission) {
      _showError('Microphone permission not granted');
      return;
    }

    print('[Audio] Starting audio capture...');
    try {
      // Configure audio recording: 16kHz, Mono, 16-bit PCM
      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          bitRate: 16000,
          numChannels: 1,
        ),
      );

      setState(() {
        _isRecording = true;
      });
      print('[Audio] Recording started, streaming to server...');

      // Phase 3: Audio Streaming
      _streamAudioToServer(stream);
    } catch (e) {
      print('[Audio] Failed to start: $e');
      _showError('Failed to start audio capture: $e');
    }
  }

  Future<void> _stopAudioCapture() async {
    print('[Audio] Stopping audio capture...');
    try {
      await _audioRecorder.stop();
      print('[Audio] Audio recorder stopped');
      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      } else {
        _isRecording = false;
      }
    } catch (e) {
      print('[Audio] Error stopping audio capture: $e');
    }
  }

  // Phase 3: Audio Streaming
  int _chunkCount = 0;

  void _streamAudioToServer(Stream<Uint8List> audioStream) {
    if (_webSocketChannel == null) {
      print('[Audio] Cannot stream: WebSocket is null');
      return;
    }

    _chunkCount = 0;
    audioStream.listen(
      (audioData) {
        if (_webSocketChannel != null && audioData.isNotEmpty) {
          // Convert to Base64 and send
          final base64Audio = base64.encode(audioData);
          final message = {'event': 'audio_chunk', 'data': base64Audio};

          _webSocketChannel!.sink.add(json.encode(message));
          _chunkCount++;
          if (_chunkCount <= 5 || _chunkCount % 50 == 0) {
            print('[Audio] Sent chunk #$_chunkCount (${audioData.length} bytes)');
          }
        }
      },
      onError: (error) {
        print('[Audio] Stream error: $error');
      },
      onDone: () {
        print('[Audio] Stream ended. Total chunks sent: $_chunkCount');
      },
    );
  }

  // Phase 7: Session Control
  Future<void> _startSession() async {
    if (_isEndingSession) return;

    await _connectWebSocket();
    if (_webSocketChannel == null) {
      return;
    }

    await _startAudioCapture();
  }

  Future<void> _endSession() async {
    await _terminateSession();
  }

  Future<void> _closeWebSocket() async {
    if (_webSocketChannel != null) {
      print('[WS] Closing WebSocket...');
      try {
        await _webSocketChannel!.sink.close().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('[WS] Close timed out after 3s');
          },
        );
        print('[WS] WebSocket closed');
      } catch (e) {
        print('[WS] Error closing WebSocket: $e');
      }
      _webSocketChannel = null;
    } else {
      print('[WS] WebSocket already null, nothing to close');
    }
  }

  Future<void> _finalizeSession() async {
    print('[Session] Finalizing session with ${_captions.length} captions...');
    try {
      final response = await http.post(
        Uri.parse(_finalizeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversation_id': _conversationId,
          'captions': _captions.map((c) => c.toJson()).toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('[Session] Finalize successful');
      } else {
        print('[Session] Finalize failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[Session] Error finalizing session: $e');
    }
  }

  Future<void> _stopSession() async {
    await _terminateSession();
  }

  Future<void> _terminateSession({String? errorMessage}) async {
    if (_isEndingSession) return;
    _isEndingSession = true;
    print('[Session] Terminating session...');

    try {
      if (_webSocketChannel != null) {
        try {
          final endMessage = {'event': 'end'};
          _webSocketChannel!.sink.add(json.encode(endMessage));
          print('[Session] Sent end event');
        } catch (e) {
          print('[Session] Failed to send end event: $e');
        }
      }

      await _stopAudioCapture();
      await _closeWebSocket();
      await _finalizeSession();
      print('[Session] Termination complete');
    } finally {
      print('[Session] Resetting state flags...');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isConnecting = false;
          if (errorMessage != null) {
            _errorMessage = errorMessage;
          }
        });
      } else {
        _isRecording = false;
        _isConnecting = false;
      }

      _isEndingSession = false;
      print('[Session] Session fully terminated');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getSpeakerColor(String speaker) {
    final colors = [
      Color(0xFFC67C4E),
      Color(0xFFD4845E),
      Color(0xFFE8956E),
      Color(0xFFB8674E),
      Color(0xFFDDB5A0),
    ];

    final hash = speaker.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        title: const Text('Group Captioning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How this screen works',
            onPressed: _showHelpOverlay,
          ),
        ],
      ),
      body: Column(
        children: [
          // Error Display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),

          // Session Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isRecording || _isConnecting)
                        ? null
                        : _startSession,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: _isRecording ? Colors.red : Color(0xFFC67C4E),
                      foregroundColor: Colors.white,
                    ),
                    label: Text(
                      _isConnecting
                          ? 'Connecting...'
                          : _isRecording
                          ? 'Session Active'
                          : 'Start Captioning',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _endSession : null,
                  icon: const Icon(Icons.stop),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('End'),
                ),
              ],
            ),
          ),

          // Phase 6: Group Captioning Display
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.closed_caption, size: 20, color: Color(0xFF3C3C3C)),
                      const SizedBox(width: 8),
                      const Text(
                        "Live Captions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3C3C3C),
                        ),
                      ),
                      const Spacer(),
                      if (_captions.isNotEmpty)
                        Text(
                          "${_captions.length} messages",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFC67C4E),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFDDB5A0)),

                  Expanded(
                    child: _captions.isEmpty
                        ? const Center(
                            child: Text(
                              "No captions yet. Start a session to begin.",
                              style: TextStyle(
                                color: Color(0xFF8B6B5F),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _captions.length,
                            itemBuilder: (context, index) {
                              final caption = _captions[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDAB9).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border(
                                    left: BorderSide(
                                      color: _getSpeakerColor(caption.speaker),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      caption.speaker,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getSpeakerColor(
                                          caption.speaker,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      caption.text,
                                      style: const TextStyle(
                                        color: Color(0xFF3C3C3C),
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${caption.receivedAt.hour.toString().padLeft(2, '0')}:${caption.receivedAt.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        color: Color(0xFFC67C4E),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CaptionReviewScreen()),
          );
        },
        backgroundColor: const Color(0xFFC67C4E),
        child: const Icon(Icons.history),
        tooltip: 'View Caption History',
      ),
    );
  }
}
