import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/speaker_profile.dart';
import '../services/conversation_service.dart';
import 'speaker_identification_screen.dart';
import 'group_captioning_screen.dart';

class SpeakerSetupScreen extends StatefulWidget {
  const SpeakerSetupScreen({super.key});

  @override
  State<SpeakerSetupScreen> createState() => _SpeakerSetupScreenState();
}

class _SpeakerSetupScreenState extends State<SpeakerSetupScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isConnecting = false;

  void _addField() {
    if (_controllers.length >= 6) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removeField(int index) {
    if (_controllers.length <= 2) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  List<SpeakerProfile> _buildProfiles() {
    return _controllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => SpeakerProfile(name: c.text.trim()))
        .toList();
  }

  Future<void> _startIdentifying() async {
    final profiles = _buildProfiles();
    if (profiles.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter at least 2 speaker names'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final conversationId = await ConversationService.instance
          .getOrCreateConversation(forceNew: true, allowLocalFallback: true);
      final uri = Uri.parse('wss://aslappserver.onrender.com/speech/ws')
          .replace(
            queryParameters: {
              'conversation_id': conversationId,
              'mode': 'identifying',
              'num_speakers': '${profiles.length}',
            },
          );
      final channel = WebSocketChannel.connect(uri);
      // Convert to broadcast stream so both screens can listen
      final broadcastStream = channel.stream.asBroadcastStream();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SpeakerIdentificationScreen(
            profiles: profiles,
            conversationId: conversationId,
            channel: channel,
            broadcastStream: broadcastStream,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _skipIdentification() async {
    setState(() => _isConnecting = true);

    try {
      final conversationId = await ConversationService.instance
          .getOrCreateConversation(forceNew: true, allowLocalFallback: true);

      final uri = Uri.parse('wss://aslappserver.onrender.com/speech/ws')
          .replace(
            queryParameters: {
              'conversation_id': conversationId,
              'mode': 'captioning',
            },
          );
      final channel = WebSocketChannel.connect(uri);
      final broadcastStream = channel.stream.asBroadcastStream();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GroupCaptioningScreen(
            speakers: const [],
            conversationId: conversationId,
            channel: channel,
            broadcastStream: broadcastStream,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start session: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        title: const Text('Speaker Setup'),
        backgroundColor: const Color(0xFFF7EFDD),
        foregroundColor: const Color(0xFF3C3C3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who\'s in this session?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C3C3C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the name of each speaker so captions show who said what.',
              style: TextStyle(color: Color(0xFF8B6B5F), fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Name fields
            Expanded(
              child: ListView.builder(
                itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFC67C4E),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers[index],
                            decoration: InputDecoration(
                              hintText: 'Speaker ${index + 1} name',
                              filled: true,
                              fillColor: const Color(0xFFFFF8F0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        if (_controllers.length > 2)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Add speaker button
            if (_controllers.length < 6)
              TextButton.icon(
                onPressed: _addField,
                icon: const Icon(Icons.add, color: Color(0xFFC67C4E)),
                label: const Text(
                  'Add speaker',
                  style: TextStyle(color: Color(0xFFC67C4E)),
                ),
              ),

            const SizedBox(height: 12),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnecting ? null : _startIdentifying,
                icon: _isConnecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.mic),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: const Color(0xFFC67C4E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: Text(
                  _isConnecting ? 'Connecting...' : 'Start Identifying',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isConnecting ? null : _skipIdentification,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  foregroundColor: const Color(0xFF3C3C3C),
                  side: const BorderSide(color: Color(0xFFC67C4E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Skip — use generic labels'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
