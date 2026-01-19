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
      'ws://10.0.2.2:5000/speech/ws'; // Update with your backend URL
  static const String _finalizeUrl =
      'http://10.0.2.2:5000/speech/finalize'; // Update with your backend URL

  // Phase 5: Caption State Management
  final List<Caption> _captions = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  String _conversationId = '';

  // Phase 9: Error Handling
  String? _errorMessage;
  bool _isConnecting = false;

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
      final uri = Uri.parse('$_wsUrl?conversation_id=$_conversationId');
      _webSocketChannel = WebSocketChannel.connect(uri);

      _webSocketChannel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );

      setState(() {
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Failed to connect to server: $e';
      });
    }
  }

  // Phase 4: Receiving Live Captions
  void _handleWebSocketMessage(dynamic message) {
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
    setState(() {
      _errorMessage = 'Connection error: $error';
    });
  }

  void _handleWebSocketDone() {
    setState(() {
      _webSocketChannel = null;
    });
  }

  // Phase 1: Audio Capture
  Future<void> _startAudioCapture() async {
    if (!_hasPermission) {
      _showError('Microphone permission not granted');
      return;
    }

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

      // Phase 3: Audio Streaming
      _streamAudioToServer(stream);
    } catch (e) {
      _showError('Failed to start audio capture: $e');
    }
  }

  Future<void> _stopAudioCapture() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping audio capture: $e');
    }
  }

  // Phase 3: Audio Streaming
  void _streamAudioToServer(Stream<Uint8List> audioStream) {
    if (_webSocketChannel == null) return;

    audioStream.listen(
      (audioData) {
        if (_webSocketChannel != null && audioData.isNotEmpty) {
          // Convert to Base64 and send
          final base64Audio = base64.encode(audioData);
          final message = {'event': 'audio_chunk', 'data': base64Audio};

          _webSocketChannel!.sink.add(json.encode(message));
        }
      },
      onError: (error) {
        print('Audio stream error: $error');
      },
    );
  }

  // Phase 7: Session Control
  Future<void> _startSession() async {
    await _connectWebSocket();
    await _startAudioCapture();
  }

  Future<void> _endSession() async {
    // Send end event
    if (_webSocketChannel != null) {
      final endMessage = {'event': 'end'};
      _webSocketChannel!.sink.add(json.encode(endMessage));
    }

    await _stopAudioCapture();
    await _closeWebSocket();
    await _finalizeSession();
  }

  Future<void> _closeWebSocket() async {
    if (_webSocketChannel != null) {
      await _webSocketChannel!.sink.close();
      _webSocketChannel = null;
    }
  }

  Future<void> _finalizeSession() async {
    try {
      final response = await http.post(
        Uri.parse(_finalizeUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversation_id': _conversationId,
          'captions': _captions.map((c) => c.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to finalize session: ${response.statusCode}');
      }
    } catch (e) {
      print('Error finalizing session: $e');
    }
  }

  Future<void> _stopSession() async {
    await _endSession();
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
    setState(() {
      _errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Color _getSpeakerColor(String speaker) {
    final colors = [
      Colors.blue.shade700,
      Colors.green.shade700,
      Colors.purple.shade700,
      Colors.orange.shade700,
      Colors.teal.shade700,
    ];

    final hash = speaker.hashCode;
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 122, 217, 168),
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
                      backgroundColor: _isRecording ? Colors.red : Colors.green,
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
                color: const Color.fromARGB(255, 60, 120, 88),
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
                      const Icon(Icons.closed_caption, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Live Captions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (_captions.isNotEmpty)
                        Text(
                          "${_captions.length} messages",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 20),

                  Expanded(
                    child: _captions.isEmpty
                        ? const Center(
                            child: Text(
                              "No captions yet. Start a session to begin.",
                              style: TextStyle(
                                color: Colors.white70,
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
                                  color: Colors.white.withOpacity(0.1),
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
                                        color: Colors.white,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${caption.receivedAt.hour.toString().padLeft(2, '0')}:${caption.receivedAt.minute.toString().padLeft(2, '0')}",
                                      style: const TextStyle(
                                        color: Colors.white60,
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
        backgroundColor: const Color.fromARGB(255, 33, 97, 140),
        child: const Icon(Icons.history),
        tooltip: 'View Caption History',
      ),
    );
  }
}
