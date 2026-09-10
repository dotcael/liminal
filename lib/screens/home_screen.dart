// John 3:16-17
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../dev/dev_prefs.dart';
import '../services/notification_service.dart';
import '../services/reminder_prefs.dart';
import '../widgets/app_toast.dart';
import '../widgets/date_time_sheet.dart';
import '../widgets/haptics.dart';
import '../widgets/pressable.dart';
import '../widgets/reminder_slider.dart';
import 'settings_screen.dart';

enum _Urgency {urgent, soon , later}

// BUG FIX: smart views (iPhone Reminders-style) that filter the personal task
// list on top of the urgency groups: All / Today / Scheduled
enum _ViewFilter { all, today, scheduled }

class HomeScreen extends StatefulWidget{

final String name;
final String role;

const HomeScreen({super.key, required this.name, required this.role});

@override 
State<HomeScreen> createState()=> _HomeScreenState();
}

// BUG FIX: all colors now use theme getters so light/dark toggle actually works
class _HomeScreenState extends State<HomeScreen>{
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textSecondary => Theme.of(context).colorScheme.onSurfaceVariant;

  // BUG FIX: urgency text stays the same, but backgrounds adapt to brightness
  static const _urgentText = Color(0xFFd87a5a);
  Color get _urgentBg => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2a1a1a) : const Color(0xFFfce8e0);
  static const _soonText = Color(0xFFc49040);
  Color get _soonBg => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2a2010) : const Color(0xFFfff3d6);
  static const _laterText = Color(0xFF5abcd8);
  Color get _laterBg => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF1a3a42) : const Color(0xFFe0f2f5);

  //load tasks from local storage
  List<Map<String, dynamic>> _tasks= [];

  // BUG FIX: active smart-view filter (Today / Scheduled / All)
  _ViewFilter _viewFilter = _ViewFilter.all;

  //loader
  bool _isLoading = true;

  //key used to store and retrieve task list 
  static const _storageKey = 'personal_tasks';

  @override
  void initState(){
super.initState(); //call superclass initState

_loadTasks();
  }

  // BUG FIX: force rebuild when theme changes so getters pick up new colors
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }

  Future<void> _loadTasks() async{
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_storageKey);
if(raw != null){

final decoded = jsonDecode(raw) as List<dynamic>;
setState((){
_tasks = decoded.cast<Map<String,dynamic>>();
for (final task in _tasks) {
  // BUG FIX: only re-derive urgency from the due date for auto tasks;
  // manual override choices are preserved as stored
  if (task['urgencyManual'] != true) {
    task['urgency'] = _urgencyString(_computeUrgency(task['dueDateTimestamp'] as int?));
  }
}

});

// Re-sync local reminders for uncompleted, not-yet-due tasks after a restart.
// cancelTaskReminders() runs first inside scheduleTaskReminders(), so pending
// reminders are idempotent — never duplicated across app launches.
for (final task in _tasks) {
  await _scheduleReminders(task);
}


}
 setState(() => _isLoading = false);
  }

  Future<void> _saveTasks() async{
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_storageKey, jsonEncode(_tasks));
  }

//convert urgency string n local storge to enum
// BUG FIX: case-insensitive — legacy stored values from _computeUrgency(...).name
// were lowercase ('urgent'/'soon'/'later') and silently fell through to _later

_Urgency _parseUrgency (String? value){
switch (value?.trim().toLowerCase()){
  case 'urgent' : return _Urgency.urgent;
  case 'soon' : return _Urgency.soon;
  default : return _Urgency.later;
}

}

//deletion. takss gets removed (using its id) and redrawn first, 
// then _saveTasks updates the local storage in the background

Future<void> _deleteTask(String id) async{
await NotificationService.cancelTaskReminders(id);
setState((){
_tasks.removeWhere((task) => task['id'] == id);

});
await _saveTasks();

}

final Map<String, Timer> _completionTimers = {};

@override
void dispose() {
  for (final t in _completionTimers.values) {
    t.cancel();
  }
  super.dispose();
}

Future<void> _toggleCompletion(String id) async {
  if (_completionTimers.containsKey(id)) {
    _completionTimers[id]!.cancel();
    _completionTimers.remove(id);
    setState(() {
      final idx = _tasks.indexWhere((task) => task['id'] == id);
      if (idx != -1) {
        _tasks[idx]['isCompleted'] = false;
      }
    });
    await _saveTasks();
    // un-completing before the 3s window: reminders come back
    await _scheduleReminders(_tasks.firstWhere((t) => t['id'] == id));
    return;
  }

  final wasCompleted = _tasks.firstWhere((t) => t['id'] == id)['isCompleted'] as bool? ?? false;

  if (!wasCompleted) {
    setState(() {
      final idx = _tasks.indexWhere((task) => task['id'] == id);
      if (idx != -1) {
        _tasks[idx]['isCompleted'] = true;
      }
    });
    await _saveTasks();
    // task is done — stop nagging about it
    await NotificationService.cancelTaskReminders(id);

    final messenger = ScaffoldMessenger.of(context);

    _completionTimers[id] = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final removedTask = Map<String, dynamic>.from(
        _tasks.firstWhere((t) => t['id'] == id),
      );
      _completionTimers.remove(id);

      setState(() {
        _tasks.removeWhere((task) => task['id'] == id);
      });
      await _saveTasks();

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Task completed'),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _tasks.insert(0, removedTask);
              });
              _saveTasks();
              _scheduleReminders(removedTask);
            },
          ),
        ),
      );
    });
  } else {
    setState(() {
      final idx = _tasks.indexWhere((task) => task['id'] == id);
      if (idx != -1) {
        _tasks[idx]['isCompleted'] = false;
      }
    });
    await _saveTasks();
    // task pulled back out of completed state — reminders return
    await _scheduleReminders(_tasks.firstWhere((t) => t['id'] == id));
  }
}

