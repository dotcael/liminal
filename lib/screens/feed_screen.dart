// John 3:16-17

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dev/dev_prefs.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

// BUG FIX: replaced main ui colors with theme getters for light/dark toggle
// category + badge colors stay mostly const since they're semantic brand colors
class _FeedScreenState extends State<FeedScreen> {

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get _textDim => Theme.of(context).colorScheme.outline;

  // category accent colors — left border + timeline dot
  static const _colorAcademic = Color(0xFF5c5cd6);
  // static const _colorPersonal = Color(0xFF4a9a60);
  static const _colorFinancial = Color(0xFFc49040);
  // urgent is a flag, not a category — but it still needs its own color
  static const _colorUrgent = Color(0xFFd85a30);

  // BUG FIX: badge backgrounds now adapt to brightness
  Color get _badgeBgAcademic => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2a2a5a) : const Color(0xFFe0e0f8);
  static const _badgeTxtAcademic = Color(0xFF8888dd);
  // static const _badgeBgPersonal = Color(0xFF1a3a28);
  // static const _badgeTxtPersonal = Color(0xFF5abba0);
  Color get _badgeBgFinancial => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF3a2a10) : const Color(0xFFf8f0d6);
  static const _badgeTxtFinancial = Color(0xFFc49040);
  // urgent badge colors — used whenever isUrgent is true, regardless of category
  Color get _badgeBgUrgent => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF3a1a1a) : const Color(0xFFfce8e0);
  static const _badgeTxtUrgent = Color(0xFFd87a5a);

  // BUG FIX: action button also theme-aware
  Color get _actionPrimaryBg => Theme.of(context).colorScheme.primaryContainer;
  Color get _actionPrimaryBorder => Theme.of(context).colorScheme.primary;
  Color get _actionPrimaryText => Theme.of(context).colorScheme.onPrimaryContainer;

  // the currently selected filter chip — defaults to showing everything
  _FeedFilter _activeFilter = _FeedFilter.all;

  // BUG FIX: audience filtering — track user's department so feed only shows
  // broadcasts meant for their dept + 'All dept.' announcements
  String? _userDepartment;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserDepartment();
  }

  // BUG FIX: force rebuild when theme changes so getters pick up new colors
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  // BUG FIX: fetch current user's department from Firestore for audience filter
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

  // ── Firestore ─────────────────────────────────────────────────────────────────
  // the broadcast collection, ordered newest-first — same collection
  // _UploadSheet writes to from the home screen's broadcast tab.
  // declared once as a Stream so StreamBuilder doesn't recreate the query
  // (and therefore re-subscribe) on every rebuild
  final Stream<QuerySnapshot> _broadcastStream = FirebaseFirestore.instance
      .collection('broadcast')
      .orderBy('createdAt', descending: true)
      .snapshots();

  // ── mapping helpers: Firestore doc → _FeedItem ───────────────────────────────

  // converts the 'urgency' string field ('Urgent' / 'Soon' / 'Later') into the
  // isUrgent boolean this screen actually displays with. anything that isn't
  // exactly 'Urgent' is treated as not urgent
  bool _parseIsUrgent(String? value) => value == 'Urgent';

  // converts the 'category' string field into the _FeedCategory enum.
  // defaults to academic if the field is missing or doesn't match —
  // broadcasts are only ever tagged Academic or Financial from the upload
  // sheet's category chips, but this keeps the mapping safe either way
  _FeedCategory _parseCategory(String? value) {
    switch (value) {
      case 'Financial':
        return _FeedCategory.financial;
      // case 'Personal':
      //   return _FeedCategory.personal;
      default:
        return _FeedCategory.academic;
    }
  }

  // groups a createdAt DateTime into 'Today', 'Yesterday', or a short date
  // label for anything older. comparing year/month/day directly (not just
  // subtracting durations) avoids the classic bug where "23 hours ago" is
  // wrongly called Today or Yesterday depending on the time of day
  String _dateGroupLabel(DateTime createdAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final difference = today.difference(itemDay).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    // intl's DateFormat — already a project dependency — handles the rest
    return DateFormat('EEE, MMM d').format(createdAt);
  }

  // formats the time-of-day shown in the top-right of each card, e.g. '8:02am'
  // DateFormat gives 'AM'/'PM' in caps, so it's lowercased to match the
  // original mockup's style
  String _formatTime(DateTime createdAt) {
    return DateFormat('h:mma').format(createdAt).toLowerCase();
  }

  // converts a single Firestore document into the _FeedItem this screen
  // already knows how to render — keeps all the Firestore-specific field
  // names contained to this one function
  _FeedItem _itemFromDoc(QueryDocumentSnapshot doc) {
    // cast the doc data to a Map so individual fields can be read by key
    final data = doc.data() as Map<String, dynamic>;

    // createdAt is a Firestore Timestamp object, not a DateTime — toDate()
    // converts it. it can briefly be null right after a write, before the
    // server timestamp round-trips back down, so fall back to now() then
    final Timestamp? timestamp = data['createdAt'] as Timestamp?;
    final createdAt = timestamp?.toDate() ?? DateTime.now();

    return _FeedItem(
      // doc.id is the Firestore-generated document id — used as the
      // ListView/Dismissible key equivalent if this screen ever needs one
      id: doc.id,
      category: _parseCategory(data['category'] as String?),
      isUrgent: _parseIsUrgent(data['urgency'] as String?),
      source: data['source'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      due: data['dueDate'] as String? ?? '',
      // the due date badge turns the urgent color whenever the post itself
      // is urgent — there's no separate "hot" flag stored in Firestore
      dueIsHot: _parseIsUrgent(data['urgency'] as String?),
      time: _formatTime(createdAt),
      dateGroup: _dateGroupLabel(createdAt),
      // BUG FIX: read audience from Firestore doc so feed can filter it
      audience: data['audience'] as String? ?? '',
    );
  }

  // ── computed properties ───────────────────────────────────────────────────────

  // BUG FIX: audience filter — if _userDepartment is known, only show broadcasts
  // targeting that department or 'All dept.' so students dont see irrelevant announcements
  //
  // filters a list of items based on which chip is active.
  // takes the list in as a parameter (rather than reading a field) because
  // the source list now comes from the StreamBuilder snapshot each rebuild,
  // not from a stored _items field
  List<_FeedItem> _visibleItems(List<_FeedItem> items) {
    // first pass: audience filter — devs can bypass with toggle
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
          // urgent filter shows any item flagged as urgent, across all categories
          return item.isUrgent;

        case _FeedFilter.academic:
          return item.category == _FeedCategory.academic;

        // case _FeedFilter.personal:
        //   return item.category == _FeedCategory.personal;

        case _FeedFilter.financial:
          return item.category == _FeedCategory.financial;

        // safeguard in case the switch reaches here
        case _FeedFilter.all:
          return true;
      }
    }).toList();
  }

  // pulls unique date group labels in the order they appear — keeps sections
  // sorted the same way the underlying (already newest-first) query is sorted
  List<String> _dateGroups(List<_FeedItem> items) {
    final seen = <String>{};
    final groups = <String>[];
    for (final item in items) {
      if (seen.add(item.dateGroup)) groups.add(item.dateGroup);
    }
    return groups;
  }

  // counts how many items are unread for the header badge.
  // NOTE: there's no read/unread tracking wired to Firestore yet — every
  // broadcast is currently treated as unread. revisit once a per-user
  // "read receipts" field or local read-state cache is added
  int _unreadCount(List<_FeedItem> items) => items.length;

  // ── build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        // StreamBuilder rebuilds automatically every time the 'broadcast'
        // collection changes — no manual refresh button or polling needed
        child: StreamBuilder<QuerySnapshot>(
          stream: _broadcastStream,
          builder: (context, snapshot) {
            // still waiting on the very first snapshot — show a spinner
            // instead of a flash of the empty state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: _accent),
              );
            }

            // BUG FIX: show actual error message so dev can debug without guessing
            // something went wrong talking to Firestore (offline, rules
            // rejection, etc.) — surface it instead of pretending it's empty
            if (snapshot.hasError) {
              final errMsg = snapshot.error.toString();
              // BUG FIX: common dev-mode issue — auth bypassed but Firestore rules
              // require auth. show a clearer message for that case
              final displayMsg = errMsg.contains('permission-denied')
                  ? 'Feed unavailable — log in required'
                  : 'Couldn\'t load the feed';
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayMsg,
                      style: TextStyle(fontSize: 13, color: _textMuted),
                    ),
                    // BUG FIX: show the real error underneath for debugging
                    const SizedBox(height: 6),
                    Text(
                      errMsg.length > 80
                          ? '${errMsg.substring(0, 80)}…'
                          : errMsg,
                      style: TextStyle(fontSize: 9, color: _textDim),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // snapshot.data!.docs is the live list of broadcast documents —
            // map each one into the _FeedItem shape the rest of this screen
            // already knows how to render
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
                // _buildNavBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────────
  // takes the full (unfiltered) item list so the unread badge always reflects
  // every broadcast, not just whatever the current filter chip shows
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
              // unread badge — only shown when there are unread items
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
          // scrollable filter chip row — maps every _FeedFilter value to a chip
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // makes a filter chip for every enum value (all, urgent,
              // academic, personal, financial) — adding a new filter later
              // only means adding it to the enum, not touching this Row
              children: _FeedFilter.values.map((f) => _buildFilterChip(f)).toList(),
            ),
          ),
          const SizedBox(height: 1),
        ],
      ),
    );
  }

  // ── filter chip ───────────────────────────────────────────────────────────────
  Widget _buildFilterChip(_FeedFilter filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      // setState triggers a rebuild — _visibleItems recomputes with the new
      // filter against whatever the StreamBuilder's latest snapshot is
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

  // builds the timeline rows for a single date group.
  // groups is passed in (rather than recomputed) so "is this the very last
  // row in the whole list" can be checked without rebuilding the group list
  // for every single group while looping
  List<Widget> _buildGroupItems(
    List<_FeedItem> items,
    List<String> groups,
    String group,
  ) {
    final groupItems = items.where((i) => i.dateGroup == group).toList();

    return List.generate(groupItems.length, (index) {
      final item = groupItems[index];
      // the very last item across all groups gets no connector line below it
      final isLast = group == groups.last && index == groupItems.length - 1;
      return _buildTimelineRow(item, drawLine: !isLast);
    });
  }

  // ── timeline row ──────────────────────────────────────────────────────────────
  Widget _buildTimelineRow(_FeedItem item, {required bool drawLine}) {
    // if the item is urgent, the dot uses the urgent color regardless of
    // category — otherwise it falls back to that category's own color
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
            top: BorderSide(color: _border, width: 0.5),
            right: BorderSide(color: _border, width: 0.5),
            bottom: BorderSide(color: _border, width: 0.5),
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
                // badge shows the real category, plus an urgent tag if needed
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

  // ── badge ─────────────────────────────────────────────────────────────────────
  Widget _buildBadge(_FeedItem item) {
    // if the item is urgent, show an 'Urgent' badge alongside the category
    // badge — this makes both the category and urgency visible at a glance
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
  // kept as a standalone helper for now — not currently called from _buildCard
  // since the feed has no real "Add to calendar" / "Dismiss" backend behavior
  // wired up yet. left here, with named color constants, so it's ready to be
  // reattached once those actions actually do something
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
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 13, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ── nav bar ───────────────────────────────────────────────────────────────────
  // left commented out — nav wiring lives outside this file (ShellScreen),
  // kept here only as a visual reference for matching styles
  // Widget _buildNavBar() {
  //   return Container(
  //     decoration: const BoxDecoration(
  //       border: Border(top: BorderSide(color: _border, width: 0.5)),
  //     ),
  //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         _buildNavItem('Home', isActive: false),
  //         _buildNavItem('Feed', isActive: true),
  //         _buildNavItem('Tasks', isActive: false),
  //         _buildNavItem('Profile', isActive: false),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildNavItem(String label, {bool isActive = false}) {
  //   return Column(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         width: 18,
  //         height: 18,
  //         decoration: BoxDecoration(
  //           color: isActive ? const Color(0xFF3a3a7a) : const Color(0xFF2d2d4a),
  //           borderRadius: BorderRadius.circular(5),
  //         ),
  //       ),
  //       const SizedBox(height: 3),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 9,
  //           color: isActive ? const Color(0xFF7b7bcc) : _textMuted,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ── helpers: map category enum → colors / labels ─────────────────────────────
  Color _categoryAccentColor(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _colorAcademic,
        // _FeedCategory.personal => _colorPersonal,
        _FeedCategory.financial => _colorFinancial,
      };

  Color _categoryBadgeBg(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _badgeBgAcademic,
        // _FeedCategory.personal => _badgeBgPersonal,
        _FeedCategory.financial => _badgeBgFinancial,
      };

  Color _categoryBadgeText(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => _badgeTxtAcademic,
        // _FeedCategory.personal => _badgeTxtPersonal,
        _FeedCategory.financial => _badgeTxtFinancial,
      };

  String _categoryLabel(_FeedCategory cat) => switch (cat) {
        _FeedCategory.academic => 'Academic',
        // _FeedCategory.personal => 'Personal',
        _FeedCategory.financial => 'Financial',
      };
}

// ── enums ─────────────────────────────────────────────────────────────────────
enum _FeedFilter {
  all,
  urgent,
  academic,
  // personal,
  financial;

  String get label => switch (this) {
        _FeedFilter.all => 'All',
        _FeedFilter.urgent => 'Urgent',
        _FeedFilter.academic => 'Academic',
        // _FeedFilter.personal => 'Personal',
        _FeedFilter.financial => 'Financial',
      };
}

// urgent is not a category — it's a standalone flag on _FeedItem
enum _FeedCategory { academic, financial }

// ── data model ────────────────────────────────────────────────────────────────
class _FeedItem {
  // the Firestore document id — kept around in case a future iteration adds
  // per-item actions (mark read, delete) that need to target a specific doc
  final String id;
  final _FeedCategory category;
  // isUrgent is a standalone boolean flag — any category can be urgent
  final bool isUrgent;
  final String source;
  final String title;
  final String body;
  final String due;
  final bool dueIsHot;
  final String time;
  final String dateGroup;
  // BUG FIX: added audience field so feed can filter by department
  final String audience;

  const _FeedItem({
    required this.id,
    required this.category,
    // isUrgent defaults to false — most items are not urgent
    this.isUrgent = false,
    required this.source,
    required this.title,
    required this.body,
    required this.due,
    required this.dueIsHot,
    required this.time,
    required this.dateGroup,
    // BUG FIX: audience defaults to empty — filtered out until user dept is loaded
    this.audience = '',
  });
}