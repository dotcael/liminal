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
  //declaring email controller variables which use text  editing controller to
  //get/trigger the value of email and password from text field

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _classController = TextEditingController();

  //declaring a variable to store the role of the user which is
  //by default student and also declaring a boolean variable to check if the user is login or not and another boolean variable to show loading indicator when the user is signing up or logging in
  String _role = 'Student';
  bool _isLoginMode = true;
  bool _isLoading = false;

  //declaring a firebase auth instance and a firestore instance to interact with the firebase database
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  //Constant system wide UI colors. Couldve used  ThemeData tho.
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
    //disposefo the data that the below controllers will hold
    // Always dispose controllers to free memory when screen is removed
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _deptController.dispose();
    _classController.dispose();
    super
        .dispose(); //  calling the super method to dispose the state of the widget
  }

  //Email validation for reps by (CHECKING) strictly using @ulk.ac.rw email

  bool _isValidRepEmail(String email) {
    return email.trim().endsWith('@ulk.ac.rw');
  }

  //local form validation to make sure no bs gets sent to the backend
  bool _validateForm() {
    //trimming the email to remove any leading or trailing spaces and shares thm inn the class
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast("Please  fill in all fields", isError: true);
      return false;
    }
    if (!email.contains('@')) {
      _showToast('Please enter a valid email address', isError: true);
      return false;
    }
    if (password.length < 8) {
      _showToast('Password must be at least 8 characters', isError: true);
      return false;
    }

    //Sign up validation

    if (!_isLoginMode) {
      if (_nameController.text.trim().isEmpty) {
        _showToast('Please enter your full name', isError: true);
        return false;
      }

      if (_deptController.text.trim().isEmpty) {
        _showToast('Please enter your department', isError: true);
        return false;
      }

      if (_classController.text.trim().isEmpty) {
        _showToast('Please enter your class', isError: true);
        return false;
      }
      // "valid address" is disclosed privately
      if (_role == 'rep' && !_isValidRepEmail(email)) {
        _showToast('Enter a valid REP email address', isError: true);
        return false;
      }
    }
    return true;
  }

  // Reusable toast
  //ensures  consistrnecy amonng popup notis

  // app assumes its  false unless called
  void _showToast(String msg, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: isError ? const Color(0xFF8a3a3a) : _accent,
      textColor: _textPrimary,
      toastLength: Toast.LENGTH_LONG, //Flutter length librrary  defaults 3.5s
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
            .get();

        final userRole =
            doc.data()?['role'] ??
            'student'; // if role exists use other wise default to student

        final userName = doc.data()?['name'] ?? 'there';
        _showToast('Welcome back,$userName');

        //navigate homeand pass user roll
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(role: userRole)),
        );
      }
      //sign up logic
      else {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        //save user profile  to firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _role,
          'class': _classController.text.trim(),
          'department': _deptController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showToast('Account created sucessfully!');

        if (mounted) {
          Navigator.pushReplacememt(
            context,
            MaterialPageRoute(
              builder: (context) {
                HomeScreen(role: _role);
              },
            ),
          );
        }
      }
    }
    // Handling specific Firebase authentication errors
    on FirebaseAuthException catch (e) {
      String msg =
          'An error orccured, please try again'; // default error message
      if (e.code == 'invalid-email') msg = 'Invalid email format';
      if (e.code == 'email-already-in-use') msg = 'Email already registered';
      if (e.code == 'user-not-found') msg = 'No account with this email';
      if (e.code == 'weak-password')
        msg = '  Passwords should  be  at least 8 characters';
      if (e.code == 'wrong-password') msg = 'Incorrect passeord, try again';
      if (e.code == 'too-many-requests')
        msg = 'Too many attempts,please try again later';

      _showToast(msg, isError: true);
    } catch (e) {
      _showToast('Unexpected error $e', isError: true);
      // Navigate to home with the role they signed up with
    }
    if (mounted) setState(() => _isLoading = false); // Hide loading indicator
  }

  // ─── Reusable input field ──────────────────────────────────────────────────
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
}