//called by upload sheet
Future<void> _addTask(Map<String,dynamic> task) async{
  // BUG FIX: only auto-assign urgency from the due date for auto tasks;
  // a manual override selection is kept as chosen in the upload sheet
  if (task['urgencyManual'] != true) {
    final timestamp = task['dueDateTimestamp'] as int?;
    task['urgency'] = _urgencyString(_computeUrgency(timestamp));
  }

  setState((){

//insert at index 0 so its the first
_tasks.insert(0,task);
 });

 await _saveTasks(); //to save it so it stays when the app is restarted
 await _scheduleReminders(task);
}

/// Schedules local reminders (pre-reminder + due time) for a task, honoring
/// the master switch, the user's default offset, and a per-task override.
/// Reminders cancel themselves for tasks with no due date or already done.
Future<void> _scheduleReminders(Map<String, dynamic> task) async {
  if (!ReminderPrefs.enabled) return;
  if (task['isCompleted'] == true) return;
  final ts = task['dueDateTimestamp'] as int?;
  if (ts == null) return;

  final override = task['preReminderMinutes'] as int?;
  final pre = override ?? ReminderPrefs.preReminderMinutes;

  await NotificationService.scheduleTaskReminders(
    taskId: task['id'] as String,
    taskName: task['taskName'] as String? ?? 'Task',
    dueDate: DateTime.fromMillisecondsSinceEpoch(ts),
    preReminderMinutes: pre,
  );
}

@override
Widget build(BuildContext context){

// renders the full screen scaffold with a navy background,
// a floating action button pinned above the nav bar, and either
// a loading spinner or the main task list depending on _isLoading
return Scaffold(
  backgroundColor: _bg,
  body: SafeArea(
     // brief spinner while shared preference loads on first mount
child: _isLoading ? const Center(child: CircularProgressIndicator(
  color: Color(0xFF4a4aaa)),) : _buildContent(),
  ),

  floatingActionButton: Padding(padding: const EdgeInsets.only(bottom: 63),
  child: _buildFab(context),),

  floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
);

}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  if (hour >= 17 && hour < 22) return 'Good evening';
  return 'Good night';
}

_Urgency _computeUrgency(int? dueDateTimestamp) {
  if (dueDateTimestamp == null) return _Urgency.later;
  final remaining = DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp)
      .difference(DateTime.now())
      .inHours;
  if (remaining <= 24) return _Urgency.urgent;
  if (remaining <= 72) return _Urgency.soon;
  return _Urgency.later;
}

// BUG FIX: canonical capitalized labels so stored values always match the
// chip options and _parseUrgency (no more lowercase 'urgent'/'soon' values)
String _urgencyString(_Urgency urgency) => switch (urgency) {
  _Urgency.urgent => 'Urgent',
  _Urgency.soon => 'Soon',
  _Urgency.later => 'Later',
};

String _daysRemaining(int? dueDateTimestamp) {
  if (dueDateTimestamp == null) return '';
  final due = DateTime.fromMillisecondsSinceEpoch(dueDateTimestamp);
  final now = DateTime.now();
  final diff = due.difference(now);
  final days = diff.inDays;
  if (days < 0) {
    final overdue = -days;
    return overdue == 1 ? 'Overdue by 1 day' : 'Overdue by $overdue days';
  }
  if (days == 0) return 'Due today';
  if (days == 1) return '1 day left';
  return '$days days left';
}

// renders the header + scrollable task list grouped by urgency 
// counts tasks per urgency bucket first for the summary chips and section labels stay accurate
Widget _buildContent(){
//loops through tasks  to count urgency fields tobuid the summary chips

int urgentCount = 0;
int soonCount = 0;
int laterCount = 0;

final visibleTasks = _filteredTasks();

for (final task in visibleTasks){
final urgency = _parseUrgency(task['urgency'] as String?);
if(urgency == _Urgency.urgent) urgentCount++;
else if (urgency == _Urgency.soon) soonCount++;
else laterCount++;
}

return Column(
  children: [_buildHeader(urgentCount, soonCount, laterCount),
  _buildViewFilterRow(),

  Expanded(child: visibleTasks.isEmpty ? _buildEmptyState() : SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [ 
 // each section only renders if it has tasks
// if urgentCount is 0 the entire urgent block is skipped
                       if (urgentCount > 0) ...[
_buildSectionLabel('Urgent'), ...visibleTasks.where((task)=> _parseUrgency(task['urgency']
as String?) == _Urgency.urgent).map((task) => _buildDismissibleCard(taskId: task['id'] as String,
title: task['taskName'] as String? ?? '', meta: task['dueDate'] as String? ?? '', urgency: _Urgency.urgent,
isCompleted: task['isCompleted'] as bool? ?? false,
notes: task['notes'] as String?,
dueDateTimestamp: task['dueDateTimestamp'] as int?)),

                       ],
                       if (soonCount > 0) ...[
                         _buildSectionLabel('Up next'),
                         ...visibleTasks.where((task)=> _parseUrgency(task['urgency'] as String?) == _Urgency.soon).map((task)
                         => _buildDismissibleCard(
                           taskId: task['id'] as String,
                         title: task['taskName'] as String? ??'',
                         meta: task['dueDate'] as String? ??'',
                         urgency: _Urgency.soon,
                         isCompleted: task['isCompleted'] as bool? ?? false,
                         notes: task['notes'] as String?,
                         dueDateTimestamp: task['dueDateTimestamp'] as int?,
                         )),
                       ],

                       if(laterCount > 0) ...[
                         _buildSectionLabel('Later'), ...visibleTasks.where((task)=>
                          _parseUrgency(task['urgency'] as String?) == _Urgency.later).map((task) => _buildDismissibleCard(
                           taskId: task['id'] as String,
                           title: task['taskName'] as String? ??'',
                           meta: task['dueDate'] as String? ?? '',
                           urgency: _Urgency.later,
                           isCompleted: task['isCompleted'] as bool? ?? false,
                           notes: task['notes'] as String?,
                           dueDateTimestamp: task['dueDateTimestamp'] as int?,

                          )),
                       ],
                      const SizedBox(height: 80),

],

),

  ), ),
],);

}// BUG FIX: smart-view filtering. Today = due today or overdue (missed items
// shouldn't vanish), Scheduled = has a due date at all, All = everything.
List<Map<String, dynamic>> _filteredTasks() {
  final now = DateTime.now();
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  return _tasks.where((task) {
    if (task['isCompleted'] == true) return false;
    if (_viewFilter == _ViewFilter.all) return true;
    final ts = task['dueDateTimestamp'] as int?;
    if (ts == null) return false;
    if (_viewFilter == _ViewFilter.today) {
      return !DateTime.fromMillisecondsSinceEpoch(ts).isAfter(endOfToday);
    }
    return true; // scheduled
  }).toList();
}

