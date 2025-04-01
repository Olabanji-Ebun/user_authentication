import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_authentication/login.dart';
import 'package:user_authentication/verifyemail.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController username = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    username.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => _obscureText = !_obscureText);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmText = !_obscureConfirmText);
  }

  Future<void> _saveUserData(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'username': username.text.trim(),
        'email': email.text.trim(),
        'isAdmin': false, // New users default to non-admin
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      });
      debugPrint('User data saved successfully.');
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (password.text != confirmPassword.text) {
      Get.snackbar('Error', "Passwords don't match",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await _saveUserData(userCredential.user!.uid);
      await userCredential.user!.sendEmailVerification();

      // Close loading dialog
      if (Get.isDialogOpen ?? false) Get.back();

      // Redirect to verification page
      Get.off(() => VerifyEmailPage());

      Get.snackbar(
        'Success!',
        'Verification email sent. Please check your inbox.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } on FirebaseAuthException catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      String errorMessage = 'Signup failed';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Email already registered';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format';
          break;
      }

      Get.snackbar('Signup Failed', errorMessage,
          backgroundColor: Colors.red, colorText: Colors.white);

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      debugPrint('Signup error: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Header
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_add_outlined,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text("Create Account",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Signup to get started",
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[600])),
                  ],
                ),

                const SizedBox(height: 40),

                // Form Section
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                          controller: username,
                          label: 'Username',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          }),
                      const SizedBox(height: 16),
                      _buildTextField(
                          controller: email,
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          }),
                      const SizedBox(height: 16),
                      _buildPasswordField(password, 'Password',
                          _obscureText, _togglePasswordVisibility),
                      const SizedBox(height: 16),
                      _buildPasswordField(confirmPassword, 'Confirm Password',
                          _obscureConfirmText, _toggleConfirmPasswordVisibility),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Signup",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Footer Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account?",
                        style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: () => Get.off(() => const Login()),
                      child: const Text("Login",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label,
      bool obscureText, VoidCallback toggleVisibility) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off), onPressed: toggleVisibility),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
