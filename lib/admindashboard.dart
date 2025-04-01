import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:user_authentication/homepage.dart';
import 'package:user_authentication/login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyAdminStatus();
    _loadUsers();
  }

  Future<void> _verifyAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final isAdmin = userDoc.exists && userDoc.data()?['isAdmin'] == true;

    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => const Homepage());
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      if (!mounted) return;
      setState(() {
        _users = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load users: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirmDelete = await _showConfirmationDialog(
      'Delete User', 
      'Are you sure you want to delete this user?',
    );
    
    if (!confirmDelete) return;

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      await _firestore.collection('users').doc(userId).delete();
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAdminStatus(String userId, bool isAdmin) async {
    await _firestore.collection('users').doc(userId).update({'isAdmin': !isAdmin});
    _loadUsers();
  }

  Future<void> _editUsername(String userId, String currentUsername) async {
    final newUsernameController = TextEditingController(text: currentUsername);

    final confirmEdit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: newUsernameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmEdit != true) return;

    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      await _firestore.collection('users').doc(userId).update({
        'username': newUsernameController.text.trim(),
      });
      await _loadUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isAdmin = user['isAdmin'] ?? false;
        final username = user['username'] ?? 'No username set';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(user['email'], style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Username: $username'),
                Text(isAdmin ? 'Admin' : 'Regular User', 
                     style: TextStyle(color: isAdmin ? Colors.green : Colors.black)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editUsername(user.id, username),
                ),
                IconButton(
                  icon: Icon(Icons.admin_panel_settings, 
                            color: isAdmin ? Colors.green : Colors.grey),
                  onPressed: () => _toggleAdminStatus(user.id, isAdmin),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteUser(user.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Get.offAll(() => const Login());
      }
    });
  }

  void _showAddUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailController, 
                     decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, 
                     decoration: const InputDecoration(labelText: 'Password'), 
                     obscureText: true),
            TextField(controller: usernameController, 
                     decoration: const InputDecoration(labelText: 'Username')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), 
                   child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );
                await _firestore.collection('users').doc(userCredential.user!.uid).set({
                  'email': emailController.text.trim(),
                  'username': usernameController.text.trim(),
                  'isAdmin': false,
                });

                _loadUsers();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              } catch (e) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding user: ${e.toString()}'))
                    );
                  }
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}