// BUG FIX: compact smart-view switcher (All / Today / Scheduled) styled like
// the rest of the pills — 3 always-visible options beat a dropdown here
Widget _buildViewFilterRow() {
  const options = [
    (label: 'All', filter: _ViewFilter.all),
    (label: 'Today', filter: _ViewFilter.today),
    (label: 'Scheduled', filter: _ViewFilter.scheduled),
  ];
  return Padding(
    padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
    child: Row(
children: options.map((o) {
  final selected = _viewFilter == o.filter;
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
    child: AppPressable(
      haptic: false,
      onTap: () {
        Haptics.select();
        setState(() => _viewFilter = o.filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2a2a5a) : _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _accent : const Color(0xFF3a3a6a),
            width: 0.5,
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: TextStyle(
            fontSize: 10,
            color: selected ? const Color(0xFFa0a0ee) : _textSecondary,
          ),
          child: Text(
            o.label,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ),
    ),
    ),
  );
}).toList(),
    ),
  );
}

// renders a swipeable wrapper around a task card — swiping left reveals a red
// delete background with a bin icon, then removes the task from the list and local storage

// BUG FIX: added isCompleted so the checkbox + dimmed styling works on the card
Widget _buildDismissibleCard({required String taskId, required String title, 
required String meta, required _Urgency urgency, required bool isCompleted, String? notes, int? dueDateTimestamp,}) {
  return Dismissible(
//uses the key to id whichc card to delete

key: Key(taskId),

direction: DismissDirection.endToStart,

//the background tha shows after a swipe
background: Container(

margin: const EdgeInsets.fromLTRB(14,0,14,6),
// BUG FIX: was `border: BorderRadius.circular(16)` — border takes a Border not a BorderRadius
// the correct field for rounding corners on BoxDecoration is borderRadius
decoration: BoxDecoration(color: const Color(0xFF8a1a1a), borderRadius: BorderRadius.circular(16)),
// BUG FIX: Alignment.centerRght typo — fixed to Alignment.centerRight
alignment: Alignment.centerRight,
padding:const EdgeInsets.only(right:20),
child: const Icon(Icons.delete_outline,color: Color(0xFFe8e8f4), size: 20),

),

//called when user lifts finger after swipe.true confirms deletion, false snaps the card back

// BUG FIX: deletion moved from confirmDismiss into onDismissed so we can offer
// undo — the task still exists until the fly-away animation actually completes
confirmDismiss: (direction) async{
  Haptics.warning();
  return true;
},

//fires after the card flies away — delete, then offer undo via snackbar
onDismissed: (direction) async {
  final idx = _tasks.indexWhere((task) => task['id'] == taskId);
  if (idx == -1) return;
  final removedTask = Map<String, dynamic>.from(_tasks[idx]);

  await _deleteTask(taskId);
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Deleted "$title"'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          setState(() {
            _tasks.insert(0, removedTask);
          });
          _saveTasks();
          _scheduleReminders(removedTask);
        },
      ),
    ),
  );
},

child: _buildTaskCard(taskId: taskId, title: title, meta : meta, urgency: urgency, isCompleted: isCompleted,
notes: notes,
dueDateTimestamp: dueDateTimestamp,),
  );
}

// renders the top section of the screen showing the user's name and three
// summary chips (urgent / soon / later) with live counts from the task list
Widget _buildHeader(int urgentCount,int soonCount, int laterCount){
return Container(
padding : const EdgeInsets.fromLTRB(18,14,18,10),
decoration:  BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5)),
),
child : Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
Row(children:[
Expanded(child: Text('${_getGreeting()}, ${widget.name}',
style:  TextStyle(fontSize:20, fontWeight: FontWeight.w500, color : _textPrimary,),)),
AppPressable(
  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
  child: Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _border, width: 0.5),
    ),
    child: const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF8888dd)),
  ),
),
]),
const SizedBox(height: 7),

Row(children:[
_buildSummaryChip('$urgentCount urgent', _urgentText, _urgentBg),
const SizedBox(width: 8),
_buildSummaryChip('$soonCount soon', _soonText, _soonBg),
const SizedBox(width:8),
// BUG FIX: was _laterCount (an int) passed as a Color — fixed to _laterText
_buildSummaryChip('$laterCount later', _laterText, _laterBg),

],),


],),


);
}

