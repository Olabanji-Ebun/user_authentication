import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_authentication/admindashboard.dart';
import 'package:user_authentication/adminmiddleware.dart';
import 'package:user_authentication/firebase_options.dart';
import 'package:user_authentication/verifyemail.dart';
import 'package:user_authentication/wrapper.dart';
import 'package:user_authentication/login.dart';
import 'package:user_authentication/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const Wrapper()),
        GetPage(name: '/verify-email', page: () => const VerifyEmailPage()),
        GetPage(name: '/login', page: () => const Login()),
        GetPage(name: '/home', page: () => const Homepage()),
        GetPage(
          name: '/admin',
          page: () => AdminDashboard(),
          middlewares: [AdminMiddleware()]// Add this for protection
        ),
      ],
      // Fallback for unknown routes
      unknownRoute: GetPage(
        name: '/not-found',
        page: () => const Scaffold(body: Center(child: Text('Not Found'))),
      ),
    );
  }
}