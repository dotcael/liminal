import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _deptController = TextEditingController();

  String _role = 'student';
  bool _isLoginMode = true;
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // First check form validation
    if (!_formKey.currentState!.validate()) {
      Fluttertoast.showToast(
        msg: "Please fix the highlighted fields",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Debug prints (visible in terminal / VS Code debug console)
    print('=== AUTH ACTION STARTED ===');
    print('Mode: ${_isLoginMode ? "LOGIN" : "SIGNUP"}');
    print('Email: ${_emailController.text.trim()}');

    try {
      if (_isLoginMode) {
        // === LOGIN ===
        print('Trying to log in...');
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print('Login SUCCESS');
        Fluttertoast.showToast(
          msg: "Login successful!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        // === SIGNUP ===
        print('Trying to create account...');
        final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print('Account created – UID: ${credential.user?.uid}');

        print('Saving user profile to Firestore...');
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role,
          'class': _classController.text.trim(),
          'department': _deptController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Profile saved successfully');

        Fluttertoast.showToast(
          msg: "Account created successfully!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth ERROR: ${e.code} → ${e.message}');

      String userMessage = e.message ?? "Authentication failed";
      String code = e.code.toUpperCase();

      // Friendly messages
      if (e.code == 'invalid-email') userMessage = "Invalid email format";
      if (e.code == 'email-already-in-use')
        userMessage = "This email is already registered";
      if (e.code == 'weak-password')
        userMessage = "Password too weak (min 6 characters)";
      if (e.code == 'user-not-found')
        userMessage = "No account with this email";
      if (e.code == 'wrong-password') userMessage = "Incorrect password";
      if (e.code == 'too-many-requests')
        userMessage = "Too many attempts – wait a moment";

      Fluttertoast.showToast(
        msg: "$userMessage ($code)",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (e) {
      print('Unexpected error: $e');
      Fluttertoast.showToast(
        msg: "Unexpected error: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
    }

    // Always stop loading (even if error)
    if (mounted) {
      setState(() => _isLoading = false);
    }

    print('=== AUTH ACTION FINISHED ===');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Login' : 'Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password required';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                if (!_isLoginMode) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Name required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'rep',
                        child: Text('Academic Representative'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _role = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _classController,
                    decoration: const InputDecoration(
                      labelText: 'Class / Year',
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty ?? true ? 'Class required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deptController,
                    decoration: const InputDecoration(labelText: 'Department'),
                    validator: (v) => v?.trim().isEmpty ?? true
                        ? 'Department required'
                        : null,
                  ),
                ],
                const SizedBox(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text(_isLoginMode ? 'LOGIN' : 'CREATE ACCOUNT'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(
                    _isLoginMode
                        ? "Don't have an account? Sign up"
                        : 'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
