//copy code [code im copying from]

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

  // ─── Design system constants ───────────────────────────────────────────────
  // These match the agreed dark navy + indigo color scheme across all screens
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _borderAccent = Color(0xFF3a3a6a);
  static const _accent = Color(0xFF4a4aaa);
  static const _accentLight = Color(0xFF7b7bcc);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textSecondary = Color(0xFF6b6b9a);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _deptController.dispose();
    super.dispose();
  }

  // ─── SECURITY: ULK email validation for rep accounts ──────────────────────
  // Reps must use an @ulk.ac.rw email to prevent students
  // from registering as academic representatives
  bool _isValidRepEmail(String email) {
    return email.trim().endsWith('@ulk.ac.rw');
  }

  // ─── Form validation ───────────────────────────────────────────────────────
  // Catches empty fields locally before making any Firebase calls
  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast("Please fill in all fields", isError: true);
      return false;
    }

    if (!email.contains('@')) {
      _showToast("Invalid email format", isError: true);
      return false;
    }

    if (password.length < 6) {
      _showToast("Password must be at least 6 characters", isError: true);
      return false;
    }

    // Signup-only validation
    if (!_isLoginMode) {
      if (_nameController.text.trim().isEmpty) {
        _showToast("Please enter your full name", isError: true);
        return false;
      }

      if (_deptController.text.trim().isEmpty) {
        _showToast("Please enter your department", isError: true);
        return false;
      }

      // SECURITY: Rep accounts require ULK email
      if (_role == 'rep' && !_isValidRepEmail(email)) {
        _showToast("Rep accounts require a @ulk.ac.rw email", isError: true);
        return false;
      }
    }

    return true;
  }

  // ─── Toast helper ──────────────────────────────────────────────────────────
  // Reusable toast so we don't repeat styling everywhere
  void _showToast(String msg, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: isError ? const Color(0xFF8a3a3a) : _accent,
      textColor: _textPrimary,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  // ─── Main auth handler ─────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    // Run validation first — stop here if anything is wrong
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // ── LOGIN ──────────────────────────────────────────────────────────
        final credential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // ROLE FIX: After login, fetch the user's actual role from Firestore
        // We don't trust the role selector on screen — we read what was
        // saved during signup. This role will be passed to HomeScreen
        // so it knows what features to show (student vs rep)
        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        final userRole = doc.data()?['role'] ?? 'student';

        _showToast("Welcome back.");

        // Navigate to home, passing the real role from Firestore
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(role: userRole)),
          );
        }
      } else {
        // ── SIGNUP ─────────────────────────────────────────────────────────
        final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Save user profile to Firestore
        // class is optional for reps — stored as empty string if not provided
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role, // 'student' or 'rep'
          'class': _classController.text.trim(), // optional for reps
          'department': _deptController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showToast("Account created.");

     
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(role: _role)),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Firebase-specific errors with friendly messages
      String msg = "Authentication failed";
      if (e.code == 'invalid-email') msg = "Invalid email format";
      if (e.code == 'email-already-in-use') msg = "Email already registered";
      if (e.code == 'weak-password') msg = "Password too weak (min 6 chars)";
      if (e.code == 'user-not-found') msg = "No account with this email";
      if (e.code == 'wrong-password') msg = "Incorrect password";
      if (e.code == 'too-many-requests')
        msg = "Too many attempts — wait a moment";
        
      _showToast(msg, isError: true);
    } catch (e) {
      _showToast("Unexpected error: $e", isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ─── Reusable input field ──────────────────────────────────────────────────
  // Keeps all fields visually consistent without repeating styling
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderAccent, width: 0.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 13, color: _textPrimary),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              const Text(
                'Liminal',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),

              const SizedBox(height: 6),
              const Text(
                'Your academic task manager',
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),

              const SizedBox(height: 32),

              // ── Always shown fields ───────────────────────────────────────
              _buildField(
                label: 'Email',
                controller: _emailController,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _buildField(
                label: 'Password',
                controller: _passwordController,
                obscure: true,
              ),

              // ── Signup-only fields ────────────────────────────────────────
              // These only appear when the user is in signup mode
              if (!_isLoginMode) ...[
                const SizedBox(height: 14),
                _buildField(label: 'Full name', controller: _nameController),
                const SizedBox(height: 14),

                // Class is optional for reps — label reflects this
                _buildField(
                  label: _role == 'rep'
                      ? 'Class / Year (optional for reps)'
                      : 'Class / Year',
                  controller: _classController,
                ),
                const SizedBox(height: 14),
                _buildField(label: 'Department', controller: _deptController),
              ],

              const SizedBox(height: 24),

              // ── Role selector ─────────────────────────────────────────────
              // Shown on both login and signup
              // On login it's visual only — real role is fetched from Firestore
              // On signup it determines what role gets saved
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role',
                      style: TextStyle(fontSize: 11, color: _textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _role = 'student'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _role == 'student'
                                    ? const Color(0xFF3a3a7a)
                                    : _surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Student',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _role == 'student'
                                      ? _textPrimary
                                      : _textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _role = 'rep'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _role == 'rep'
                                    ? const Color(0xFF3a3a7a)
                                    : _surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Rep',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _role == 'rep'
                                      ? _textPrimary
                                      : _textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit button ─────────────────────────────────────────────
              GestureDetector(
                onTap: _isLoading ? null : _handleSubmit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: _textPrimary,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Login' : 'Create Account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Toggle login / signup ─────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: _isLoginMode
                              ? "Don't have an account? "
                              : "Already have an account? ",
                        ),
                        TextSpan(
                          text: _isLoginMode ? 'Sign up' : 'Login',
                          style: const TextStyle(color: _accentLight),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
