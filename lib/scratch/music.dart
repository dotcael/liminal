// John 3:16-17
//reference code
import 'package:flutter/material.dart';

// stateful because the screen reacts to filter chip taps
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // ── color system ─────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textMuted = Color(0xFF6b6b9a);
  static const _textDim = Color(0xFF4a4a6a);

  // category accent colors — left border + timeline dot
  static const _colorAcademic = Color(0xFF5c5cd6);
  static const _colorPersonal = Color(0xFF4a9a60);
  static const _colorFinancial = Color(0xFFc49040);
  // urgent is now a flag, not a category — but we still need a color for it
  static const _colorUrgent = Color(0xFFd85a30);

  // badge background / text pairs per category
  static const _badgeBgAcademic = Color(0xFF2a2a5a);
  static const _badgeTxtAcademic = Color(0xFF8888dd);
  static const _badgeBgPersonal = Color(0xFF1a3a28);
  static const _badgeTxtPersonal = Color(0xFF5abba0);
  static const _badgeBgFinancial = Color(0xFF3a2a10);
  static const _badgeTxtFinancial = Color(0xFFc49040);
  // urgent badge colors — used when isUrgent is true, regardless of category
  static const _badgeBgUrgent = Color(0xFF3a1a1a);
  static const _badgeTxtUrgent = Color(0xFFd87a5a);

  // the currently selected filter chip — defaults to showing everything
  _FeedFilter _activeFilter = _FeedFilter.all;

  // ── feed data ─────────────────────────────────────────────────────────────────
  // in the real app this will come from Firestore — hardcoded for the prototype
  final List<_FeedItem> _items = const [
    _FeedItem(
      // academic category + isUrgent: true — deadline announcement
      category: _FeedCategory.academic,
      isUrgent: true,
      source: 'Dr. Sibanda · CS Dept',
      title: 'Assignment 3 deadline is firm — no extensions',
      body: 'Submission closes Friday 11:59pm. Late work will not be accepted.',
      due: '2 days left',
      dueIsHot: true,
      time: '8:02am',
      isUnread: true,
      dateGroup: 'Today',
    ),
    _FeedItem(
      // academic, not urgent — just a venue change
      category: _FeedCategory.academic,
      isUrgent: false,
      source: 'SE · Year 3',
      title: 'Lecture rescheduled — Room B4, 8am tomorrow',
      body: 'Venue change only. Topic remains Design Patterns ch. 4.',
      due: 'Tomorrow',
      dueIsHot: false,
      time: '7:45am',
      isUnread: true,
      dateGroup: 'Today',
      actions: ['Add to calendar', 'Dismiss'],
    ),
    _FeedItem(
      // financial category + isUrgent: true — overdue fees
      category: _FeedCategory.financial,
      isUrgent: true,
      source: 'Finance Office',
      title: 'Semester 2 fees — balance outstanding',
      // 'r' prefix = raw string, tells Dart to treat $ as a literal symbol
      body: r'$420 due before the 30th to avoid a late fee.',
      due: '10 days',
      dueIsHot: true,
      time: '6:30am',
      isUnread: true,
      dateGroup: 'Today',
      actions: ['View statement', 'Snooze'],
    ),
    _FeedItem(
      // personal, not urgent — self-added reminder
      category: _FeedCategory.personal,
      isUrgent: false,
      source: 'Personal',
      title: 'Review chapter 2 notes',
      body: 'You added this task 3 days ago. No progress logged yet.',
      due: 'Friday',
      dueIsHot: false,
      time: '9:00pm',
      isUnread: false,
      dateGroup: 'Yesterday',
    ),
    _FeedItem(
      // academic, urgent — overdue library book
      category: _FeedCategory.academic,
      isUrgent: true,
      source: 'Library · Resource Notice',
      title: 'Borrowed book overdue — Algorithms Unlocked',
      body: 'Return or renew by end of week. Fines apply after 7 days.',
      due: 'Overdue',
      dueIsHot: true,
      time: '2:10pm',
      isUnread: false,
      dateGroup: 'Yesterday',
    ),
  ];

  // ── computed properties ───────────────────────────────────────────────────────

  // filters _items based on which chip is active
  List<_FeedItem> get _visibleItems {

    if (_activeFilter == _FeedFilter.all) return _items;
    
    return _items.where((item) {
      switch (_activeFilter) {
        case _FeedFilter.urgent:
          // urgent filter shows any item flagged as urgent, across all categories
          return item.isUrgent;

        case _FeedFilter.academic:
          return item.category == _FeedCategory.academic;

        case _FeedFilter.personal:
          return item.category == _FeedCategory.personal;

        case _FeedFilter.financial:
          return item.category == _FeedCategory.financial;

          //safeguard incase the case reaches here
        case _FeedFilter.all:
          return true;
      }
    }).toList();
  }

  // pulls unique date group labels in the order they appear — keeps sections sorted
  List<String> get _dateGroups {
    //empty  box
    final seen = <String>{};
    //groups list
    final groups = <String>[];
    for (final item in _visibleItems) {
      if (seen.add(item.dateGroup)) groups.add(item.dateGroup);
    }
    return groups;
  }

  // counts how many items are still unread for the header badge
  int get _unreadCount => _items.where((i) => i.isUnread).length;

  // ── build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              // if the active filter returns nothing, show the empty state
              child: _visibleItems.isEmpty
                  ? _buildEmptyState()
                  : _buildTimeline(),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Feed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              // unread badge — only shown when there are unread items
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _badgeBgAcademic,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_unreadCount new',
                    style: const TextStyle(fontSize: 9, color: _badgeTxtAcademic),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // scrollable filter chip row — maps every _FeedFilter value to a chip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              //make a filter chip for all enum values [all,personal,financial,accademic] etc

              children: _FeedFilter.values
                  .map((f) => _buildFilterChip(f))
                  .toList(),
            ),
          ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }

  // ── filter chip ───────────────────────────────────────────────────────────────
  Widget _buildFilterChip(_FeedFilter filter) {
    final isActive = _activeFilter
     == filter;
    return GestureDetector(
    
      // setState triggers a rebuild — _visibleItems recomputes with the new filter
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? _accent : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _accent : _border,
            width: 0.5,
          ),
        ),
        child: Text(
          filter.label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? _textPrimary : _textMuted,
          ),
        ),
      ),
    );
  }

  // ── timeline ──────────────────────────────────────────────────────────────────
  Widget _buildTimeline() {
    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      children: [
        for (final group in _dateGroups) ...[
          _buildDateLabel(group),
          ..._buildGroupItems(group),
        ],
      ],
    );
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          color: _textDim,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildGroupItems(String group) {
    final groupItems = _visibleItems.where((i) => i.dateGroup == group).toList();

    return List.generate(groupItems.length, (index) {
      final item = groupItems[index];
      // the last item in the entire list gets no connector line below it
      final isLast = group == _dateGroups.last && index == groupItems.length - 1;
      return _buildTimelineRow(item, drawLine: !isLast);
    });       
  }

  // ── timeline row ──────────────────────────────────────────────────────────────
  Widget _buildTimelineRow(_FeedItem item, {required bool drawLine}) {
    // if the item is urgent, the dot uses the urgent color regardless of category 
    //else use the default category color nlue for academic, green for personal and yellow for personal

    final dotColor = item.isUrgent ? _colorUrgent : _categoryAccentColor(item.category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left column: dot + vertical connector line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bg,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                ),
                if (drawLine)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.only(top: 3),
                      color: _border,
                    ),
                  ),
              ],
            ),
          ),
          // right column: the card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14, bottom: 6, top: 6),
              child: _buildCard(item),
            ),
          ),
        ],
      ),
    );
  }

  // ── card ──────────────────────────────────────────────────────────────────────
  Widget _buildCard(_FeedItem item) {
    // if urgent, the left border goes red — otherwise it uses the category color
    final leftBorderColor = item.isUrgent ? _colorUrgent : _categoryAccentColor(item.category);

    // urgent cards also get a slightly warm dark background
    final cardBg = item.isUrgent ? const Color(0xFF231a1a) : _surface;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(
            top: const BorderSide(color: _border, width: 0.5),
            right: const BorderSide(color: _border, width: 0.5),
            bottom: const BorderSide(color: _border, width: 0.5),
            // left border is the urgency-aware color
            left: BorderSide(color: leftBorderColor, width: 2.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // source + timestamp row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.source, style: const TextStyle(fontSize: 9, color: _textMuted)),
                Text(item.time, style: const TextStyle(fontSize: 9, color: _textDim)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
                height: 1.4,
              ),
            ),
            if (item.body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.body,
                style: const TextStyle(fontSize: 9, color: _textMuted, height: 1.5),
              ),
            ],
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // badge shows the real category, not urgency
                _buildBadge(item),
                Text(
                  item.due,
                  style: TextStyle(
                    fontSize: 9,
                    color: item.dueIsHot ? _badgeTxtUrgent : _textDim,
                  ),
                ),
              ],
            ),
            if (item.actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: item.actions.map((label) {
                  final isPrimary = item.actions.indexOf(label) == 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildActionButton(label, isPrimary: isPrimary),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── badge ─────────────────────────────────────────────────────────────────────
  Widget _buildBadge(_FeedItem item) {
    // if the item is urgent, show an 'Urgent' badge on top of the category badge
    // this makes both the category and urgency visible at a glance
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.isUrgent) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeBgUrgent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'Urgent',
              style: TextStyle(fontSize: 8, color: _badgeTxtUrgent),
            ),
          ),
          const SizedBox(width: 4),
        ],
        // always show the real category badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _categoryBadgeBg(item.category),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            _categoryLabel(item.category),
            style: TextStyle(fontSize: 8, color: _categoryBadgeText(item.category)),
          ),
        ),
      ],
    );
  }

  // ── action button ─────────────────────────────────────────────────────────────
  Widget _buildActionButton(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF3a3a7a) : _bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrimary ? const Color(0xFF5c5cd6) : _border,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: isPrimary ? const Color(0xFFa0a0ee) : _textMuted,
        ),
      ),
    );
  }

  // ── empty state ───────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border, width: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ── nav bar ───────────────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('Home', isActive: false),
          _buildNavItem('Feed', isActive: true),
          //_buildNavItem('Tasks', isActive: false),
          _buildNavItem('Profile', isActive: false),
        ],
      ),
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
            color: isActive ? const Color(0xFF7b7bcc) : _textMuted,
          ),
        ),
      ],
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────────
  Color _categoryAccentColor(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _colorAcademic,
        _FeedCategory.personal => _colorPersonal,
        _FeedCategory.financial => _colorFinancial,
      };

  Color _categoryBadgeBg(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _badgeBgAcademic,
        _FeedCategory.personal => _badgeBgPersonal,
        _FeedCategory.financial => _badgeBgFinancial,
      };

  Color _categoryBadgeText(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _badgeTxtAcademic,
        _FeedCategory.personal => _badgeTxtPersonal,
        _FeedCategory.financial => _badgeTxtFinancial,
      };

  String _categoryLabel(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => 'Academic',
        _FeedCategory.personal => 'Personal',
        _FeedCategory.financial => 'Financial',
      };
}

// ── enums ─────────────────────────────────────────────────────────────────────
enum _FeedFilter {
  all,
  urgent,
  academic,
  personal,
  financial;

  String get label => switch (this) {
        _FeedFilter.all => 'All',
        _FeedFilter.urgent => 'Urgent',
        _FeedFilter.academic => 'Academic',
        _FeedFilter.personal => 'Personal',
        _FeedFilter.financial => 'Financial',
      };
}

// urgent is no longer a category — it's removed from _FeedCategory
enum _FeedCategory { academic, personal, financial }

// ── data model ────────────────────────────────────────────────────────────────
class _FeedItem {
  final _FeedCategory category;

  
  // isUrgent is now a standalone boolean flag — any category can be urgent
  final bool isUrgent;
  final String source;
  final String title;
  final String body;
  final String due;
  final bool dueIsHot;
  final String time;
  final bool isUnread;
  final String dateGroup;
  final List<String> actions;

  const _FeedItem({
    required this.category,
    // isUrgent defaults to false — most items are not urgent
    this.isUrgent = false,
    required this.source,
    required this.title,
    required this.body,
    required this.due,
    required this.dueIsHot,
    required this.time,
    required this.isUnread,
    required this.dateGroup,
    this.actions = const [],
  });
}