// renders a small colored pill chip used in the header summary row
// textColor and bgColor are passed in so each urgency level has its own palette
Widget _buildSummaryChip(String label, Color textColor, Color bgColor){
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20),),
    child: Text(label, style : TextStyle(fontSize:10, color: textColor)),
  );
}

// renders an uppercase grey section divider label (URGENT / UP NEXT / LATER)
// used to visually separate task groups in the scrollable list
Widget _buildSectionLabel(String label){
  return Padding(padding: const EdgeInsets.fromLTRB(18,10,18,5),
  child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: _textSecondary,
  letterSpacing: 0.5,),),);
}

// renders a centered empty state message when the task list is empty
// prompts the user to tap the + button to add their first task
Widget _buildEmptyState(){
return Center(
child:Column(
mainAxisSize : MainAxisSize.min, children : const [Text('No tasks yet', style: 
TextStyle(fontSize:13, color: Color(0xFF4a4a6a)),),
SizedBox(height: 6), Text('Tap + to add', style: TextStyle(fontSize:11, color: 
Color(0xFF4a4a6a)),),

],

),

);

}

// renders a single task card with a colored left border that reflects urgency,
// a title, a due date string (meta), a days-remaining label, and a badge pill
Widget _buildTaskCard({required String taskId, required String title, required String meta,
 required _Urgency urgency, required bool isCompleted, String? notes, int? dueDateTimestamp,}){

final borderColor = switch(urgency){
  _Urgency.urgent => const Color(0xFFd85a30),
  _Urgency.soon => const Color(0xFF5c5cd6),
  _Urgency.later => const Color(0xFF3d8fa1),
};

final cardBg = urgency == _Urgency.urgent ? const Color(0xFF231a1a) : _surface;

final badgeText = urgency == _Urgency.urgent ? const Color(0xFFd87a5a) : 
urgency == _Urgency.soon ? const Color(0xFF8888dd) : const Color(0xFF5abcd8);

final badgeBg = urgency == _Urgency.urgent ? const Color(0xFF3a1a1a) :
 urgency == _Urgency.soon ? const Color(0xFF2a2a5a) : const Color(0xFF1a3a42);

 return Container(

margin : const EdgeInsets.fromLTRB(14,0,14,6),
decoration : BoxDecoration(color: isCompleted ? const Color(0xFF1c1c2e) : cardBg, borderRadius: BorderRadius.circular(16),
border : Border.all(color: isCompleted ? const Color(0xFF2a2a3a) : _border,  width: 0.5),),

child : ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Container(padding: const EdgeInsets.all(14),decoration : BoxDecoration(
border: Border(left: BorderSide(color: isCompleted ? const Color(0xFF3a3a3a) : borderColor, width : 4)),
), child : Row(
crossAxisAlignment: CrossAxisAlignment.start, children : [
// BUG FIX: completion toggle circle — animated + haptic so completing a task
// actually *feels* like checking something off
AppPressable(
  haptic: false,
  pressedScale: 0.8,
  onTap: () {
    if (!isCompleted) {
      Haptics.success();
    } else {
      Haptics.tap();
    }
    _toggleCompletion(taskId);
  },
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
    width: 18, height: 18,
    margin: const EdgeInsets.only(right: 10, top: 1),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: isCompleted ? const Color(0xFF2a5a2a) : Colors.transparent,
      border: Border.all(
        color: isCompleted ? const Color(0xFF4a9a4a) : const Color(0xFF4a4a6a),
        width: 1.5,
      ),
    ),
    child: AnimatedScale(
      scale: isCompleted ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: const Icon(Icons.check, size: 12, color: Color(0xFF5abba0)),
    ),
  ),
),
Expanded(child: Column(
crossAxisAlignment: CrossAxisAlignment.start,  children: [Text(title, style:
TextStyle(
  fontSize:12, fontWeight: FontWeight.w500,
  color : isCompleted ? const Color(0xFF4a4a6a) : _textPrimary,
  decoration: isCompleted ? TextDecoration.lineThrough : null,
),),

const SizedBox(height: 4),

// meta is the due date string the user typed

  Text(meta, style: TextStyle(
    fontSize: 10.5,
    color : isCompleted ? const Color(0xFF3a3a5a) : _textSecondary,
  ),),
  if (notes != null && notes.trim().isNotEmpty && !isCompleted) ...[
    const SizedBox(height: 3),
    Text(
      notes.trim(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 9.5, color: isCompleted ? const Color(0xFF3a3a5a) : _textSecondary, height: 1.4),
    ),
  ],
  if (dueDateTimestamp != null && !isCompleted) ...[
    const SizedBox(height: 3),
    Text(_daysRemaining(dueDateTimestamp), style: TextStyle(
      fontSize: 9.5,
      color: _daysRemaining(dueDateTimestamp).startsWith('Overdue')
          ? const Color(0xFFd87a5a)
          : _daysRemaining(dueDateTimestamp) == 'Due today'
              ? const Color(0xFFc49040)
              : _textSecondary,
    )),
  ],

],


),),

Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical:3),
decoration: BoxDecoration(
  color: isCompleted ? const Color(0xFF1a1a2a) : badgeBg,
  borderRadius: BorderRadius.circular(10),
),
child: Text(
  urgency == _Urgency.urgent ? 'Urgent' : urgency == _Urgency.soon ? 'Soon' : 'Later',
  style: TextStyle(
    fontSize: 9.5,
    color: isCompleted ? const Color(0xFF3a3a5a) : badgeText,
  ),
),
),

],

),),

),

 );
 }

