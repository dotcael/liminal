// John 3:16-17
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
            // _buildNavBar(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 63),
        child: _buildFab(context),
      ),
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
          const Text(
            'Good Morning,',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 7),
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

  Widget _buildTaskCard({
    required String title,
    required String meta,
    required String dueBadge,
    required _Urgency urgency,
  }) {
    final borderColor = switch (urgency) {
      _Urgency.urgent => const Color(0xFFd85a30),
      _Urgency.soon   => const Color(0xFF5c5cd6),
      _Urgency.later  => const Color(0xFF3d8fa1),
    };

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

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: borderColor, width: 4)),
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
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: const TextStyle(fontSize: 10.5, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  dueBadge,
                  style: TextStyle(fontSize: 9.5, color: badgeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // add task button / FAB (floating action button)
  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          // isScrollControlled lets the sheet grow taller than half the screen
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const _UploadSheet(),
        );
      },
      backgroundColor: _accent,
      foregroundColor: _textPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, size: 28),
    );
  }

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


// upload sheet — handles both personal task creation and rep broadcasts
// StatefulWidget because it manages tab state and form field values
class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textMuted = Color(0xFF6b6b9a);

  static const _colorUrgent = Color(0xFFd85a30);
  static const _colorSoon = Color(0xFF5c5cd6);
  static const _colorLater = Color(0xFF3d8fa1);

  int _activeTab = 0;

  final _taskNameController = TextEditingController();
  final _taskDueDateController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _sourceController = TextEditingController();
  final _broadcastDueDateController = TextEditingController();

  String? _selectedUrgency;
  String _selectedAudience = 'CS Year 3';
  String _selectedCategory = 'Academic';

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDueDateController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _sourceController.dispose();
    _broadcastDueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(18, 16, 18, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF3a3a6a),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'New post',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildTabRow(),
          const SizedBox(height: 16),
          _activeTab == 0 ? _buildPersonalForm() : _buildBroadcastForm(),
          const SizedBox(height: 16),
          _buildUrgencyPicker(),
          const SizedBox(height: 16),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildTab('Personal', index: 0),
          _buildTab('Broadcast', index: 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {required int index}) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = index;
          _selectedUrgency = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3a3a7a) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? _textPrimary : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField('Task name', _taskNameController),
        const SizedBox(height: 10),
        _buildField('Due date', _taskDueDateController, hint: 'e.g. Friday, Dec 20'),
      ],
    );
  }

  Widget _buildBroadcastForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField('Title', _titleController, hint: 'e.g. Lecture rescheduled'),
        const SizedBox(height: 10),
        _buildField('Body', _bodyController, hint: 'Add more detail…', tall: true),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildField('Source', _sourceController, hint: 'e.g. Mr. Musa · CS')),
            const SizedBox(width: 8),
            Expanded(child: _buildField('Due date', _broadcastDueDateController, hint: 'e.g. Friday')),
          ],
        ),
        const SizedBox(height: 10),
        _buildLabel('Target audience'),
        const SizedBox(height: 6),
        _buildAudienceChips(),
        const SizedBox(height: 10),
        _buildLabel('Category'),
        const SizedBox(height: 6),
        _buildCategoryChips(),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {String? hint, bool tall = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3a3a6a), width: 0.5),
          ),
          child: TextField(
            controller: controller,
            maxLines: tall ? 3 : 1,
            style: const TextStyle(fontSize: 11, color: _textPrimary),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF4a4a6a)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3),
    );
  }

  Widget _buildAudienceChips() {
    final options = ['CS Year 3', 'SE Year 3', 'All dept.'];
    return Wrap(
      spacing: 6,
      children: options.map((option) {
        final isSelected = _selectedAudience == option;
        return GestureDetector(
          onTap: () => setState(() => _selectedAudience = option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2a2a5a) : _bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _accent : const Color(0xFF3a3a6a),
                width: 0.5,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFFa0a0ee) : _textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChips() {
    final options = ['Academic', 'Financial', 'Urgent'];
    return Wrap(
      spacing: 6,
      children: options.map((option) {
        final isSelected = _selectedCategory == option;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2a2a5a) : _bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _accent : const Color(0xFF3a3a6a),
                width: 0.5,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFFa0a0ee) : _textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrgencyPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Urgency'),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildUrgencyChip('Urgent', _colorUrgent, const Color(0xFF2a1a1a)),
            const SizedBox(width: 6),
            _buildUrgencyChip('Soon', _colorSoon, const Color(0xFF1e1e3a)),
            const SizedBox(width: 6),
            _buildUrgencyChip('Later', _colorLater, const Color(0xFF0e2a30)),
          ],
        ),
      ],
    );
  }

  Widget _buildUrgencyChip(String label, Color borderColor, Color bgColor) {
    final isSelected = _selectedUrgency == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedUrgency = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : _bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? borderColor : const Color(0xFF3a3a6a),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? borderColor : _textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isPersonal = _activeTab == 0;
    return GestureDetector(
      onTap: () {
        // Firestore write goes here in the next step
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isPersonal ? const Color(0xFF3a6a4a) : _accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isPersonal ? 'Add task' : 'Broadcast',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }
}