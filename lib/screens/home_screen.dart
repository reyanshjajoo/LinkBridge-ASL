import 'package:asl_app/screens/group_captioning_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'education_screen.dart';
import 'text_reader_page.dart';

/// App shell with persistent bottom navigation.
///
/// Each tab keeps its state alive via [IndexedStack], so users can switch
/// between tools without losing in-progress work.
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

    // Stagger each nav icon so the bar feels responsive on first load.
    _navAnimations = List.generate(4, (index) {
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
    // Sign-out can complete after this widget is removed, so guard navigation.
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  void _onNavTap(int index) {
    // Light haptics make tab changes feel intentional without being distracting.
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
    final shouldFloatNav = _index == 1;

    return Scaffold(
      backgroundColor: const Color(0xFFD7BE82), // Warm gold background
      // One scaffold for the whole app shell
      appBar: AppBar(
        backgroundColor: const Color(0xFF515A47), // Sage green for header
        elevation: 2,
        centerTitle: true,
        title: Text(
          _index == 0
              ? "Live Captions"
              : _index == 1
              ? "Reader"
              : _index == 2
              ? "Learn"
              : "Account",
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
              onPressed: () {},
            ),
          if (_index == 3)
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
              TextReaderPage(mode: _readerMode),
              const EducationScreen(),
              _AccountPage(email: user?.email, onSignOut: _signOut),
            ],
          ),
          if (_index == 1)
            Positioned(
              left: 16,
              right: 16,
              bottom: 156,
              child: Text(
                _readerMode == ReaderMode.single
                    ? "Point at text and tap Scan"
                    : "Hold phone at a readable angle",
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
              bottom: 94,
              child: _ReaderModeSwitcher(
                mode: _readerMode,
                onModeChanged: _setReaderMode,
              ),
            ),
          Positioned(
            left: shouldFloatNav ? 16 : 0,
            right: shouldFloatNav ? 16 : 0,
            bottom: shouldFloatNav ? 16 : 0,
            child: AnimatedBuilder(
              animation: _navController,
              builder: (context, child) {
                final navBar = BottomNavigationBar(
                  currentIndex: _index,
                  onTap: _onNavTap,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFF755C1B),
                  unselectedItemColor: Colors.black54,
                  backgroundColor: shouldFloatNav
                      ? Colors.transparent
                      : const Color(0xFFD7BE82),
                  elevation: shouldFloatNav ? 0 : 8,
                  items: [
                    BottomNavigationBarItem(
                      icon: ScaleTransition(
                        scale: _navAnimations[0],
                        child: const Icon(Icons.mic_none_outlined),
                      ),
                      label: "Live Captions",
                    ),
                    BottomNavigationBarItem(
                      icon: ScaleTransition(
                        scale: _navAnimations[1],
                        child: const Icon(Icons.text_fields),
                      ),
                      label: "Reader",
                    ),
                    BottomNavigationBarItem(
                      icon: ScaleTransition(
                        scale: _navAnimations[2],
                        child: const Icon(Icons.school_outlined),
                      ),
                      label: "Learn",
                    ),
                    BottomNavigationBarItem(
                      icon: ScaleTransition(
                        scale: _navAnimations[3],
                        child: const Icon(Icons.person_outline),
                      ),
                      label: "Account",
                    ),
                  ],
                );

                if (!shouldFloatNav) {
                  return navBar;
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7BE82).withOpacity(0.75),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: navBar,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
                "SINGLE",
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
                "ON THE GO",
                style: labelStyle(mode == ReaderMode.onTheGo),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight account summary shown in the fourth tab.
///
/// This widget stays intentionally read-only so sign-out remains the only
/// account action from the home shell.
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
                  backgroundColor: const Color(0xFFFFFDF0).withOpacity(0.25),
                  child: Text(
                    (email != null && email!.isNotEmpty)
                        ? email![0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Signed in",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? "Not signed in",
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
              "Sign Out",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