// renders the indigo floating action button pinned above the nav bar
// tapping it opens the _UploadSheet modal where the user creates a new task
 Widget _buildFab(BuildContext context){
  return FloatingActionButton(
onPressed:() async {
Haptics.tap();

final newTask = await showModalBottomSheet<Map<String, dynamic>>(
  context : context, isScrollControlled: true, backgroundColor: Colors.transparent,
  builder : (context) => _UploadSheet(role: widget.role),
);

//if a task is Returned ad it to the local list
if(newTask != null){
await _addTask(newTask);
  
}


},

backgroundColor: _accent,
foregroundColor: _textPrimary,
elevation: 6,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//the '+' icon
child: const Icon(Icons.add, size: 28),

  );

  
 }


}

// BUG FIX: broadcast tab now checks _canBroadcast — only reps + developer see it
//upload SHeet
//make broadcasr exclusive to reps(per role)


class _UploadSheet extends StatefulWidget{
  final String role;

const _UploadSheet({required this.role});

@override
// BUG FIX: was State<_UploadSheetState> — should extend the state of _UploadSheet
State<_UploadSheet> createState() => _UploadSheetState();

}

// BUG FIX: was `extends State<_UploadSheetState>` — a State must be typed to its
// owning StatefulWidget (_UploadSheet), not to itself
// BUG FIX: replaced static const with theme getters for light/dark mode support
class _UploadSheetState extends State<_UploadSheet>{
  // BUG FIX: developer same as rep — both can broadcast; respects role sim override
  bool get _canBroadcast {
    final role = DevPrefs.effectiveRole(widget.role);
    return role == 'rep' || role == 'developer';
  }

  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textMuted => Theme.of(context).colorScheme.onSurfaceVariant;

  static const _colorUrgent = Color(0xFFd85a30);
  static const _colorSoon = Color(0xFF5c5cd6);
  static const _colorLater = Color(0xFF3d8fa1);

//0 = personal, 1 = broadcacst
int _activeTab = 0;

//loading state for broadcast to prevent duplicates
// BUG FIX: was `int _isSubmitting = false` — false is a bool literal, not an int
bool _isSubmitting = false;

final _taskNameController = TextEditingController();
final _taskDueDateController = TextEditingController();
final _notesController = TextEditingController();
final _titleController = TextEditingController();
final _bodyController = TextEditingController();
final _sourceController = TextEditingController();
final _broadcastDueDateController = TextEditingController();

DateTime? _pickedDate;
String? _selectedUrgency;
// BUG FIX: broadcast due date (Phase B) — real timestamp so announcements
// carry actual timing instead of free-text "Wednesday"
DateTime? _pickedBroadcastDate;
// BUG FIX: manual override toggle — when false (default) urgency is derived
// from the picked due date; when true the chips drive the stored badge
bool _manualUrgency = false;

// BUG FIX: per-task reminder override — null means "use the Profile default",
// 0 means off for this task, otherwise a custom pre-reminder in minutes
int? _overrideMinutes;

// BUG FIX: auto urgency derived from the picked due date+time (mirrors
// _computeUrgency): due within 24h is Urgent, within 72h is Soon, else Later
String get _autoUrgency {
  final picked = _pickedDate;
  if (picked == null) return 'Later';
  final remaining = picked.difference(DateTime.now()).inHours;
  if (remaining <= 24) return 'Urgent';
  if (remaining <= 72) return 'Soon';
  return 'Later';
}
// BUG FIX: default didn't match the new audience chip options below — no chip
// would show as selected on first open. Defaulting to the first option instead.
String _selectedAudience = 'Software Engineering';
String _selectedCategory = 'Academic';

//dispose controllers after use
@override
void dispose(){
  _taskNameController.dispose();
_taskDueDateController.dispose();
_notesController.dispose();
_titleController.dispose();
_bodyController.dispose();
_sourceController.dispose();
_broadcastDueDateController.dispose();

super.dispose(); //clear out the widget state
}

@override 
Widget build(BuildContext context){
  // how tall the keyboard is
  // BUG FIX: was `MediaQuery.0f` — should be `MediaQuery.of`
final bottomInset = MediaQuery.of(context).viewInsets.bottom;

return Container(
  decoration:BoxDecoration(color : _surface, 
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),

// BUG FIX: was `botomInset` — variable declared above is `bottomInset`
padding : EdgeInsets.fromLTRB(18,16,18,24 + bottomInset),
child : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment : CrossAxisAlignment.start,
children: [
//drag tile,already handled by flutter showBottomModal
Center(child: Container(
width: 32, height: 3,
decoration : BoxDecoration(color : const Color(0xFF3a3a6a),
borderRadius : BorderRadius.circular(2),),


),),

const SizedBox(height: 16),
//title
Text('New Post', style : TextStyle(fontSize:15, fontWeight: FontWeight.w500,
color : _textPrimary),),

// BUG FIX: removed _buildTabRow() for non-broadcast users — students only see personal form
// show personal / broadcast tabs wilddget
if(_canBroadcast) ...[
  const SizedBox(height : 14),
  _buildTabRow(),
  const SizedBox(height:16),
],

// BUG FIX: was calling undefined _buildBroadcastFrom() in both branches —
// personal tab now correctly routes to _buildPersonalForm(),
// broadcast tab routes to _buildBroadcastForm()
// BUG FIX: non-broadcast roles always get personal form regardless of _activeTab
_canBroadcast
  ? (_activeTab == 0 ? _buildPersonalForm() : _buildBroadcastForm())
  : _buildPersonalForm(),

const  SizedBox(height: 16),
_buildUrgencyPicker(),
const SizedBox(height: 16),
// BUG FIX: was _buildSubmitBotton() — method is named _buildSubmitButton()
_buildSubmitButton(),


],),
);
}

