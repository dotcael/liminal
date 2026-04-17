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
                  children: [_buildSectionLabel('Urgent'), _buildTaskCard(
                    title: 'Data Structures Assignment 3',
                    meta: 'CS Year 3 · Academic',
                    dueBadge: 'Tomorrow',
                    urgency: _Urgency.urgent,
                  ),
                  _buildSectionLabel ('Up next'),
                  _buildTaskCard(title: 'SE lecture moved', meta: '8am · Room B4',
                  dueBadge: '2 days', urgency: _Urgency.soon), 

                  _buildTaskCard(title: 'Review chapter 2 notes', meta: 'Personal', dueBadge: ' Friday',
                  urgency: _Urgency.later,
                  ),
                  const SizedBox(height: 12),
                  _buildFab(),
                  const SizedBox (height: 16),
                  ]),),),

                  _buildNavBar()
          ],
        ),
      ),
    );
  }

   // header with greeting, name, and inline summary chips

   Widget _buildHeader() {
return Container(padding:const EdgeInsets.fromLTRB(18, 14, 18, 10),
decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5)),),

child: Column(crossAxisAlignment: CrossAxisAlignment.start,
children: [const text('Good Morning,', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: _textPrimary,),),


const SizedBox (height: 7)


Row()
])
)

   }