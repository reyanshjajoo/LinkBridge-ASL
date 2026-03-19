import 'package:asl_app/screens/group_captioning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'translator_screen.dart';
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

  // Keep tab labels in one place so the app bar title and bottom nav never drift.
  static const List<String> _tabTitles = [
    "Camera",
    "Audio",
    "Reader",
    "Learn",
    "Account",
  ];

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7EFDD),
        elevation: 1,
        centerTitle: true,
        title: Text(
          _tabTitles[_index],
          style: const TextStyle(
            color: Color(0xFF3C3C3C),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_index == 4)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF3C3C3C)),
              onPressed: _signOut,
            ),
        ],
      ),

      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            const TranslatorScreen(),
            const GroupCaptioningScreen(),
            const TextReaderPage(),
            const EducationScreen(),
            _AccountPage(email: user?.email, onSignOut: _signOut),
          ],
        ),
      ),

      bottomNavigationBar: AnimatedBuilder(
        animation: _navController,
        builder: (context, child) {
          return BottomNavigationBar(
            currentIndex: _index,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF3C3C3C),
            unselectedItemColor: Colors.black54,
            backgroundColor: const Color(0xFFF7EFDD),
            elevation: 8,
            // Technical debt: this screen relies on the same tab order in
            // _tabTitles, IndexedStack.children, and nav items below.
            // If a tab is inserted/reordered, update all three together.
            items: [
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _navAnimations[0],
                  child: const Icon(Icons.pan_tool_alt_outlined),
                ),
                label: "Camera",
              ),
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _navAnimations[1],
                  child: const Icon(Icons.mic_none_outlined),
                ),
                label: "Audio",
              ),
              BottomNavigationBarItem(
                icon: ScaleTransition(
                  scale: _navAnimations[3],
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
                  scale: _navAnimations[4],
                  child: const Icon(Icons.person_outline),
                ),
                label: "Account",
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lightweight account summary shown in the fifth tab.
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
              color: const Color(0xFF3C3C3C),
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
              backgroundColor: const Color(0xFFF7EFDD),
              foregroundColor: const Color(0xFF3C3C3C),
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