Widget _buildTabRow(){
return Container(
  padding : const EdgeInsets.all(3), decoration : BoxDecoration(color: _bg,
  borderRadius: BorderRadius.circular(10),), child : Row(children :
   [_buildTab('Personal', index: 0), _buildTab('Broadcast', index : 1),],),);
}

Widget _buildTab(String label, {required int index}){
  final isActive = _activeTab == index; // activeTab is 0
  return Expanded(child: AppPressable(
  haptic: false,
  onTap:(){
  Haptics.select();
  setState((){_activeTab = index;
  //reset urgency selection when switching tabs
  _selectedUrgency = null;
  _pickedDate = null;
  _pickedBroadcastDate = null;
  _overrideMinutes = null;
  });
  },
  child:  AnimatedContainer(padding:const EdgeInsets.symmetric(vertical:7), duration: const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  decoration :
  BoxDecoration(color : isActive? const Color (0xFF3a3a7a) : Colors.transparent,
  borderRadius : BorderRadius.circular(8),),
  child: AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 180),
  style: TextStyle(fontSize: 11, color:
  isActive? _textPrimary  : _textMuted),
  child: Text(label, textAlign: TextAlign.center, maxLines: 1),
  ),
  ),
  ),);
}

// BUG FIX: this used to contain the broadcast fields (title/body/source/etc) —
// restored to the personal tab's actual two fields: task name + due date
// BUG FIX: due date now uses a date picker instead of free-text
Widget _buildPersonalForm(){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
  _buildField('Task name', _taskNameController),
  const SizedBox(height: 10),
  _buildDateField(),
  const SizedBox(height: 10),
  _buildReminderPicker(),
  const SizedBox(height: 10),
  _buildField('Notes', _notesController, hint: 'Add details (optional)', tall: true),
],);
}

// BUG FIX: per-task pre-reminder override via slider. "Default" follows the
// Profile > Settings default; 0 = off for this task; otherwise a custom
// pre-reminder in minutes (0–120, 5-min steps).
Widget _buildReminderPicker(){
final isDefault = _overrideMinutes == null;
final minutes = _overrideMinutes ?? ReminderPrefs.preReminderMinutes;
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
Row(children:[
_buildLabel('Remind me'),
const Spacer(),
AppPressable(
  haptic: false,
  onTap: () {
    Haptics.select();
    setState(() => _overrideMinutes = null);
  },
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isDefault ? const Color(0xFF2a2a5a) : _bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDefault ? _accent : const Color(0xFF3a3a6a),
        width: 0.5,
      ),
    ),
    child: Text(
      'Default (${ReminderPrefs.preReminderMinutes}min)',
      style: TextStyle(
        fontSize: 9,
        color: isDefault ? const Color(0xFFa0a0ee) : _textMuted,
      ),
    ),
  ),
),
]),
const SizedBox(height: 6),
ReminderSlider(
  minutes: minutes,
  accent: _accent,
  border: const Color(0xFF3a3a6a),
  textMuted: _textMuted,
  onChanged: (m) => setState(() => _overrideMinutes = m),
),
],);
}

// BUG FIX: new date picker field — tapping opens a system date picker dialog
// and populates the controller with a formatted date string
Widget _buildDateField(){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
_buildLabel('Due date'), const SizedBox(height: 5),
AppPressable(
  onTap: _pickDate,
  child: Container(
    decoration: BoxDecoration(color: _bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF3a3a6a), width: 0.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Expanded(child: Text(
        _taskDueDateController.text.isEmpty
          ? 'Pick a date'
          : _taskDueDateController.text,
        style: TextStyle(
          fontSize: 11,
          color: _taskDueDateController.text.isEmpty
            ? const Color(0xFF4a4a6a) : _textPrimary,
        ),
      )),
      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF4a4a6a)),
    ],),
  ),
),],);
}

Future<void> _pickDate() async {
final now = DateTime.now();
// one adaptive popup instead of two chained Material dialogs —
// Cupertino wheel sheet on iOS, themed M3 pickers on Android/Quest
final picked = await showAdaptiveDateTimePicker(
context,
initial: _pickedDate ?? now,
first: now,
title: 'Due date',
);
if(picked == null || !mounted) return;

setState(() {
_pickedDate = picked;
// BUG FIX: only auto-assign urgency from the date in auto mode;
// a manual chip choice is never overwritten by picking a date
if(!_manualUrgency){
final remaining = picked.difference(now).inHours;
if (remaining <= 24) _selectedUrgency = 'Urgent';
else if (remaining <= 72) _selectedUrgency = 'Soon';
else _selectedUrgency = 'Later';
}
_taskDueDateController.text =
DateFormat('EEE, MMM d · h:mma').format(picked).toLowerCase();
});
}

// BUG FIX: broadcast due-date picker (Phase B) — mirrors the personal date
// field but keeps its own selected timestamp
Widget _buildBroadcastDateField(){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
_buildLabel('Due date'), const SizedBox(height: 5),
AppPressable(
  onTap: _pickBroadcastDate,
  child: Container(
    decoration: BoxDecoration(color: _bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF3a3a6a), width: 0.5),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(children: [
      Expanded(child: Text(
        _broadcastDueDateController.text.isEmpty
          ? 'Pick a date'
          : _broadcastDueDateController.text,
        style: TextStyle(
          fontSize: 11,
          color: _broadcastDueDateController.text.isEmpty
            ? const Color(0xFF4a4a6a) : _textPrimary,
        ),
      )),
      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF4a4a6a)),
    ],),
  ),
),],);
}

Future<void> _pickBroadcastDate() async {
final now = DateTime.now();
final picked = await showAdaptiveDateTimePicker(
context,
initial: _pickedBroadcastDate ?? now,
first: now,
dateOnly: true,
title: 'Due date',
);
if(picked != null && mounted){
setState(() {
_pickedBroadcastDate = picked;
_broadcastDueDateController.text = DateFormat('EEE, MMM d').format(picked);
});
}
}

