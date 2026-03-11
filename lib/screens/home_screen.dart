import 'package:asl_app/screens/group_captioning_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'translator_screen.dart';
import 'education_screen.dart';
import 'text_reader_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _index = 0;

  late AnimationController _navController;
  late List<Animation<double>> _navAnimations;

  @override
  void initState() {
    super.initState();

    _navController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create staggered animations for nav items
    _navAnimations = List.generate(4, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _navController,
        curve: Interval(
          index * 0.1,
          0.6 + index * 0.1,
          curve: Curves.elasticOut,
        ),
      ));
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
    Navigator.pushReplacementNamed(context, "/login");
  }

  Widget _buildCurrentPage(User? user) {
    switch (_index) {
      case 0:
        return const TranslatorScreen();
      case 1:
        return const GroupCaptioningScreen();
      case 2:
        return const EducationScreen();
      case 3:
        return const TextReaderPage();
      case 4:
      default:
        return _AccountPage(
          email: user?.email,
          onSignOut: _signOut,
        );
    }
  }

  void _onNavTap(int index) {
    setState(() => _index = index);
    // Add haptic feedback or subtle animation here
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFDAB9),

      // One scaffold for the whole app shell
      appBar: AppBar(
  backgroundColor: const Color(0xFFF7EFDD),
  elevation: 1, // subtle separation from green background
  centerTitle: true,
  title: Text(
    _index == 0
        ? "Camera"
        : _index == 1
            ? "Audio"
            : _index == 2
                ? "Learn"
                : _index == 3
                ? "Reader"
                : "Account",
    style: const TextStyle(
      color: Color(0xFF3C3C3C),
      fontWeight: FontWeight.w700,
    ),
  ),
  actions: [
    if (_index == 3)
      IconButton(
        icon: const Icon(
          Icons.logout,
          color: Color(0xFF3C3C3C),
        ),
        onPressed: _signOut,
      ),
  ],
),


      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            // These screens should ideally NOT create their own Scaffold/AppBar.
            // If they currently do, scroll down to the note below.
            const TranslatorScreen(),
            const GroupCaptioningScreen(),
            const EducationScreen(),

            // Account tab (simple, no card)
            _AccountPage(
              email: user?.email,
              onSignOut: _signOut,
            ),
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
        },
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  final String? email;
  final Future<void> Function() onSignOut;

  const _AccountPage({
    required this.email,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 18),

          // Profile header
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

          // Sign out button (primary)
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
