
//updated FAB to update th screen

Widget _buildFab() {
  return FloatingActionButton(
    onPressed: () {
      showModalBottomSheet(
        context: context,
        // isScrollControlled lets the sheet grow taller than half the screen
        isScrollControlled: true,
        // removes the default white background
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








// upload sheet — handles both personal task creation and rep broadcasts
// StatefulWidget because it manages tab state and form field values
class _UploadSheet extends StatefulWidget {
  const _UploadSheet();

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  // color system
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textMuted = Color(0xFF6b6b9a);

  // urgency colors
  static const _colorUrgent = Color(0xFFd85a30);
  static const _colorSoon = Color(0xFF5c5cd6);
  static const _colorLater = Color(0xFF3d8fa1);

  // 0 = Personal, 1 = Broadcast
  int _activeTab = 0;

  // personal tab controllers
  final _taskNameController = TextEditingController();
  final _taskDueDateController = TextEditingController();

  // broadcast tab controllers
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _sourceController = TextEditingController();
  final _broadcastDueDateController = TextEditingController();

  // urgency selection — null means not picked yet
  String? _selectedUrgency;

  // broadcast-only: target audience and category
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
    // viewInsets.bottom pushes the sheet up when the keyboard appears
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

          // tab row
          _buildTabRow(),
          const SizedBox(height: 16),

          // form fields swap based on active tab
          _activeTab == 0 ? _buildPersonalForm() : _buildBroadcastForm(),
          const SizedBox(height: 16),

          // urgency picker — shared by both tabs
          _buildUrgencyPicker(),
          const SizedBox(height: 16),

          // submit button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // tab switcher
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
          // reset urgency when switching tabs
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

  // personal tab — task name, due date, urgency
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

  // broadcast tab — title, body, source, due date, audience, category
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
            Expanded(child: _buildField('Source', _sourceController, hint: 'e.g. Dr. Sibanda · CS')),
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

  // reusable input field
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

  // small uppercase section label
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3),
    );
  }

  // audience chips — broadcast only
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

  // category chips — broadcast only
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

  // urgency picker — shared by both tabs
  // suggested automatically from due date in a later iteration
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
          // selected chip gets its category color, unselected is flat
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

  // submit button — label and color change based on active tab
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