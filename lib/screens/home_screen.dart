import 'package:flutter/material.dart';


// urgency levels used to drive card styling
enum _Urgency { urgent, soon, later }

class HomeScreen extends StatelessWidget {
  final String name;
  final String role;

  const HomeScreen({super.key, required this.name, required this.role});

  // same color system as auth screen
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textSecondary = Color(0xFF6b6b9a);

  // urgency badge colors — text and background pairs
  static const _urgentText = Color(0xFFd87a5a);
  static const _urgentBg = Color(0xFF2a1a1a);
  static const _soonText = Color(0xFFc49040);
  static const _soonBg = Color(0xFF2a2010);
  static const _laterText = Color(0xFF5abcd8);
  static const _laterBg = Color(0xFF1a3a42);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Urgent'),

                    _buildTaskCard(
                      title: 'Data Structures Assignment 3',
                      meta: 'CS Year 3 · Academic',
                      dueBadge: 'Tomorrow',
                      urgency: _Urgency.urgent,
                    ),
                    _buildSectionLabel('Up next'),

                    _buildTaskCard(
                      title: 'SE lecture moved',
                      meta: '8am · Room B4',
                      dueBadge: '2 days',
                      urgency: _Urgency.soon,
                    ),
                    _buildTaskCard(
                      title: 'Review chapter 2 notes',
                      meta: 'Personal',
                      dueBadge: 'Friday',
                      urgency: _Urgency.later,
                    ),
                    _buildTaskCard(

                      title: 'Cross Check IDCL Terms',
                      meta: 'Personal ',
                      dueBadge: 'Friday',
                      urgency: _Urgency.later,
                  
                    ),
                    _buildTaskCard(

                      title: 'Cross Check IDCL Terms',
                      meta: 'Personal ',
                      dueBadge: 'Friday',
                      urgency: _Urgency.later,
                  
                    ),
                    _buildTaskCard(

                      title: 'Cross Check IDCL Terms',
                      meta: 'Personal ',
                      dueBadge: 'Friday',
                      urgency: _Urgency.soon,
                  
                    ),
                    _buildTaskCard(

                      title: 'Pay School fees',
                      meta: 'Academic ',
                      dueBadge: 'Friday',
                      urgency: _Urgency.urgent,
                  
                    ),
                    _buildTaskCard(

                      title: 'Cross Check IDCL Terms',
                      meta: 'Personal ',
                      dueBadge: 'Friday',
                      urgency: _Urgency.later,
                  
                    ),
                      _buildTaskCard(

                      title: 'Pay School fees',
                      meta: 'Academic ',
                      dueBadge: 'Friday',
                      urgency: _Urgency.urgent,
                  
                      ),
                    const SizedBox(height: 12),
                   
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
      floatingActionButton: Padding( padding: const EdgeInsets.only(bottom:63),
      child:_buildFab(),),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  // header with greeting, name, and inline summary chips
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
           //Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: _textPrimary)),
          const Text(
            'Good Morning,',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 7),

          // inline summary chips 
          Row(
            children: [
              _buildSummaryChip('1 urgent', _urgentText, _urgentBg),
              const SizedBox(width: 8),
              _buildSummaryChip('3 soon', _soonText, _soonBg),
              const SizedBox(width: 8),
              _buildSummaryChip('5 later', _laterText, _laterBg),
            ],
          ),
        ],
      ),
    );
  }

  // reusable colored pill chip for the summary row
  Widget _buildSummaryChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }

  //divider labels 
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 5),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          color: _textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // task card with urgency-colored left border and matching badge
  Widget _buildTaskCard({
    required String title,
    required String meta,
    required String dueBadge,
    required _Urgency urgency,
  }) {
    // left border color changes based on urgency level
    final borderColor = switch (urgency) {
      _Urgency.urgent => const Color(0xFFd85a30),
      _Urgency.soon   => const Color(0xFF5c5cd6),
      _Urgency.later  => const Color(0xFF3d8fa1),
    };

    // urgent cards get a slightly warm background, others use default surface
    final cardBg = urgency == _Urgency.urgent ? const Color(0xFF231a1a) : _surface;

    final badgeText = urgency == _Urgency.urgent
        ? const Color(0xFFd87a5a)
        : urgency == _Urgency.soon
            ? const Color(0xFF8888dd)
            : const Color(0xFF5abcd8);

    final badgeBg = urgency == _Urgency.urgent
        ? const Color(0xFF3a1a1a)
        : urgency == _Urgency.soon
            ? const Color(0xFF3a1a1a)
            : const Color(0xFF1a3a42);

    // FIX: ClipRRect handles border radius so BoxDecoration can have mixed border colors

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            left: BorderSide(color: borderColor, width: 3),  // urgency accent
            top: BorderSide(color: _border, width: 0.5),
            right: BorderSide(color: _border, width: 0.5),
            bottom: BorderSide(color: _border, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    style: const TextStyle(fontSize: 10, color: _textSecondary),
                  ),
                ],
              ),
            ),
            // due date badge — color matches urgency level
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dueBadge,
                style: TextStyle(fontSize: 9, color: badgeText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // add task button / FAB (floating action button)
  Widget _buildFab() {
    return FloatingActionButton(onPressed:(){
// TO OPEN TASK MODAL LATER
    } , backgroundColor: _accent, foregroundColor: _textPrimary, elevation: 6,
    shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),),
    child: const Icon(Icons.add, size: 28),); // its positioned left 
    // i want it ot be bottom left and some margin so its not directly on the screen or the nav bar
  }
  // bottom nav bar — static for now, will wire up when other screens are built
  Widget _buildNavBar() {

    // after decoration — restructured so decoration, padding, and child are all
    // proper named args of the same Container
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Home', isActive: true),
          _buildNavItem('Feed'),
          _buildNavItem('Task'),
          _buildNavItem('Profile'),
        ],
      ),
    );
  }

  // individual nav item — active state uses accent color
  Widget _buildNavItem(String label, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3a3a7a) : const Color(0xFF2d2d4a),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive ? const Color(0xFF7b7bcc) : _textSecondary,
          ),
        ),
      ],
    );
  }
}