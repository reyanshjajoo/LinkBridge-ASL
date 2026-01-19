import 'package:asl_app/screens/group_captioning_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'translator_screen.dart';
import 'education_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 122, 217, 168),

      // One scaffold for the whole app shell
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 1, // subtle separation from green background
  centerTitle: true,
  title: Text(
    _index == 0
        ? "Camera"
        : _index == 1
            ? "Audio"
            : _index == 2
                ? "Learn"
                : "Account",
    style: const TextStyle(
      color: Color.fromARGB(255, 20, 35, 28),
      fontWeight: FontWeight.w700,
    ),
  ),
  actions: [
    if (_index == 3)
      IconButton(
        icon: const Icon(
          Icons.logout,
          color: Color.fromARGB(255, 20, 35, 28),
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

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 60, 120, 88),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pan_tool_alt_outlined),
            label: "Camera",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_outlined),
            label: "Audio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: "Learn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Account",
          ),
        ],
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
              color: const Color.fromARGB(255, 60, 120, 88),
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
                  backgroundColor: Colors.white.withOpacity(0.25),
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
              backgroundColor: Colors.white,
              foregroundColor: const Color.fromARGB(255, 60, 120, 88),
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
