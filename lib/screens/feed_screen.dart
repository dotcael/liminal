import 'package:flutter/material.dart';

//stateful to do shi like changing based on what filter is picked

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {

  //static mean constants belong to the class not an instance thus they dont
  // need this.x to be used.

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

  //Acticely selected filter, Defaults to showing all
  _FeedFilter _activeFilter = _FeedFilter.all;

  //Feed items
  final List<_FeedItem> _items = const [
    _FeedItem(
      isUrgent: true,
      category: _FeedCategory.academic,
      source: 'Mr. Musa · CS Dept',
      title: 'Assignment 3 deadline update',
      body: 'Submissions close at Friday, 10pm. Late submissions will not be accepted',
      due: '2 days left',
      dueIsHot: true,
      time: '8:02',
      isUnread: true,
      dateGroup: 'Today',
    ),
    _FeedItem(
      category: _FeedCategory.academic,
      source: 'Head of Department',
      title: 'Exam hall is FAC one',
      body: ' Second floor, room three',
      due: 'Tomorrow',
      dueIsHot: false,
      time: '12:00',
      isUnread: false,
      dateGroup: 'Today',
      actions: ['Add to calendar', 'Dismiss'],
    ),
    _FeedItem(
      category: _FeedCategory.academic,
      source: 'Dr Mutumba',
      title: 'Class presentation today, starting 10pm',
      body: ' Fourth floor, room three',
      due: 'Tomorrow',
      dueIsHot: false,
      time: '12:00',
      isUnread: false,
      dateGroup: 'Today',
    ),
    _FeedItem(
      isUrgent: true,
      category: _FeedCategory.financial,
      source: 'Finance Office',
      title: 'Second Semester fees - arrears',
      body: 'Payment must be done by March 3rd, to be elligable for subsequent exams',
      due: 'Tomorrow',
      dueIsHot: false,
      time: '12:00',
      isUnread: false,
      dateGroup: 'Today',
      actions: ['Add to calendar', 'Dismiss'],
    ),
    _FeedItem(
      isUrgent: true,
      category: _FeedCategory.personal,
      source: 'Personal',
      title: 'Revise Study Questions',
      body: ' Study CAT 2 exam questions',
      due: 'Today',
      dueIsHot: true,
      time: '8:03am',
      isUnread: true,
      dateGroup: 'Yesterday',
    ),
  ];

  //filter items based on active filter
  List<_FeedItem> get _visibleItems {
    if (_activeFilter == _FeedFilter.all) return _items;

    //where loops through and only returns those that pass the test
    return _items.where((item) {
      switch (_activeFilter) {
        case _FeedFilter.urgent:
          return item.isUrgent;
        case _FeedFilter.academic:
          return item.category == _FeedCategory.academic;
        case _FeedFilter.financial:
          return item.category == _FeedCategory.financial;
        case _FeedFilter.personal:
          return item.category == _FeedCategory.personal;
        // safety fallback
        case _FeedFilter.all:
          return true;
      }
    }).toList();
  }

  List<String> get _dateGroups {
    final seen = <String>{};
    final groups = <String>[];

    for (final item in _visibleItems) {
      if (seen.add(item.dateGroup)) groups.add(item.dateGroup);
    }
    return groups;
  }

  //counts unread items
  int get _unreadCount => _items.where((i) => i.isUnread).length;

  //build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              // if active filter returns nothing, show the empty state
              child: _visibleItems.isEmpty ? _buildEmptyState() : _buildTimeline(),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // define the header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      decoration: const BoxDecoration(
        // FIX: BorderState → BorderSide
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

              //unread badge
              // conditional spread — if 0 unread, nothing added
              // if > 0, both the spacer and badge drop in as a unit
              if (_unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  // FIX: symmmetric → symmetric
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _badgeBgAcademic,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // $ inserts the value of _unreadCount into the string
                  child: Text(
                    '$_unreadCount new',
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
              // FIX: _feedFilterValues → _FeedFilter.values
              // FIX: .List() → .toList()
              // FIX: childern → children
              // .map() loops through every enum value and calls _buildFilterChip with it
              // (f) is the name we gave each value as it comes through the loop
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

  // Filter chip that lights up when active
  // 'filter' parameter receives whichever enum value .map() is currently on
  Widget _buildFilterChip(_FeedFilter filter) {
    // isActive is true only when this chip matches the currently selected filter
    final isActive = _activeFilter == filter;

    return GestureDetector(
      // FIX: GestureDector → GestureDetector
      // FIX: onTap() >= → onTap: () =>
      // setState tells Flutter something changed, trigger a rebuild
      // _activeFilter updates to this chip's value, _visibleItems recomputes
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          // ternary — active gets accent fill, inactive gets surface
          color: isActive ? _accent : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _accent : _border,
            width: 0.5,
          ),
        ),
        // filter.label calls the label getter on the enum — returns 'Academic', 'Urgent' etc
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

  //Timeline
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
      // FIX: padding → Padding (widget name is capitalised)
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          color: _textDim,
          // FIX: letterSpace → letterSpacing
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  List<Widget> _buildGroupItems(String group) {
    // FIX: =- → == (was assigning instead of comparing)
    final groupItems = _visibleItems.where((i) => i.dateGroup == group).toList();

    return List.generate(groupItems.length, (index) {
      final item = groupItems[index];

      //last item does not get a line connector
      final isLast = group == _dateGroups.last && index == groupItems.length - 1;
      return _buildTimelineRow(item, drawLine: !isLast);
    });
  }

  //timeline row
  //left dots and lines connecting them and the card they associate with
  Widget _buildTimelineRow(_FeedItem item, {required bool drawLine}) {
    // if the item is urgent, the dot uses the urgent color regardless of category
    // else use the default category color — blue for academic, green for personal, yellow for financial
    // FIX: _colorIsUrgent → _colorUrgent
    final dotColor = item.isUrgent ? _colorUrgent : _categoryAccentColor(item.category);

    // IntrinsicHeight makes the left column match the card's height
    // so the vertical line stretches exactly as tall as the card next to it
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //left column, the dot and the vertical line connector
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  // FIX: height, 9 → height: 9
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

          //right column, the card
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 14, bottom: 6,
          top: 6),
          child: _buildCard(item),),),

        ],
      ),
    );
  }

  //card
  Widget _buildCard(_FeedItem item) {
    //if item is urgent use urgentcolor on border else use the default category color
    final leftBorderColor = item.isUrgent ? _colorUrgent : _categoryAccentColor(item.category);
    // FIX: cardBg was never declared
    final cardBg = item.isUrgent ? const Color(0xFF231a1a) : _surface;

    //clip rect keeps the right side rounded and the left side straight and colored accordingly
    return ClipRRect(borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10),),

    child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: cardBg,
     border: Border(top: const BorderSide(color: _border, width: 0.5),
     right: const BorderSide(color: _border, width: 0.5),
     bottom: const BorderSide(color: _border, width: 0.5),
     left: BorderSide(color: leftBorderColor, width: 2.5),),),

     child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
       //source and timestamp
       // FIX: MainAxisAlignment.start → MainAxisAlignment.spaceBetween
       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
         // FIX: _textmuted → _textMuted
         Text(item.source, style: const TextStyle(fontSize: 9, color: _textMuted)),
         Text(item.time, style: const TextStyle(fontSize: 9, color: _textDim)),
       ],),

       const SizedBox(height: 4),
       Text(
        item.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
        color: _textPrimary, height: 1.4,),
       ),

       if (item.body.isNotEmpty) ...[const SizedBox(height: 2),
         // FIX: _textmuted → _textMuted, colon after _textMuted → comma
         Text(item.body, style: const TextStyle(fontSize: 9, color: _textMuted, height: 1.5),),
       ],

       const SizedBox(height: 7),
       Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
        //bad to show categoty not urgency
        _buildBadge(item),
        Text(item.due, style: TextStyle(fontSize: 9, color: item.dueIsHot ? _badgeTxtUrgent : _textDim,),),
       ],),

       if (item.actions.isNotEmpty) ...[
         const SizedBox(height: 8),
         // FIX: item,actions → item.actions
         Row(children: item.actions.map((label) {
           final isPrimary = item.actions.indexOf(label) == 0;
           return Padding(padding: const EdgeInsets.only(right: 6),
           child: _buildActionButton(label, isPrimary: isPrimary),);
         }).toList(),),
       ],
      ],
     ),
    ),
   );
  }

  //badge i am here
  Widget _buildBadge(_FeedItem item){
   // if the item is urgent, show an 'Urgent' badge on top of the category badge
    // this makes both the category and urgency visible at a glance

  return Row(mainAxisSize: MainAxisSize.mi n)

  }

}

//data model
class _FeedItem {
  final _FeedCategory category;
  final bool isUrgent;
  final bool dueIsHot;
  final bool isUnread;
  final String source;
  final String title;
  final String body;
  final String due;
  final String time;
  final String dateGroup;
  final List<String> actions;

  const _FeedItem({
    this.isUrgent = false,
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

// ── enums ─────────────────────────────────────────────────────────────────────
// these live outside the class at file level
// _FeedFilter drives the chips and which items are visible
// _FeedCategory is separate — urgency is a flag (isUrgent) not a category
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

enum _FeedCategory { academic, personal, financial }