// BUG FIX: this is the form that was previously (and wrongly) named
// _buildPersonalForm — moved here under its correct name, with controller
// and typo fixes applied (see inline notes below)
Widget _buildBroadcastForm(){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
  _buildField('Title', _titleController, hint: 'e.g Exam hall changed'),
  const SizedBox(height:10), _buildField('Body', _bodyController,
   hint: 'Add further details...', tall: true), const SizedBox(height:10),
   //why are they both in seperate expanded wraps?
   // so each field gets half the row's width instead of one field taking it all
   Row(children:[
     // BUG FIX: was _sourceTitleController (undefined) — actual controller is _sourceController
     Expanded(child: _buildField('Source', _sourceController, hint: 'e.g Mr Musa · CS '),),
   const SizedBox(width : 8), 
   // BUG FIX: broadcast due date is now a real date picker (Phase B) instead
   // of free text, so announcements carry a true dueDateTimestamp
   Expanded(child: _buildBroadcastDateField()),
   ],),
   
   
   const SizedBox (height : 10), _buildLabel('Target audience'), const SizedBox(height: 6),
   _buildAudienceChips(),
   const SizedBox(height: 10),
   _buildLabel('Category'),
// BUG FIX: was `cons SizedBox` — missing the `t` in const
const SizedBox(height: 6),
_buildCategoryChips(),


   ],);
}

Widget _buildField(String label, TextEditingController controller, {String? hint, bool tall = false,}){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children: [
_buildLabel(label), const SizedBox(height: 5), Container(decoration: BoxDecoration(color: _bg,
borderRadius: BorderRadius.circular(8), border : Border.all(color: const Color(0xFF3a3a6a), width: 0.5),), child:
TextField(controller: controller, maxLines : tall? 3 : 1, style : TextStyle(fontSize: 11, color: _textPrimary),
decoration : InputDecoration( border : InputBorder.none, contentPadding:
 const EdgeInsets.symmetric(horizontal : 12, vertical: 9,),
hintText: hint, hintStyle: const TextStyle(fontSize: 11, color : Color(0xFF4a4a6a),),
 
 ),

),),

],);
}

Widget _buildLabel(String text){
  return Text(text, style : TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3),);
}

Widget _buildAudienceChips(){
final options = ['Software Engineering', 'Networking', 'Database', 'All dept.'];
return Wrap(spacing: 6, children: options.map((option){
final isSelected = _selectedAudience == option;

return AppPressable(
haptic: false,
onTap: () {
Haptics.select();
setState(()=> _selectedAudience = option);
},

// BUG FIX: was `const Edgeinsets.symmetric` — class name is EdgeInsets (capital I)
child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
decoration: BoxDecoration(color: isSelected ? const Color(0xFF2a2a5a) : _bg, 
borderRadius: BorderRadius.circular(20), border:
 Border.all(color: isSelected ? _accent : const Color(0xFF3a3a6a), width: 0.5),), 
 child:Text(option, style: 
 TextStyle(fontSize: 10, color: isSelected ? const Color(0xFFa0a0ee) : _textMuted),),

),);



}).toList(),);
}

Widget _buildCategoryChips(){
final options=['Academic', 'Financial'];
return Wrap(spacing: 6, children:  options.map((option){
final isSelected = option == _selectedCategory;

return AppPressable(
haptic: false,
onTap: () {
Haptics.select();
setState(() => _selectedCategory = option);
},

// BUG FIX: was `child Container(` — missing the colon after the named parameter `child`
child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10 ),
decoration: BoxDecoration(color: isSelected ? const Color(0xFF2a2a5a) : _bg,
borderRadius: BorderRadius.circular(20), border: Border.all(
  color: isSelected ? _accent : const Color(0xFF3a3a6a), width: 0.6),
),
// BUG FIX: was `_option` (undefined, leading underscore) — loop variable is `option`
child: Text(option, style: TextStyle(fontSize: 10,
 color: isSelected ? const Color(0xFFa0a0ee) : _textPrimary,),),

),
);}).toList(),);}

Widget _buildUrgencyPicker(){
return Column(crossAxisAlignment: CrossAxisAlignment.start, children:
 [Row(children:[
   _buildLabel('Urgency'),
   const Spacer(),
   const Text('Auto', style: TextStyle(fontSize: 10, color: Color(0xFF4a4a6a))),
   Switch(
     value: _manualUrgency,
     onChanged: (v) => setState(() => _manualUrgency = v),
     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
   ),
   const Text('Manual', style: TextStyle(fontSize: 10, color: Color(0xFF4a4a6a))),
 ]),
const SizedBox(height: 6), Row(children:[
    //label, border color, bg color
 _buildUrgencyChip('Urgent', _colorUrgent, const Color(0xFF2a1a1a)),
 const SizedBox(width: 6),
 _buildUrgencyChip('Soon', _colorSoon, const Color(0xFF1e1e3a)),
 const SizedBox(width: 6),
 _buildUrgencyChip('Later',_colorLater, const Color(0xFF0e2a30)),
 ],
 
 ),],);

}

