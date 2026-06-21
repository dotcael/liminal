// John 3:16-17
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Urgency { urgent, soon, later }

// changed to StatefulWidget so the task list can rebuild when local storage changes
class HomeScreen extends StatefulWidget {
  final String name;
  final String role;

  const HomeScreen({super.key, required this.name, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textSecondary = Color(0xFF6b6b9a);

  static const _urgentText = Color(0xFFd87a5a);
  static const _urgentBg = Color(0xFF2a1a1a);
  static const _soonText = Color(0xFFc49040);
  static const _soonBg = Color(0xFF2a2010);
  static const _laterText = Color(0xFF5abcd8);
  static const _laterBg = Color(0xFF1a3a42);

  // the in-memory list of personal tasks loaded from local storage
  // each entry is a Map<String, dynamic> matching what was written by _UploadSheet
  List<Map<String, dynamic>> _tasks = [];

  // true while _loadTasks is reading from shared_preferences on first mount
  // used to show a spinner instead of an empty state during the brief read
  bool _isLoading = true;

  // the key used to store and retrieve the task list in shared_preferences
  // keeping it as a constant avoids typos if it's referenced in multiple places
  static const _storageKey = 'personal_tasks';

  @override
  void initState() {
    super.initState();
    // load saved tasks as soon as the screen mounts
    // initState can't be async itself, so _loadTasks is a separate async method
    _loadTasks();
  }

  // reads the JSON string stored under _storageKey and decodes it into _tasks
  // shared_preferences stores everything as strings — JSON is how we serialize a list of maps
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    // getString returns null if the key doesn't exist yet (first launch)
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      // jsonDecode turns the JSON string back into a Dart List
      // each element is cast to Map<String, dynamic> so we can access fields by name
      final decoded = jsonDecode(raw) as List<dynamic>;
      setState(() {
        _tasks = decoded.cast<Map<String, dynamic>>();
      });
    }
    // mark loading as done whether or not there were any saved tasks
    setState(() => _isLoading = false);
  }

