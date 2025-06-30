import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../Providers/auth_provider.dart';
import '../Screens/home_screen.dart';
import '../Screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // 🔄 Waiting for authentication stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✅ User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen(); // Show your main app screen
        }

        // 🔐 Not logged in
        return const LoginScreen(); // Show login/signup
      },
    );
  }
}
