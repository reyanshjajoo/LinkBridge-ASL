import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../asl/asl_translator_screen.dart';
import '../captioning/group_captioning_screen.dart';
import '../education/education_screen.dart';
import '../reader/text_reader_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _index = 0;
  ReaderMode _readerMode = ReaderMode.single;

  late AnimationController _navController;
  late List<Animation<double>> _navAnimations;

  @override
  void initState() {
    super.initState();

    _navController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _navAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _navController,
          curve: Interval(
            index * 0.1,
            0.6 + index * 0.1,
            curve: Curves.elasticOut,
          ),
        ),
      );
    });

    _navController.forward();
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _onNavTap(int index) {
    setState(() => _index = index);
    HapticFeedback.lightImpact();
  }

  void _setReaderMode(ReaderMode mode) {
    if (_readerMode == mode) return;
    setState(() => _readerMode = mode);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final navBar = BottomNavigationBar(
      currentIndex: _index,
      onTap: _onNavTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF755C1B),
      unselectedItemColor: Colors.black54,
      backgroundColor: const Color(0xFFD7BE82),
      elevation: 8.0,
      items: [
        BottomNavigationBarItem(
          icon: ScaleTransition(
            scale: _navAnimations[0],
            child: const Icon(Icons.mic_none_outlined),
          ),
          label: 'Captions',
        ),
        BottomNavigationBarItem(
          icon: ScaleTransition(
            scale: _navAnimations[1],
            child: const Icon(Icons.text_fields),
          ),
          label: 'Reader',
        ),
        BottomNavigationBarItem(
          icon: ScaleTransition(
            scale: _navAnimations[2],
            child: const Icon(Icons.sign_language),
          ),
          label: 'ASL',
        ),
        BottomNavigationBarItem(
          icon: ScaleTransition(
            scale: _navAnimations[3],
            child: const Icon(Icons.school_outlined),
          ),
          label: 'Learn',
        ),
        BottomNavigationBarItem(
          icon: ScaleTransition(
            scale: _navAnimations[4],
            child: const Icon(Icons.person_outline),
          ),
          label: 'Account',
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFD7BE82),
      appBar: AppBar(
        backgroundColor: const Color(0xFF515A47),
        elevation: 2,
        centerTitle: true,
        title: Text(
          _index == 0
              ? 'Captions'
              : _index == 1
              ? 'Reader'
              : _index == 2
              ? 'ASL Translator'
              : _index == 3
              ? 'Learn'
              : 'Account',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_index == 0)
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'How this screen works',
              onPressed: () {},
            ),
          if (_index == 1)
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'How this screen works',
              onPressed: _showReaderHelp,
            ),
          if (_index == 2)
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'How this screen works',
              onPressed: _showAslTranslatorHelp,
            ),
          if (_index == 4)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut,
            ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              const GroupCaptioningScreen(),
              _index == 1
                  ? TextReaderPage(mode: _readerMode)
                  : const SizedBox.shrink(),
              _index == 2
                  ? const AslTranslatorScreen()
                  : const SizedBox.shrink(),
              const EducationScreen(),
              _AccountPage(email: user?.email, onSignOut: _signOut),
            ],
          ),
          if (_index == 1)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomInset + 96,
              child: Text(
                _readerMode == ReaderMode.single
                    ? 'Point at text and tap Scan'
                    : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                ),
              ),
            ),
          if (_index == 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 24,
              child: _ReaderModeSwitcher(
                mode: _readerMode,
                onModeChanged: _setReaderMode,
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _navController,
        builder: (context, child) => navBar,
      ),
    );
  }

  void _showAslTranslatorHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ASL Translator'),
          content: const SingleChildScrollView(
            child: Text(
              'This feature records a short video of a signed word, sends it to the translation service, and shows the most likely result.\n\nHow to use:\n- Hold RECORD to start recording.\n- Sign one clear word in front of the camera.\n- Release RECORD to stop, or wait for the 4 second timer.\n- Wait for processing, then review the prediction and tap Speak if you want it read aloud.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _showReaderHelp() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reader'),
          content: const SingleChildScrollView(
            child: Text(
              'This screen uses the camera to read text from signs, labels, or pages.\n\nHow to use:\n- In Single mode, point the camera at text and tap Scan.\n- In On-the-Go mode, the app scans automatically and can read text aloud.\n- Use the mute button to stop spoken output.\n- Tap the mode switcher to change between manual and automatic scanning.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}

class _ReaderModeSwitcher extends StatelessWidget {
  const _ReaderModeSwitcher({required this.mode, required this.onModeChanged});

  final ReaderMode mode;
  final ValueChanged<ReaderMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    TextStyle labelStyle(bool selected) => TextStyle(
      color: selected ? Colors.white : Colors.white70,
      fontSize: 17,
      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => onModeChanged(ReaderMode.single),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                'SINGLE',
                style: labelStyle(mode == ReaderMode.single),
              ),
            ),
          ),
          const SizedBox(width: 28),
          GestureDetector(
            onTap: () => onModeChanged(ReaderMode.onTheGo),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                'ON THE GO',
                style: labelStyle(mode == ReaderMode.onTheGo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  final String? email;
  final Future<void> Function() onSignOut;

  const _AccountPage({required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF515A47),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  color: Colors.black26,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(
                    0xFFFFFDF0,
                  ).withValues(alpha: 0.25),
                  child: Text(
                    (email != null && email!.isNotEmpty)
                        ? email![0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Signed in',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'Not signed in',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: const Color(0xFF7A4419),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
