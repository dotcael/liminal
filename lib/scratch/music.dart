// John 3:16-17
import 'package:flutter/material.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // same color system as home_screen.dart
  static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textMuted = Color(0xFF6b6b9a);
  static const _textDim = Color(0xFF4a4a6a);

  // category accent colors — left bar + timeline dot
  static const _colorAcademic = Color(0xFF5c5cd6);
  static const _colorPersonal = Color(0xFF4a9a60);
  static const _colorFinancial = Color(0xFFc49040);
  static const _colorUrgent = Color(0xFFd85a30);

  // badge bg / text pairs per category
  static const _badgeBgAcademic = Color(0xFF2a2a5a);
  static const _badgeTxtAcademic = Color(0xFF8888dd);
  static const _badgeBgPersonal = Color(0xFF1a3a28);
  static const _badgeTxtPersonal = Color(0xFF5abba0);
  static const _badgeBgFinancial = Color(0xFF3a2a10);
  static const _badgeTxtFinancial = Color(0xFFc49040);
  static const _badgeBgUrgent = Color(0xFF3a1a1a);
  static const _badgeTxtUrgent = Color(0xFFd87a5a);

  // currently selected filter chip — drives which items are visible
  _FeedFilter _activeFilter = _FeedFilter.all;

  // full list of feed items — in a real app this comes from Firestore / a provider
  final List<_FeedItem> _items = const [
    _FeedItem(
      category: _FeedCategory.urgent,
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
      category: _FeedCategory.academic,
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
      category: _FeedCategory.financial,
      source: 'Finance Office',
      title: 'Semester 2 fees — balance outstanding',
      body: r'$420 due before the 30th to avoid a late fee.',
      due: '10 days',
      dueIsHot: true,
      time: '6:30am',
      isUnread: true,
      dateGroup: 'Today',
      actions: ['View statement', 'Snooze'],
    ),
    _FeedItem(
      category: _FeedCategory.personal,
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
      category: _FeedCategory.academic,
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

  // returns the items that match the active filter chip
  List<_FeedItem> get _visibleItems {
    if (_activeFilter == _FeedFilter.all) return _items;
    return _items.where((item) {
      switch (_activeFilter) {
        case _FeedFilter.academic:
          // urgent items belong to academic in context — include them
          return item.category == _FeedCategory.academic ||
              item.category == _FeedCategory.urgent;
        case _FeedFilter.personal:
          return item.category == _FeedCategory.personal;
        case _FeedFilter.financial:
          return item.category == _FeedCategory.financial;
        case _FeedFilter.all:
          return true;
      }
    }).toList();
  }

  // pulls the unique date group labels (Today / Yesterday / etc.)
  // in the order they first appear so section headers stay sorted
  List<String> get _dateGroups {
    final seen = <String>{};
    final groups = <String>[];
    for (final item in _visibleItems) {
      if (seen.add(item.dateGroup)) groups.add(item.dateGroup);
    }
    return groups;
  }

  // how many items in _items are still unread
  int get _unreadCount => _items.where((i) => i.isUnread).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
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

  // ── header: title + unread chip + filter chips ──────────────────────────────
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
                    style: const TextStyle(
                      fontSize: 9,
                      color: _badgeTxtAcademic,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // horizontal filter chip row — scrollable if more chips are added later
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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

  // individual filter chip — active state uses accent fill
  Widget _buildFilterChip(_FeedFilter filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
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

  // ── timeline list — groups items under date headers ──────────────────────────
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

  // uppercase grey date section label
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

  // builds the timeline rows for a single date group
  List<Widget> _buildGroupItems(String group) {
    final groupItems = _visibleItems
        .where((i) => i.dateGroup == group)
        .toList();
    return List.generate(groupItems.length, (index) {
      final item = groupItems[index];
      // whether to draw the vertical line below this dot —
      // the last item in the entire visible list gets no line
      final isLast = group == _dateGroups.last &&
          index == groupItems.length - 1;
      return _buildTimelineRow(item, drawLine: !isLast);
    });
  }

  // one row: dot + vertical line on the left, card on the right
  Widget _buildTimelineRow(_FeedItem item, {required bool drawLine}) {
    final dotColor = _categoryAccentColor(item.category);
    return IntrinsicHeight(
      // IntrinsicHeight makes the Row children match the tallest child's height
      // needed so the vertical line stretches to fill the full card height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── left column: dot + line ──
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 14),
                // colored ring dot
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bg,
                    border: Border.all(color: dotColor, width: 1.5),
                  ),
                ),
                // vertical connector line — hidden on last item
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
          // ── right column: the card ──
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

  // ── feed card ────────────────────────────────────────────────────────────────
  Widget _buildCard(_FeedItem item) {
    final accentColor = _categoryAccentColor(item.category);
    final cardBg = item.category == _FeedCategory.urgent
        ? const Color(0xFF231a1a)
        : _surface;

    // ClipRRect fixes the mixed-border + borderRadius crash
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cardBg,
          // left border uses category color; other sides use the default border
          border: Border(
            top: const BorderSide(color: _border, width: 0.5),
            right: const BorderSide(color: _border, width: 0.5),
            bottom: const BorderSide(color: _border, width: 0.5),
            left: BorderSide(color: accentColor, width: 2.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // source line + timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.source,
                  style: const TextStyle(fontSize: 9, color: _textMuted),
                ),
                Text(
                  item.time,
                  style: const TextStyle(fontSize: 9, color: _textDim),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // title
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
                height: 1.4,
              ),
            ),
            // body text — only shown when non-empty
            if (item.body.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.body,
                style: const TextStyle(fontSize: 9, color: _textMuted, height: 1.5),
              ),
            ],
            const SizedBox(height: 7),
            // badge + due date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBadge(item.category),
                Text(
                  item.due,
                  style: TextStyle(
                    fontSize: 9,
                    color: item.dueIsHot ? _badgeTxtUrgent : _textDim,
                  ),
                ),
              ],
            ),
            // action buttons — only shown when the item has actions defined
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

  // small category badge pill
  Widget _buildBadge(_FeedCategory category) {
    final bg = _categoryBadgeBg(category);
    final text = _categoryBadgeText(category);
    final label = _categoryLabel(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(fontSize: 8, color: text)),
    );
  }

  // action button — primary gets accent fill, secondary is ghost
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

  // shown when filter returns no results
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

  // ── bottom nav bar — matches home_screen.dart ────────────────────────────────
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
          _buildNavItem('Tasks', isActive: false),
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
            color: isActive
                ? const Color(0xFF3a3a7a)
                : const Color(0xFF2d2d4a),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isActive
                ? const Color(0xFF7b7bcc)
                : _textMuted,
          ),
        ),
      ],
    );
  }

  // ── helpers: map category enum → colors / labels ─────────────────────────────
  Color _categoryAccentColor(_FeedCategory cat) => switch (cat) {
        _FeedCategory.urgent => _colorUrgent,
        _FeedCategory.academic => _colorAcademic,
        _FeedCategory.personal => _colorPersonal,
        _FeedCategory.financial => _colorFinancial,
      };

  Color _categoryBadgeBg(_FeedCategory cat) => switch (cat) {
        _FeedCategory.urgent => _badgeBgUrgent,
        _FeedCategory.academic => _badgeBgAcademic,
        _FeedCategory.personal => _badgeBgPersonal,
        _FeedCategory.financial => _badgeBgFinancial,
      };

  Color _categoryBadgeText(_FeedCategory cat) => switch (cat) {
        _FeedCategory.urgent => _badgeTxtUrgent,
        _FeedCategory.academic => _badgeTxtAcademic,
        _FeedCategory.personal => _badgeTxtPersonal,
        _FeedCategory.financial => _badgeTxtFinancial,
      };

  String _categoryLabel(_FeedCategory cat) => switch (cat) {
        _FeedCategory.urgent => 'Urgent',
        _FeedCategory.academic => 'Academic',
        _FeedCategory.personal => 'Personal',
        _FeedCategory.financial => 'Financial',
      };
}

// ── enums ─────────────────────────────────────────────────────────────────────
enum _FeedFilter {
  all,
  academic,
  personal,
  financial;

  String get label => switch (this) {
        _FeedFilter.all => 'All',
        _FeedFilter.academic => 'Academic',
        _FeedFilter.personal => 'Personal',
        _FeedFilter.financial => 'Financial',
      };
}

enum _FeedCategory { urgent, academic, personal, financial }

// ── data model ────────────────────────────────────────────────────────────────
class _FeedItem {
  final _FeedCategory category;
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