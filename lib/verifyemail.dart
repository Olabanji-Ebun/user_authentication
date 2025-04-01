import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:user_authentication/homepage.dart';
import 'package:user_authentication/login.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  late Timer _timer;
  bool _isLoading = true;
  bool _isEmailSent = false;
  bool _isSending = false;

  Future<void> signout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.closeAllSnackbars();
      Get.offAll(() => const Login());
    } catch (e) {
      Get.snackbar('Error', 'Could not sign out', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    _sendVerificationEmail();
  }

  Future<void> _sendVerificationEmail() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() => _isEmailSent = true);
      Get.snackbar('Success', 'Verification email sent',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error', 'Could not send verification email', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      
      if (user?.emailVerified ?? false) {
        timer.cancel();
        Get.closeAllSnackbars();
        Get.offAll(() => const Homepage());
      }
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    Get.closeAllSnackbars();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          TextButton(
            onPressed: signout,
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text('Checking verification status...'),
              ] else ...[
                Icon(Icons.email_outlined, size: 80, color: _isEmailSent ? Colors.green : Colors.grey),
                const SizedBox(height: 20),
                Text(_isEmailSent ? 'Verification email sent. Check your inbox.' : 'Sending verification email...'),
                const SizedBox(height: 30),
                const Text('Please verify your email to continue.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendVerificationEmail,
                  child: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Resend Email'),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: signout,
        tooltip: 'Return to Sign In',
        child: const Icon(Icons.logout),
      ),
    );
  }
}
