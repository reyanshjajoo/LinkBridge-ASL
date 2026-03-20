import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/caption_review_service.dart';

class CaptionReviewScreen extends StatefulWidget {
  const CaptionReviewScreen({super.key});

  @override
  State<CaptionReviewScreen> createState() => _CaptionReviewScreenState();
}

class _CaptionReviewScreenState extends State<CaptionReviewScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await CaptionReviewService.getConversationList();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load conversations: $e';
        _isLoading = false;
      });
    }
  }

  void _viewConversation(String conversationId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationDetailScreen(
          conversationId: conversationId,
          title: title,
        ),
      ),
    );
  }

  int _messageCount(Map<String, dynamic> conversation) {
    final value = conversation['message_count'];
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  String _formatHistoryTimestamp(dynamic rawValue) {
    final parsed = _parseTimestamp(rawValue);
    if (parsed == null) {
      return 'Unknown time';
    }

    final local = parsed.toLocal();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final dayDiff = todayStart.difference(messageDay).inDays;

    final timeText = _formatTime(local);
    if (dayDiff == 0) {
      return 'Today at $timeText';
    }
    if (dayDiff == 1) {
      return 'Yesterday at $timeText';
    }

    final month = _monthNames[local.month - 1];
    return '$month ${local.day}, ${local.year} at $timeText';
  }

  DateTime? _parseTimestamp(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    if (rawValue is DateTime) {
      return rawValue;
    }

    if (rawValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawValue, isUtc: true);
    }

    final text = rawValue.toString().trim();
    if (text.isEmpty || text == 'null') {
      return null;
    }

    final asInt = int.tryParse(text);
    if (asInt != null) {
      return DateTime.fromMillisecondsSinceEpoch(asInt, isUtc: true);
    }

    return DateTime.tryParse(text);
  }

  String _formatTime(DateTime dt) {
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BE82), // Warm gold background
      appBar: AppBar(
        backgroundColor: const Color(0xFF515A47), // Sage green header
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: _conversations.isEmpty
            ? const Text(
                'Start a captioning session',
                style: TextStyle(color: Colors.white),
              )
            : const Text(
                'Caption History',
                style: TextStyle(color: Colors.white),
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _conversations.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.white54),
                  SizedBox(height: 16),
                  Text(
                    "No saved caption sessions yet",
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Start a group captioning session to see it here",
                    style: TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                ],
              ),
            )
          : Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
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
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  final messageCount = _messageCount(conversation);
                  final messageLabel = messageCount == 1
                      ? 'message'
                      : 'messages';
                  final prettyTimestamp = _formatHistoryTimestamp(
                    conversation['created_at'],
                  );
                  return Card(
                    color: Colors.white,
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFE8D3B9),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFC67C4E),
                        child: const Icon(Icons.forum, color: Colors.white),
                      ),
                      title: Text(
                        conversation['title'] ?? 'Untitled Conversation',
                        style: const TextStyle(
                          color: Color(0xFF3C3C3C),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                      subtitle: Text(
                        '$messageCount $messageLabel • $prettyTimestamp',
                        style: const TextStyle(color: Color(0xFF8B6B5F)),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFFC67C4E),
                        size: 16,
                      ),
                      onTap: () => _viewConversation(
                        conversation['id'] ?? '',
                        conversation['title'] ?? 'Untitled',
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class ConversationDetailScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const ConversationDetailScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCaptions();
  }

  Future<void> _loadCaptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await CaptionReviewService.getConversationMessages(
        widget.conversationId,
      );
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load captions: $e';
        _isLoading = false;
      });
    }
  }

  Color _getSpeakerColor(String speaker) {
    final colors = [
      const Color(0xFF7A4419), // Rich Brown
      const Color(0xFF755C1B), // Darker Brown
      const Color(0xFFD7BE82), // Warm Gold/Tan
      const Color(0xFF515A47), // Muted Sage Green
      const Color(0xFF400406), // Deep Maroon
    ];

    final hash = speaker.hashCode;
    return colors[hash.abs() % colors.length];
  }

  String _displaySpeaker(ChatMessage message) {
    if (message.speaker != null && message.speaker!.trim().isNotEmpty) {
      return message.speaker!;
    }

    if (message.type == ChatMessage.typeAsl) {
      return 'ASL';
    }

    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7BE82), // Warm gold background
      appBar: AppBar(
        backgroundColor: const Color(0xFF515A47), // Sage green header
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCaptions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _messages.isEmpty
          ? const Center(
              child: Text(
                "No captions found for this conversation",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            )
          : Container(
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
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final speakerName = _displaySpeaker(message);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAB9).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(
                          color: _getSpeakerColor(speakerName),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          speakerName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getSpeakerColor(speakerName),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.text,
                          style: const TextStyle(
                            color: Color(0xFF3C3C3C),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}",
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
    );
  }
}
