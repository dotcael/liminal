// John 3:16-17

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dev/dev_prefs.dart';
import '../widgets/haptics.dart';
import '../widgets/pressable.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _textDim => Theme.of(context).colorScheme.outline;

  static const _colorAcademic = Color(0xFF5c5cd6);
  static const _colorFinancial = Color(0xFFc49040);
  static const _colorUrgent = Color(0xFFd85a30);

  Color get _badgeBgAcademic => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2a2a5a) : const Color(0xFFe0e0f8);
  static const _badgeTxtAcademic = Color(0xFF8888dd);
  Color get _badgeBgFinancial => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF3a2a10) : const Color(0xFFf8f0d6);
  static const _badgeTxtFinancial = Color(0xFFc49040);
  Color get _badgeBgUrgent => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF3a1a1a) : const Color(0xFFfce8e0);
  static const _badgeTxtUrgent = Color(0xFFd87a5a);

  Color get _actionPrimaryBg => Theme.of(context).colorScheme.primaryContainer;
  Color get _actionPrimaryBorder => Theme.of(context).colorScheme.primary;
  Color get _actionPrimaryText => Theme.of(context).colorScheme.onPrimaryContainer;

  _FeedFilter _activeFilter = _FeedFilter.all;

  String? _userDepartment;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserDepartment();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  Future<void> _loadUserDepartment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingUser = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userDepartment = doc.data()?['department'] as String?;
          _isLoadingUser = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  final Stream<QuerySnapshot> _broadcastStream = FirebaseFirestore.instance
      .collection('broadcast')
      .orderBy('createdAt', descending: true)
      .snapshots();

  bool _parseIsUrgent(String? value) => value == 'Urgent';

  _FeedCategory _parseCategory(String? value) {
    switch (value) {
      case 'Financial':
        return _FeedCategory.financial;
      //   return _FeedCategory.personal;
      default:
        return _FeedCategory.academic;
    }
  }

  String _dateGroupLabel(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final difference = today.difference(itemDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(createdAt);
  }

  // formats the time-of-day shown in the top-right of each card, e.g. '8:02am'
  String _formatTime(DateTime createdAt) {
    return DateFormat('h:mma').format(createdAt).toLowerCase();
  }

  _DueState _dueStateFor(int? ts) {
    if (ts == null) return _DueState.unknown;
    final due = DateTime.fromMillisecondsSinceEpoch(ts);
    final days = due.difference(DateTime.now()).inDays;
    if (days < 0) return _DueState.overdue;
    if (days == 0) return _DueState.today;
    return _DueState.future;
  }

  String _dueCountdown(int? ts) {
    final due = DateTime.fromMillisecondsSinceEpoch(ts ?? 0);
    final now = DateTime.now();
    final diff = due.difference(now);
    final days = diff.inDays;
    if (ts == null) return '';
    if (days < 0) {
      final late = -days;
      return late == 1 ? 'Overdue by 1 day' : 'Overdue by $late days';
    }
    if (days == 0) {
      final hours = diff.inHours;
      return hours <= 0 ? 'Due today' : 'Due in $hours hr';
    }
    return days == 1 ? 'Due in 1 day' : 'Due in $days days';
  }

  _FeedItem _itemFromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final createdAt = timestamp?.toDate() ?? DateTime.now();

    return _FeedItem(
      id: doc.id,
      category: _parseCategory(data['category'] as String?),
      isUrgent: _parseIsUrgent(data['urgency'] as String?),
      source: data['source'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      due: data['dueDate'] as String? ?? '',
      dueTs: data['dueDateTimestamp'] as int?,
      dueIsHot: _parseIsUrgent(data['urgency'] as String?),
      time: _formatTime(createdAt),
      dateGroup: _dateGroupLabel(createdAt),
      audience: data['audience'] as String? ?? '',
    );
  }

  List<_FeedItem> _visibleItems(List<_FeedItem> items) {
    final bypass = DevPrefs.bypassAudience;
    if (!bypass && !_isLoadingUser && _userDepartment != null) {
      items = items.where((item) {
        return item.audience == _userDepartment || item.audience == 'All dept.';
      }).toList();
    }

    if (_activeFilter == _FeedFilter.all) return items;

    return items.where((item) {
      switch (_activeFilter) {
        case _FeedFilter.urgent:
          return item.isUrgent;

        case _FeedFilter.academic:
          return item.category == _FeedCategory.academic;

        //   return item.category == _FeedCategory.personal;

        case _FeedFilter.financial:
          return item.category == _FeedCategory.financial;

        case _FeedFilter.all:
          return true;
      }
    }).toList();
  }

  List<String> _dateGroups(List<_FeedItem> items) {
    final seen = <String>{};
    final groups = <String>[];
    for (final item in items) {
      if (seen.add(item.dateGroup)) groups.add(item.dateGroup);
    }
    return groups;
  }

  int _unreadCount(List<_FeedItem> items) => items.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _broadcastStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: _accent),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Couldn\'t load the feed',
                      style: TextStyle(fontSize: 13, color: _textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Please check your connection and try again',
                      style: TextStyle(fontSize: 9, color: _textDim),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final items = docs.map(_itemFromDoc).toList();
            final visible = _visibleItems(items);

            return Column(
              children: [
                _buildHeader(items),
                Expanded(
                  // if the active filter returns nothing, show the empty state
                  child: visible.isEmpty
                      ? _buildEmptyState()
                      : _buildTimeline(visible),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<_FeedItem> allItems) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Feed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                ),
              ),
              if (_unreadCount(allItems) > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _badgeBgAcademic,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_unreadCount(allItems)} new',
                    style: const TextStyle(fontSize: 9, color: _badgeTxtAcademic),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _FeedFilter.values.map((f) => _buildFilterChip(f)).toList(),
            ),
          ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_FeedFilter filter) {
    final isActive = _activeFilter == filter;
    return AppPressable(
      haptic: false,
      // setState triggers a rebuild — _visibleItems recomputes with the new
      onTap: () {
        Haptics.select();
        setState(() => _activeFilter = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
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
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 10,
            color: isActive ? _textPrimary : _textMuted,
          ),
          child: Text(filter.label, maxLines: 1),
        ),
      ),
    );
  }

  Widget _buildTimeline(List<_FeedItem> items) {
    final groups = _dateGroups(items);
    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      children: [
        for (final group in groups) ...[
          _buildDateLabel(group),
          ..._buildGroupItems(items, groups, group),
        ],
      ],
    );
  }

  Widget _buildDateLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          color: _textDim,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // for every single group while looping
  List<Widget> _buildGroupItems(
    List<_FeedItem> items,
    List<String> groups,
    String group,
  ) {
    final groupItems = items.where((i) => i.dateGroup == group).toList();

    return List.generate(groupItems.length, (index) {
      final item = groupItems[index];
      final isLast = group == groups.last && index == groupItems.length - 1;
      return _buildTimelineRow(item, drawLine: !isLast);
    });
  }

  Widget _buildTimelineRow(_FeedItem item, {required bool drawLine}) {
    // if the item is urgent, the dot uses the urgent color regardless of
    final dotColor = item.isUrgent ? _colorUrgent : _categoryAccentColor(item.category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildCard(_FeedItem item) {
    // if urgent, the left border goes red — otherwise it uses the category color
    final leftBorderColor = item.isUrgent ? _colorUrgent : _categoryAccentColor(item.category);

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
            top: BorderSide(color: _border, width: 0.5),
            right: BorderSide(color: _border, width: 0.5),
            bottom: BorderSide(color: _border, width: 0.5),
            left: BorderSide(color: leftBorderColor, width: 2.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.source, style: TextStyle(fontSize: 9, color: _textMuted)),
                Text(item.time, style: TextStyle(fontSize: 9, color: _textDim)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: TextStyle(
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
                style: TextStyle(fontSize: 9, color: _textMuted, height: 1.5),
              ),
            ],
            if (item.dueTs != null) ...[
              const SizedBox(height: 4),
              Text(
                _dueCountdown(item.dueTs),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _dueStateFor(item.dueTs) == _DueState.overdue
                      ? _badgeTxtUrgent
                      : (item.dueIsHot ? _badgeTxtUrgent : _accent),
                ),
              ),
            ],
            if (DevPrefs.showRawIds) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16162a),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '[ID: ${item.id.length > 20 ? '${item.id.substring(0, 20)}…' : item.id}] [audience: ${item.audience}] [urgent: ${item.isUrgent}]',
                  style: const TextStyle(fontSize: 7, color: Color(0xFF4a4a6a), fontFamily: 'monospace', height: 1.3),
                ),
              ),
            ],
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(_FeedItem item) {
    // if the item is urgent, show an 'Urgent' badge alongside the category
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

  Widget _buildActionButton(String label, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary ? _actionPrimaryBg : _bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPrimary ? _actionPrimaryBorder : _border,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: isPrimary ? _actionPrimaryText : _textMuted,
        ),
      ),
    );
  }

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
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // Widget _buildNavBar() {
  //   return Container(

  // Widget _buildNavItem(String label, {bool isActive = false}) {
  //   return Column(
  //       const SizedBox(height: 3),

  Color _categoryAccentColor(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _colorAcademic,
        _FeedCategory.financial => _colorFinancial,
      };

  Color _categoryBadgeBg(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _badgeBgAcademic,
        _FeedCategory.financial => _badgeBgFinancial,
      };

  Color _categoryBadgeText(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _badgeTxtAcademic,
        _FeedCategory.financial => _badgeTxtFinancial,
      };

  String _categoryLabel(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => 'Academic',
        _FeedCategory.financial => 'Financial',
      };
}

enum _FeedFilter {
  all,
  urgent,
  academic,
  financial;

  String get label => switch (this) {
        _FeedFilter.all => 'All',
        _FeedFilter.urgent => 'Urgent',
        _FeedFilter.academic => 'Academic',
        _FeedFilter.financial => 'Financial',
      };
}

enum _FeedCategory { academic, financial }

enum _DueState { unknown, today, future, overdue }

class _FeedItem {
  final String id;
  final _FeedCategory category;
  final bool isUrgent;
  final String source;
  final String title;
  final String body;
  final String due;
  final int? dueTs;
  final bool dueIsHot;
  final String time;
  final String dateGroup;
  final String audience;

  const _FeedItem({
    required this.id,
    required this.category,
    this.isUrgent = false,
    required this.source,
    required this.title,
    required this.body,
    required this.due,
    required this.dueIsHot,
    this.dueTs,
    required this.time,
    required this.dateGroup,
    this.audience = '',
  });
}
