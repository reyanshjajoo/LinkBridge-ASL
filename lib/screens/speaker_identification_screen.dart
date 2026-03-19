import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import '../models/speaker_profile.dart';
import 'group_captioning_screen.dart';

enum IdentificationState { waiting, listening, detected, error }

class SpeakerIdentificationScreen extends StatefulWidget {
  final List<SpeakerProfile> profiles;
  final String conversationId;
  final WebSocketChannel channel;
  final Stream broadcastStream;

  const SpeakerIdentificationScreen({
    super.key,
    required this.profiles,
    required this.conversationId,
    required this.channel,
    required this.broadcastStream,
  });

  @override
  State<SpeakerIdentificationScreen> createState() =>
      _SpeakerIdentificationScreenState();
}

class _SpeakerIdentificationScreenState
    extends State<SpeakerIdentificationScreen> {
  final AudioRecorder _recorder = AudioRecorder();
  int _currentIndex = 0;
  IdentificationState _state = IdentificationState.waiting;
  late StreamSubscription _wsSub;
  bool _wsSubCancelled = false;
  StreamSubscription? _audioSub;
  Timer? _timeoutTimer;
  int _chunkCount = 0;

  @override
  void initState() {
    super.initState();
    _wsSub = widget.broadcastStream.listen(
      _handleMessage,
      onError: _handleError,
      onDone: _handleDone,
    );
    _initializeIdentification();
  }

  Future<void> _initializeIdentification() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for identification'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _state = IdentificationState.error);
      return;
    }
    _promptCurrentSpeaker();
  }

  void _handleMessage(dynamic raw) {
    final data = json.decode(raw);
    if (data['event'] == 'speaker_detected') {
      debugPrint('[ID] speaker_detected: ${data['label']}');
      _onSpeakerDetected(data['label']);
    } else if (data['event'] == 'captioning_started') {
      debugPrint('[ID] captioning_started received');
      unawaited(_navigateToCaptioning());
    }
  }

  void _handleError(dynamic error) {
    if (!mounted) return;
    _showErrorDialog('Connection lost. Please start over.');
  }

  void _handleDone() {
    if (!mounted) return;
    _showErrorDialog('Connection closed unexpectedly. Please start over.');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Connection Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // back to setup
            },
            child: const Text('Start Over'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptCurrentSpeaker() async {
    _chunkCount = 0;
    setState(() => _state = IdentificationState.waiting);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _state = IdentificationState.listening);
    await _startStreaming();
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 15), _onTimeout);
  }

  Future<void> _startStreaming() async {
    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          bitRate: 16000,
          numChannels: 1,
        ),
      );
      debugPrint('[ID] Microphone stream started');
      _audioSub = stream.listen(
        (chunk) {
          if (chunk.isEmpty) return;
          try {
            widget.channel.sink.add(
              json.encode({
                'event': 'audio_chunk',
                'data': base64.encode(chunk),
              }),
            );
            _chunkCount++;
            if (_chunkCount <= 5 || _chunkCount % 50 == 0) {
              debugPrint(
                '[ID] Sent audio chunk #$_chunkCount (${chunk.length} bytes)',
              );
            }
          } catch (e) {
            debugPrint('[ID] Failed sending audio chunk: $e');
          }
        },
        onError: (error) {
          debugPrint('[ID] Microphone stream error: $error');
        },
        onDone: () {
          debugPrint('[ID] Microphone stream ended after $_chunkCount chunks');
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start microphone stream: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _state = IdentificationState.error);
    }
  }

  Future<void> _stopStreaming() async {
    _timeoutTimer?.cancel();
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
  }

  void _onSpeakerDetected(String label) async {
    // Don't stop streaming — keep audio flowing to maintain diarization context
    _timeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      widget.profiles[_currentIndex].speakerLabel = label;
      widget.profiles[_currentIndex].isConfirmed = true;
      _state = IdentificationState.detected;
    });
    debugPrint('[ID] Speaker ${_currentIndex + 1} detected: $label');

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (_currentIndex + 1 < widget.profiles.length) {
      setState(() => _currentIndex++);
      // Audio is already streaming — just reset timeout for next speaker
      _chunkCount = 0;
      setState(() => _state = IdentificationState.waiting);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _state = IdentificationState.listening);
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 15), _onTimeout);
    } else {
      await _stopStreaming();
      _finishIdentification();
    }
  }

  Future<void> _finishIdentification() async {
    // Register speakers with server (fire-and-forget)
    _registerSpeakers();

    // Request mode switch
    widget.channel.sink.add(json.encode({'event': 'begin_captioning'}));
  }

  Future<void> _registerSpeakers() async {
    try {
      await http.post(
        Uri.parse('https://aslappserver.onrender.com/speech/register_speakers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'conversation_id': widget.conversationId,
          'speakers': widget.profiles
              .where((p) => p.isConfirmed)
              .map((p) => p.toJson())
              .toList(),
        }),
      );
    } catch (_) {
      // fire-and-forget
    }
  }

  Future<void> _navigateToCaptioning() async {
    if (!_wsSubCancelled) {
      _wsSubCancelled = true;
      await _wsSub.cancel();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GroupCaptioningScreen(
          speakers: widget.profiles.where((p) => p.isConfirmed).toList(),
          conversationId: widget.conversationId,
          channel: widget.channel,
          broadcastStream: widget.broadcastStream,
        ),
      ),
    );
  }

  void _onTimeout() {
    if (_state != IdentificationState.listening) return;
    _stopStreaming();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _chunkCount == 0
              ? 'No microphone audio chunks were captured.'
              : 'Audio sent ($_chunkCount chunks), but no speaker was detected.',
        ),
        backgroundColor: Colors.red,
      ),
    );
    setState(() => _state = IdentificationState.error);
  }

  void _retryCurrentSpeaker() {
    _promptCurrentSpeaker();
  }

  void _reidentifyAll() {
    _stopStreaming();
    // Tell server to clear seen labels so re-identification works
    widget.channel.sink.add(json.encode({'event': 'reset_identification'}));
    setState(() {
      _currentIndex = 0;
      for (final p in widget.profiles) {
        p.speakerLabel = null;
        p.isConfirmed = false;
      }
    });
    _promptCurrentSpeaker();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _audioSub?.cancel();
    if (!_wsSubCancelled) {
      _wsSubCancelled = true;
      unawaited(_wsSub.cancel());
    }
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = widget.profiles[_currentIndex];
    final progress = (_currentIndex + 1) / widget.profiles.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        title: const Text('Identify Speakers'),
        backgroundColor: const Color(0xFFF7EFDD),
        foregroundColor: const Color(0xFF3C3C3C),
        actions: [
          if (_currentIndex > 0 || _state == IdentificationState.error)
            TextButton(
              onPressed: _reidentifyAll,
              child: const Text(
                'Re-identify All',
                style: TextStyle(color: Color(0xFFC67C4E)),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFDDB5A0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC67C4E),
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              'Speaker ${_currentIndex + 1} of ${widget.profiles.length}',
              style: const TextStyle(color: Color(0xFF8B6B5F), fontSize: 13),
            ),
            const SizedBox(height: 40),

            // Speaker name prompt
            Text(
              currentProfile.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C3C3C),
              ),
            ),
            const SizedBox(height: 12),

            // State-dependent UI
            if (_state == IdentificationState.waiting)
              const Text(
                'Get ready...',
                style: TextStyle(fontSize: 18, color: Color(0xFF8B6B5F)),
              ),

            if (_state == IdentificationState.listening) ...[
              const Text(
                'Please say something now',
                style: TextStyle(fontSize: 18, color: Color(0xFFC67C4E)),
              ),
              const SizedBox(height: 30),
              _buildPulsingMic(),
            ],

            if (_state == IdentificationState.detected) ...[
              const SizedBox(height: 20),
              const Icon(Icons.check_circle, size: 72, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                '${currentProfile.name} identified!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],

            if (_state == IdentificationState.error) ...[
              const SizedBox(height: 20),
              const Icon(Icons.error_outline, size: 72, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'No speech detected. Try again?',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retryCurrentSpeaker,
                icon: const Icon(Icons.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC67C4E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text('Retry'),
              ),
            ],

            const Spacer(),

            // Confirmed speakers list
            if (_currentIndex > 0) ...[
              const Divider(color: Color(0xFFDDB5A0)),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Confirmed:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C3C3C),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.profiles
                    .where((p) => p.isConfirmed)
                    .map(
                      (p) => Chip(
                        avatar: const Icon(Icons.check, size: 16),
                        label: Text(p.name),
                        backgroundColor: const Color(0xFFF7EFDD),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingMic() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      onEnd: () {
        // Restart animation by rebuilding
        if (mounted && _state == IdentificationState.listening) {
          setState(() {});
        }
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFC67C4E).withValues(alpha: 0.2),
        ),
        child: const Icon(Icons.mic, size: 48, color: Color(0xFFC67C4E)),
      ),
    );
  }
}
