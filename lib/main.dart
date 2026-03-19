import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

/// App entry point.
///
/// Ensures Flutter bindings and Firebase are ready before rendering UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

/// Root widget that defines global theme and named routes.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  /// Builds the top-level [MaterialApp] used across the project.
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF3C3C3C),
          selectionColor: Color(0xFFFFDAB9),
          selectionHandleColor: Color(0xFF3C3C3C),
        ),
      ),

      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginScreen(),
        "/register": (context) => const RegisterScreen(),
        "/home": (context) => const HomeScreen(),
      },
    );
  }
}
