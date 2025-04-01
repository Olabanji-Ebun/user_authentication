import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:user_authentication/homepage.dart';
import 'package:user_authentication/login.dart';
import 'package:user_authentication/verifyemail.dart';


class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors in the auth stream
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final user = snapshot.data;

        // User is logged in
        if (user != null) {
          // Check email verification status
          if (user.emailVerified) {
            return const Homepage();
          } else {
            return const VerifyEmailPage();
          }
        }

        // User is not logged in
        return const Login();
      },
    );
  }
}