  // writes the current _tasks list to shared_preferences as a JSON string
  // called after every add and delete so the stored data stays in sync with the UI
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_tasks));
  }

  // converts the urgency string stored in local storage to the local _Urgency enum
  // 'Urgent' → _Urgency.urgent, 'Soon' → _Urgency.soon, anything else → _Urgency.later
  // this is the bridge between what's stored (strings) and what the UI uses (enums)
  _Urgency _parseUrgency(String? value) {
    switch (value) {
      case 'Urgent': return _Urgency.urgent;
      case 'Soon':   return _Urgency.soon;
      default:       return _Urgency.later;
    }
  }

  // removes the task with the given id from _tasks, redraws the UI, then persists
  // the removal happens in _tasks first (setState) so the UI updates instantly
  // _saveTasks then writes the updated list to disk in the background
  Future<void> _deleteTask(String id) async {
    setState(() {
      _tasks.removeWhere((task) => task['id'] == id);
    });
    await _saveTasks();
  }

  // called by _UploadSheet after a successful local save
  // adds the new task map to _tasks and persists immediately
  Future<void> _addTask(Map<String, dynamic> task) async {
    setState(() {
      // insert at index 0 so the newest task appears at the top
      // this matches the descending order we had with Firestore's orderBy createdAt
      _tasks.insert(0, task);
    });
    await _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            // brief spinner while shared_preferences reads from disk on first mount
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4a4aaa)),
              )
            : _buildContent(),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 63),
        child: _buildFab(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  // extracted so build() stays readable — contains the header + scrollable task list
  Widget _buildContent() {
    // loop through all tasks once and count by urgency bucket
    // these counts drive the summary chips in the header
    int urgentCount = 0;
    int soonCount = 0;
    int laterCount = 0;

    for (final task in _tasks) {
      final urgency = _parseUrgency(task['urgency'] as String?);
      if (urgency == _Urgency.urgent) urgentCount++;
      else if (urgency == _Urgency.soon) soonCount++;
      else laterCount++;
    }

    return Column(
      children: [
        _buildHeader(urgentCount, soonCount, laterCount),
        Expanded(
          child: _tasks.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // each section only renders if it has tasks
                      // if urgentCount is 0 the entire urgent block is skipped
                      if (urgentCount > 0) ...[
                        _buildSectionLabel('Urgent'),
                        // filter _tasks to only urgent ones, then map each to a card
                        ..._tasks
                            .where((task) =>
                                _parseUrgency(task['urgency'] as String?) ==
                                _Urgency.urgent)
                            .map((task) => _buildDismissibleCard(
                                  taskId: task['id'] as String,
                                  title: task['taskName'] as String? ?? '', //string coalescing if the string is null set it to empty string 
                                  meta: task['dueDate'] as String? ?? '',
                                  urgency: _Urgency.urgent,
                                )),
                      ],

                      if (soonCount > 0) ...[
                        _buildSectionLabel('Up next'),
                        ..._tasks
                            .where((task) =>
                                _parseUrgency(task['urgency'] as String?) ==
                                _Urgency.soon)
                            .map((task) => _buildDismissibleCard(
                                  taskId: task['id'] as String,
                                  title: task['taskName'] as String? ?? '',
                                  meta: task['dueDate'] as String? ?? '',
                                  urgency: _Urgency.soon,
                                )),
                      ],

                      if (laterCount > 0) ...[
                        _buildSectionLabel('Later'),
                        ..._tasks
                            .where((task) =>
                                _parseUrgency(task['urgency'] as String?) ==
                                _Urgency.later)
                            .map((task) => _buildDismissibleCard(
                                  taskId: task['id'] as String,
                                  title: task['taskName'] as String? ?? '',
                                  meta: task['dueDate'] as String? ?? '',
                                  urgency: _Urgency.later,
                                )),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // wraps each task card in a Dismissible widget
  // Dismissible is Flutter's built-in swipe-to-delete widget
  // it handles partial swipe (reveals background), tap on background, and full swipe
  // this gives us the iOS mail-style delete behaviour out of the box
  Widget _buildDismissibleCard({
    required String taskId,
    required String title, 
    required String meta,
    required _Urgency urgency,
  }) {
    return Dismissible(
      // key must be unique per item — the local task id is perfect for this
      // Flutter uses the key to track which card is being dismissed
      key: Key(taskId),

      // only allow swipe from right to left — matches iOS convention
      direction: DismissDirection.endToStart,

      // background is what slides in behind the card as you swipe
      // only secondaryBackground is needed since direction is endToStart
      background: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        decoration: BoxDecoration(
          color: const Color(0xFF8a1a1a),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Color(0xFFe8e8f4), size: 20),
      ),

      // confirmDismiss is called when the user lifts their finger
      // returning true completes the dismissal, false snaps the card back
      confirmDismiss: (direction) async {
        // delete from local storage — instant, no network
        await _deleteTask(taskId);
        return true;
      },

      // onDismissed runs after the card finishes sliding off screen
      // the actual delete already happened in confirmDismiss
      // this is just where you'd add a snackbar or undo option if needed
      onDismissed: (direction) {},

      child: _buildTaskCard(
        title: title,
        meta: meta,
        urgency: urgency,
      ),
    );
  }

  Widget _buildHeader(int urgentCount, int soonCount, int laterCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // widget.name accesses the parent StatefulWidget's field
          // in a StatelessWidget you'd write 'name' directly
          // in a StatefulWidget state class you go through widget.
          Text(
            'Good morning, ${widget.name}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _buildSummaryChip('$urgentCount urgent', _urgentText, _urgentBg),
              const SizedBox(width: 8),
              _buildSummaryChip('$soonCount soon', _soonText, _soonBg),
              const SizedBox(width: 8),
              _buildSummaryChip('$laterCount later', _laterText, _laterBg),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text(
            'No tasks yet',
            style: TextStyle(fontSize: 13, color: Color(0xFF6b6b9a)),
          ),
          SizedBox(height: 6),
          Text(
            'Tap + to add one',
            style: TextStyle(fontSize: 11, color: Color(0xFF4a4a6a)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String meta,
    required _Urgency urgency,
  }) {
    final borderColor = switch (urgency) {
      _Urgency.urgent => const Color(0xFFd85a30),
      _Urgency.soon   => const Color(0xFF5c5cd6),
      _Urgency.later  => const Color(0xFF3d8fa1),
    };

    final cardBg = urgency == _Urgency.urgent
        ? const Color(0xFF231a1a)
        : _surface;

    final badgeText = urgency == _Urgency.urgent
        ? const Color(0xFFd87a5a)
        : urgency == _Urgency.soon
            ? const Color(0xFF8888dd)
            : const Color(0xFF5abcd8);

    final badgeBg = urgency == _Urgency.urgent
        ? const Color(0xFF3a1a1a)
        : urgency == _Urgency.soon
            ? const Color(0xFF2a2a5a)
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
                    // meta is the due date string the user typed
                    // shown as the secondary line below the task title
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: _textSecondary,
                      ),
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
                  urgency == _Urgency.urgent
                      ? 'Urgent'
                      : urgency == _Urgency.soon
                          ? 'Soon'
                          : 'Later',
                  style: TextStyle(fontSize: 9.5, color: badgeText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        // await the sheet — _UploadSheet returns the new task map on success
        // or null if the user dismissed without saving
        final newTask = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const _UploadSheet(),
        );
        // if a task came back, add it to the local list
        if (newTask != null) {
          await _addTask(newTask);
        }
      },
      backgroundColor: _accent,
      foregroundColor: _textPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.add, size: 28),
    );
  }
}














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

  bool _isSubmitting = false;

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
    // always dispose controllers when the widget is removed from the tree
    // failure to do this leaks memory — the controllers stay alive in the background
    _taskNameController.dispose();
    _taskDueDateController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _sourceController.dispose();
    _broadcastDueDateController.dispose();
    super.dispose(); //clear out the widget state
  }

  @override
  Widget build(BuildContext context) {
    // viewInsets.bottom is the height of the on-screen keyboard
    // adding it to the bottom padding pushes the sheet up when the keyboard appears
    // so the fields are never hidden behind the keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // how You tall the keyboard is

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
          // drag handle — visual affordance that the sheet is draggable
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
          // reset urgency selection when switching tabs
          // so the previous tab's selection doesn't carry over
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
        _buildField(
          'Due date',
          _taskDueDateController,
          hint: 'e.g. Friday, Dec 20',
        ),
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
            Expanded(
              child: _buildField('Source', _sourceController, hint: 'e.g. Mr. Musa · CS'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildField('Due date', _broadcastDueDateController, hint: 'e.g. Friday'),
            ),
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    bool tall = false,
  }) {
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4a4a6a),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: _textMuted,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildAudienceChips() {
    final options = ['CS Year 3', 'SE Year 3', 'All dept.'];
    return Wrap(
      spacing: 6,
      children: options.map((options) {
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
    final options = ['Academic', 'Financial'];
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
                width: 0.6,
              ),
            ),
            child: Text(
              option,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFFa0a0ee) : _textPrimary,
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
            //label, border color, bg color
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

  // submit button is visually disabled while _isSubmitting is true (broadcast tab only)
  Widget _buildSubmitButton() {
    final isPersonal = _activeTab == 0;
    return GestureDetector(
      // onTap is null when _isSubmitting is true — GestureDetector ignores null taps
      onTap: _isSubmitting ? null : _handleSubmit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          // slightly dimmed when submitting to signal the button is inactive
          color: _isSubmitting
              ? const Color(0xFF2a2a5a)
              : isPersonal
                  ? const Color(0xFF3a6a4a)
                  : _accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _isSubmitting
              ? 'Sending…'
              : isPersonal
                  ? 'Add Task'
                  : 'Broadcast',
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



  

  Future<void> _handleSubmit() async {
    // validation runs first for both tabs
    //active tab == 0 is personal

    if (_activeTab == 0) {
      if (_taskNameController.text.trim().isEmpty) {
        _showToast('Please enter a task name', isError: true);
        return;
      }
    } else {
      if (_titleController.text.trim().isEmpty) {
        _showToast('Please enter a title', isError: true);
        return;
      }
    }

    if (_selectedUrgency == null) {
      _showToast('Please select an urgency level', isError: true);
      return;
    }

    //recheck tab to know if to use local or firestore writes

    if (_activeTab == 0) {
      // personal tab — write to local storage only, no network involved
      // build the task map that will be stored and returned to HomeScreen
      final newTask = {
        // millisecondsSinceEpoch gives a unique integer timestamp as the local id
        // toString() converts it to a string so it matches the Map<String, dynamic> type
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'taskName': _taskNameController.text.trim(),
        'dueDate': _taskDueDateController.text.trim(),
        'urgency': _selectedUrgency,
        'category': 'Personal',
      };

      _showToast('Task added');

      // dismiss the keyboard before closing
      FocusScope.of(context).unfocus();

      // Navigator.pop with a value passes the task map back to the FAB's await
      // HomeScreen receives it in newTask and calls _addTask
      if (mounted) Navigator.pop(context, newTask);

    } else {
      // broadcast tab — still uses Firestore, network required
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showToast('Error: user not logged in', isError: true);
        return;
      }

      // set _isSubmitting to true before the write starts
      // this disables the button and shows 'Sending…' so the user knows something is happening
      setState(() => _isSubmitting = true);

      // dismiss the keyboard before closing the sheet
      FocusScope.of(context).unfocus();

      try {
        await FirebaseFirestore.instance.collection('broadcast').add({
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'source': _sourceController.text.trim(),
          'dueDate': _broadcastDueDateController.text.trim(),
          'audience': _selectedAudience,
          'category': _selectedCategory,
          'urgency': _selectedUrgency,
          'uid': user.uid,
          // FieldValue.serverTimestamp() writes the server's current time
          // more reliable than DateTime.now() which uses the device clock
          'createdAt': FieldValue.serverTimestamp(),
        });

        _showToast('Broadcast sent');

        // close the sheet after a successful write
        // mounted check ensures we don't call Navigator on a widget that no longer exists
        if (mounted) Navigator.pop(context);

      } catch (e) {

        _showToast('Error: $e', isError: true);
        // re-enable the button so the user can try again
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor:
          isError ? const Color(0xFF8a3a3a) : const Color(0xFF4a4aaa),
      textColor: const Color(0xFFe8e8f4),
      toastLength: Toast.LENGTH_LONG,
    );
  }


  
}