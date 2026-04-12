import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  //this is the constructor for the auth screen
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

//this is the state for the auth screen
//declaring email controller variables which use text editing controller to
class _AuthScreenState extends State<AuthScreen> {
  //get/trigger the value of email and password from text field

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _deptController = TextEditingController();

  //declaring a variable to store the role of the user which is
  //by default student
  String _role = 'student';
  bool _isLoginMode = true;
  bool _isLoading = false;

  //declaring a firebase auth instance and a firestore instance to interact with the firebase database
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  //Constant system wide UI colors. Couldve used ThemeData tho.
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _borderAccent = Color(0xFF3a3a6a);
  static const _accent = Color(0xFF4a4aaa);
  static const _accentLight = Color(0xFF7b7bcc);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textSecondary = Color(0xFF6b6b9a);

  @override
  //using the controllers when the widget is disposed to free up resources
  void dispose() {
    //dispose of the data that the below controllers will hold
    // Always dispose controllers to free memory when screen is removed
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _deptController.dispose();
    super.dispose(); // calling the super method to dispose the state of the widget
  }

  //Email validation for reps by (CHECKING) strictly using @ulk.ac.rw email
  bool _isValidRepEmail(String email) {
    return email.trim().endsWith('@ulk.ac.rw');
  }

  //local form validation to make sure no bs gets sent to the backend
  bool _validateForm() {
    //trimming the email to remove any leading or trailing spaces and shares them in the class
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

    //Sign up validation
    if (!_isLoginMode) {
      if (_nameController.text.trim().isEmpty) {
        _showToast("Please enter your full name", isError: true);
        return false;
      }

      if (_deptController.text.trim().isEmpty) {
        _showToast("Please enter your department", isError: true);
        return false;
      }

      // "valid address" is disclosed privately
      if (_role == 'rep' && !_isValidRepEmail(email)) {
        _showToast("Rep accounts require a @ulk.ac.rw email", isError: true);
        return false;
      }
    }

    return true;
  }

  // Reusable toast
  //ensures consistency among popup notis

  // app assumes its false unless called
  void _showToast(String msg, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: isError ? const Color(0xFF8a3a3a) : _accent,
      textColor: _textPrimary,
      toastLength: Toast.LENGTH_LONG, //Flutter length library defaults 3.5s
    );
  }

  // Main Authentication logic for both login and signup
  Future<void> _handleSubmit() async {
    if (!_validateForm()) return; // If validation fails, exit early

    setState(() => _isLoading = true); // Show loading indicator

    try {
      if (_isLoginMode) {
        final credential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final doc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get(); //get the user role from the firestore database

        final userRole = doc.data()?['role'] ?? 'student'; // if role exists use otherwise default to student
        final userName = doc.data()?['name'] ?? 'there'; // fetch name from Firestore

        _showToast("Welcome back.");

        // Navigate to home, passing the real role from Firestore
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(name: userName, role: userRole)),
          );
        }
      }
      //sign up logic
      else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        //save user profile to firestore
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
            MaterialPageRoute(builder: (context) => HomeScreen(name: _nameController.text.trim(), role: _role)),
          );
        }
      }
    }
    // Handling specific Firebase authentication errors
     on FirebaseAuthException catch (e) {
      String msg;

      if (_isLoginMode) {
        switch (e.code) {
          case 'invalid-email':
            msg = "Invalid email format";
            break;
          case 'user-not-found':
            msg = "No account found with this email";
            break;
          case 'wrong-password':
          case 'invalid-credential':
            msg = "Incorrect email or password";
            break;
          case 'user-disabled':
            msg = "This account has been disabled";
            break;
          case 'too-many-requests':
            msg = "Too many attempts — wait a moment";
            break;
          case 'network-request-failed':
            msg = "Network error — check your internet connection";
            break;
          default:
            msg = "Login failed. Please try again";
        }
      } else {
        switch (e.code) {
          case 'invalid-email':
            msg = "Invalid email format";
            break;
          case 'email-already-in-use':
            msg = "Email already registered";
            break;
          case 'weak-password':
            msg = "Password too weak (min 6 chars)";
            break;
          case 'operation-not-allowed':
            msg = "Signup is currently unavailable";
            break;
          case 'network-request-failed':
            msg = "Network error — check your internet connection";
            break;
          default:
            msg = "Account creation failed. Please try again";
        }
      }

      _showToast(msg, isError: true);
    } catch (e) {
      _showToast("Something went wrong. Please try again", isError: true);
    }
    if (mounted) setState(() => _isLoading = false); // Hide loading indicator
  }

  // Reusable input field
  // Keeps all fields visually consistent without repeating styling
  Widget _buildField({
    required String label,
    required TextEditingController controller,

    //password dotting if ticked (true)
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
         decoration: InputDecoration(
  border: InputBorder.none,
  filled: true,
  fillColor: _surface,
  contentPadding: const EdgeInsets.symmetric(
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

              //sign up mode
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

              //role selector
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

              //submit button
              //if it is loading and gets tapped do nothing else handle submit
              GestureDetector(
                onTap: _isLoading ? null : _handleSubmit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const Center(
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

              //toggle login or signup
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