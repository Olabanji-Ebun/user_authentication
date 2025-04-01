import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('AdminMiddleware: User not authenticated');
      return RouteSettings(name: '/login');
    }

    // Fetch user data synchronously (consider caching to avoid async issues)
    FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((doc) {
      if (!doc.exists || !(doc.data()?['isAdmin'] ?? false)) {
        debugPrint('AdminMiddleware: Access denied');
        return RouteSettings(name: '/home');
      }
    }).catchError((error) {
      debugPrint('AdminMiddleware: Error fetching user data - $error');
      return RouteSettings(name: '/home');
    });

    return null;
  }
}
