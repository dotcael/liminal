// John 3:16-17
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String role;

  const ProfileScreen({super.key, required this.name, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textMuted = Color(0xFF6b6b9a);
  static const _textDim = Color(0xFF4a4a6a);

  // fetched from Firestore on mount — not passed in as a constructor param
  // since ShellScreen only carries name and role, not the full user doc
  String _department = '';
  String _email = '';
  bool _isLoading = true;

  bool get _isRep => widget.role == 'rep';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // fetches the current user's Firestore document to get department + email
  // falls back to empty strings if fields are missing
  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    setState(() {
      _department = doc.data()?['department'] as String? ?? '';
      _email = doc.data()?['email'] as String? ?? user.email ?? '';
      _isLoading = false;
    });
  }

  // signs the user out of Firebase Auth and pushes them back to AuthScreen,
  // clearing the entire navigation stack so they can't press back to get in
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 24),
          // reps see broadcast settings, students see subscriptions
          _isRep ? _buildRepSection() : _buildStudentSection(),
          const SizedBox(height: 32),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  // avatar initial + name + role badge
  Widget _buildHeader() {
    return Row(
      children: [
        // avatar circle showing first letter of name
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2a2a5a),
            border: Border.all(color: const Color(0xFF4a4aaa), width: 0.5),
          ),
          child: Center(
            child: Text(
              widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Color(0xFFa0a0ee),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // role badge pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _isRep
                    ? const Color(0xFF2a2a5a)
                    : const Color(0xFF1a3a28),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _isRep ? 'Rep' : 'Student',
                style: TextStyle(
                  fontSize: 10,
                  color: _isRep
                      ? const Color(0xFF8888dd)
                      : const Color(0xFF5abba0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // email + department fields displayed as read-only info rows
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Column(
        children: [
          _buildInfoRow('Email', _email),
          const SizedBox(height: 12),
          _buildInfoRow('Department', _department.isEmpty ? '—' : _department),
        ],
      ),
    );
  }

  // a single label + value row used inside _buildInfoSection
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _textMuted)),
        Text(value, style: const TextStyle(fontSize: 11, color: _textPrimary)),
      ],
    );
  }

  // rep-only section — broadcast settings placeholder
  // scoped out for this iteration, structure is here for the next one
  Widget _buildRepSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Broadcast settings'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: const Text(
            'Broadcast preferences coming in a later iteration.',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ),
      ],
    );
  }

  // student-only section — subscription preferences placeholder
  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Subscriptions'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.5),
          ),
          child: const Text(
            'Subscription preferences coming in a later iteration.',
            style: TextStyle(fontSize: 11, color: _textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        color: _textDim,
        letterSpacing: 0.5,
      ),
    );
  }

  // logout button — full width, destructive red tint
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2a1a1a),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8a3a3a), width: 0.5),
        ),
        child: const Text(
          'Log out',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFFd87a5a),
          ),
        ),
      ),
    );
  }
}