// BUG FIX: was `_buildUrgencychip` (lowercase c) — calls above expect _buildUrgencyChip
Widget _buildUrgencyChip(String label, Color borderColor, Color bgColor){
final isSelected = _selectedUrgency == label;

return AppPressable(
haptic: false,
onTap: (){
  Haptics.select();
  setState((){
  // BUG FIX: tapping a chip in auto mode switches to manual override so the
  // chosen urgency is actually respected instead of being auto-assigned later
  _manualUrgency = true;
  _selectedUrgency = label;
  });
},
child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  padding: const EdgeInsets.symmetric(vertical: 5, horizontal:12),
//bgColor gets passed in
decoration: BoxDecoration(color: isSelected ? bgColor : _bg,
 // BUG FIX: was `BorderRadius.circlar` — should be `circular`
 borderRadius: BorderRadius.circular(20), border: Border.all(
  color: isSelected ? borderColor : const Color(0xFF3a3a6a),width: 0.5 ),),

  
  child: Text( label, style: TextStyle(fontSize: 10, color: isSelected ? borderColor : _textMuted),),
),


);
}

Widget _buildSubmitButton(){

final isPersonal = _activeTab == 0;

return AppPressable(
haptic: false,
onTap: _isSubmitting ? null : () {
  Haptics.tap();
  _handleSubmit();
},
child : AnimatedContainer (
  duration: const Duration(milliseconds: 180),
  alignment: Alignment.center,
width : double.infinity, padding: const EdgeInsets.symmetric(vertical: 11),
decoration: BoxDecoration(
//dim when submitting
color : _isSubmitting ? const Color(0xFF2a2a5a) : _accent,
borderRadius: BorderRadius.circular(10),
),

child : _isSubmitting
  ? const SizedBox(
      width: 14, height: 14,
      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFe8e8f4)),
    )
  : Text(isPersonal ? 'Add Task' : 'Broadcast',
textAlign : TextAlign.center, style: TextStyle(fontSize:12, fontWeight : FontWeight.w500,
color : _textPrimary,),
),
),
);
}

Future <void> _handleSubmit()async{
//validate  both tabs  first
//activeTab 0 is personal, 1 is Broadcast

if(_activeTab  == 0){
if(_taskNameController.text.trim().isEmpty){
_showToast('Task name field can not be empty', isError: true);
return;
}
if(_taskNameController.text.trim().length > 200){
_showToast('Task name is too long (max 200 chars)', isError: true);
return;
}
  } else{
if(!_canBroadcast){
  _showToast('Only reps can broadcast announcements', isError: true);
  return;
}
if(_titleController.text.trim().isEmpty){
  _showToast('Title field can not be empty', isError: true);
  return;
}
if(_titleController.text.trim().length > 200){
  _showToast('Title is too long (max 200 chars)', isError: true);
  return;
}
if(_bodyController.text.trim().length > 2000){
  _showToast('Body is too long (max 2000 chars)', isError: true);
  return;
}
if(_sourceController.text.trim().length > 100){
  _showToast('Source is too long (max 100 chars)', isError: true);
  return;
}
  }

 // BUG FIX: a chip is only required when overriding manually — in auto mode
 // the urgency comes from the picked due date (defaults to 'Later' if none)
 if(_manualUrgency && _selectedUrgency == null){
_showToast('Pick an urgency level in Manual mode', isError: true);
return;
 }

//resolve the effective urgency based on the mode
 final effectiveUrgency = _manualUrgency ? (_selectedUrgency ?? 'Later') : _autoUrgency;

//submit handler
 if(_activeTab == 0){

//build task map thatll be stored  and returned  to home screen
  final newTask = {
'id'  : DateTime.now().millisecondsSinceEpoch.toString(),
'taskName' : _taskNameController.text.trim(),
'notes' : _notesController.text.trim(),
'dueDate' : _taskDueDateController.text.trim(),
'dueDateTimestamp' : _pickedDate?.millisecondsSinceEpoch,
'urgency':  effectiveUrgency,
// BUG FIX: store the override mode so the home screen keeps manual choices
'urgencyManual':  _manualUrgency,
'category' :  'Personal',
// BUG FIX: track completion state so tasks can be toggled done
'isCompleted' : false,
// BUG FIX: per-task pre-reminder override (null = use Profile default)
'preReminderMinutes': _overrideMinutes,
  };

  _showToast('Task added');

  //dismiss keyboard
  FocusScope.of(context).unfocus();

//send the task map back to the FAB, homescreen uses it to call _addTask
  if(mounted) Navigator.pop(context, newTask);
 }


//broadcast tab
 else{
// BUG FIX: safety check — block broadcast if role doesnt have permission
if (!_canBroadcast) {
  _showToast('Only reps can broadcast announcements', isError: true);
  return;
}

final user = FirebaseAuth.instance.currentUser;
if(user == null){
  _showToast('Error: user not logged in', isError: true);
  return;
}

//temproarily disable button
// before the network call starts so the button
//disables and shows 'Sending' for the entire duration of the write
setState(() => _isSubmitting = true);

//dismiss keyboard
FocusScope.of(context).unfocus();

try{
await FirebaseFirestore.instance.collection('broadcast').add({

  'title': _titleController.text.trim(),
  'body' : _bodyController.text.trim(),
  'source': _sourceController.text.trim(),
  'dueDate' : _broadcastDueDateController.text.trim(),
  // BUG FIX: real timestamp so broadcast pushes/carousels know the actual due time
  'dueDateTimestamp' : _pickedBroadcastDate?.millisecondsSinceEpoch,
  'audience' : _selectedAudience,
  'category' : _selectedCategory,
  'urgency' : effectiveUrgency,
  'uid' : user.uid,


   // FieldValue.serverTimestamp() to write the server's current time
   'createdAt' : FieldValue.serverTimestamp(),

});

_showToast('Task update broadcasted!');

//pop sheet after success
if(mounted) Navigator.pop(context);

}catch(e){
  _showToast('Failed to send broadcast', isError: true);

  if(mounted) setState(()=> _isSubmitting = false);
}

 }
}

void  _showToast(String text, {bool isError = false}){
  AppToast.show(context, text, isError: isError);
}
 


}