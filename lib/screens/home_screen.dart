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

enum _ViewFilter { all, today, scheduled }

class HomeScreen extends StatefulWidget{

final String name;
final String role;

const HomeScreen({super.key, required this.name, required this.role});

@override 
State<HomeScreen> createState()=> _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _surface => Theme.of(context).colorScheme.surfaceContainerHighest;
  Color get _border => Theme.of(context).dividerColor;
  Color get _accent => Theme.of(context).colorScheme.primary;
  Color get _textPrimary => Theme.of(context).colorScheme.onSurface;
  Color get _textSecondary => Theme.of(context).colorScheme.onSurfaceVariant;

  static const _urgentText = Color(0xFFd87a5a);
  Color get _urgentBg => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2a1a1a) : const Color(0xFFfce8e0);
  static const _soonText = Color(0xFFc49040);
  Color get _soonBg => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2a2010) : const Color(0xFFfff3d6);
  static const _laterText = Color(0xFF5abcd8);
  Color get _laterBg => Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF1a3a42) : const Color(0xFFe0f2f5);

  List<Map<String, dynamic>> _tasks= [];

  _ViewFilter _viewFilter = _ViewFilter.all;

  bool _isLoading = true;

  static const _storageKey = 'personal_tasks';

  @override
  void initState(){
super.initState();

_loadTasks();
  }

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
  if (task['urgencyManual'] != true) {
    task['urgency'] = _urgencyString(_computeUrgency(task['dueDateTimestamp'] as int?));
  }
}

});

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

_Urgency _parseUrgency (String? value){
switch (value?.trim().toLowerCase()){
  case 'urgent' : return _Urgency.urgent;
  case 'soon' : return _Urgency.soon;
  default : return _Urgency.later;
}

}

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
    await _scheduleReminders(_tasks.firstWhere((t) => t['id'] == id));
  }
}

Future<void> _addTask(Map<String,dynamic> task) async{
  if (task['urgencyManual'] != true) {
    final timestamp = task['dueDateTimestamp'] as int?;
    task['urgency'] = _urgencyString(_computeUrgency(timestamp));
  }

  setState((){

_tasks.insert(0,task);
 });

 await _saveTasks();
 await _scheduleReminders(task);
}

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

return Scaffold(
  backgroundColor: _bg,
  body: SafeArea(
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

Widget _buildContent(){

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
    return true;
  }).toList();
}

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

Widget _buildDismissibleCard({required String taskId, required String title, 
required String meta, required _Urgency urgency, required bool isCompleted, String? notes, int? dueDateTimestamp,}) {
  return Dismissible(

key: Key(taskId),

direction: DismissDirection.endToStart,

background: Container(

margin: const EdgeInsets.fromLTRB(14,0,14,6),
decoration: BoxDecoration(color: const Color(0xFF8a1a1a), borderRadius: BorderRadius.circular(16)),
alignment: Alignment.centerRight,
padding:const EdgeInsets.only(right:20),
child: const Icon(Icons.delete_outline,color: Color(0xFFe8e8f4), size: 20),

),

confirmDismiss: (direction) async{
  Haptics.warning();
  return true;
},

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
_buildSummaryChip('$laterCount later', _laterText, _laterBg),

],),

],),

);
}

Widget _buildSummaryChip(String label, Color textColor, Color bgColor){
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20),),
    child: Text(label, style : TextStyle(fontSize:10, color: textColor)),
  );
}

Widget _buildSectionLabel(String label){
  return Padding(padding: const EdgeInsets.fromLTRB(18,10,18,5),
  child: Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: _textSecondary,
  letterSpacing: 0.5,),),);
}

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
child: const Icon(Icons.add, size: 28),

  );

  
 }

}

class _UploadSheet extends StatefulWidget{
  final String role;

const _UploadSheet({required this.role});

@override
State<_UploadSheet> createState() => _UploadSheetState();

}

class _UploadSheetState extends State<_UploadSheet>{
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

int _activeTab = 0;

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
DateTime? _pickedBroadcastDate;
bool _manualUrgency = false;

int? _overrideMinutes;

String get _autoUrgency {
  final picked = _pickedDate;
  if (picked == null) return 'Later';
  final remaining = picked.difference(DateTime.now()).inHours;
  if (remaining <= 24) return 'Urgent';
  if (remaining <= 72) return 'Soon';
  return 'Later';
}
String _selectedAudience = 'Software Engineering';
String _selectedCategory = 'Academic';

@override
void dispose(){
  _taskNameController.dispose();
_taskDueDateController.dispose();
_notesController.dispose();
_titleController.dispose();
_bodyController.dispose();
_sourceController.dispose();
_broadcastDueDateController.dispose();

super.dispose();
}

@override 
Widget build(BuildContext context){
final bottomInset = MediaQuery.of(context).viewInsets.bottom;

return Container(
  decoration:BoxDecoration(color : _surface, 
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),),

padding : EdgeInsets.fromLTRB(18,16,18,24 + bottomInset),
child : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment : CrossAxisAlignment.start,
children: [
Center(child: Container(
width: 32, height: 3,
decoration : BoxDecoration(color : const Color(0xFF3a3a6a),
borderRadius : BorderRadius.circular(2),),

),),

const SizedBox(height: 16),
Text('New Post', style : TextStyle(fontSize:15, fontWeight: FontWeight.w500,
color : _textPrimary),),

if(_canBroadcast) ...[
  const SizedBox(height : 14),
  _buildTabRow(),
  const SizedBox(height:16),
],

_canBroadcast
  ? (_activeTab == 0 ? _buildPersonalForm() : _buildBroadcastForm())
  : _buildPersonalForm(),

const  SizedBox(height: 16),
_buildUrgencyPicker(),
const SizedBox(height: 16),
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
  final isActive = _activeTab == index;
  return Expanded(child: AppPressable(
  haptic: false,
  onTap:(){
  Haptics.select();
  setState((){_activeTab = index;
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
final picked = await showAdaptiveDateTimePicker(
context,
initial: _pickedDate ?? now,
first: now,
title: 'Due date',
);
if(picked == null || !mounted) return;

setState(() {
_pickedDate = picked;
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

Widget _buildBroadcastForm(){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
  _buildField('Title', _titleController, hint: 'e.g Exam hall changed'),
  const SizedBox(height:10), _buildField('Body', _bodyController,
   hint: 'Add further details...', tall: true), const SizedBox(height:10),
   Row(children:[
     Expanded(child: _buildField('Source', _sourceController, hint: 'e.g Mr Musa · CS '),),
   const SizedBox(width : 8), 
   Expanded(child: _buildBroadcastDateField()),
   ],),
   
   
   const SizedBox (height : 10), _buildLabel('Target audience'), const SizedBox(height: 6),
   _buildAudienceChips(),
   const SizedBox(height: 10),
   _buildLabel('Category'),
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

child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10 ),
decoration: BoxDecoration(color: isSelected ? const Color(0xFF2a2a5a) : _bg,
borderRadius: BorderRadius.circular(20), border: Border.all(
  color: isSelected ? _accent : const Color(0xFF3a3a6a), width: 0.6),
),
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
 _buildUrgencyChip('Urgent', _colorUrgent, const Color(0xFF2a1a1a)),
 const SizedBox(width: 6),
 _buildUrgencyChip('Soon', _colorSoon, const Color(0xFF1e1e3a)),
 const SizedBox(width: 6),
 _buildUrgencyChip('Later',_colorLater, const Color(0xFF0e2a30)),
 ],
 
 ),],);

}

Widget _buildUrgencyChip(String label, Color borderColor, Color bgColor){
final isSelected = _selectedUrgency == label;

return AppPressable(
haptic: false,
onTap: (){
  Haptics.select();
  setState((){
  _manualUrgency = true;
  _selectedUrgency = label;
  });
},
child: AnimatedContainer(
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeOut,
  padding: const EdgeInsets.symmetric(vertical: 5, horizontal:12),
decoration: BoxDecoration(color: isSelected ? bgColor : _bg,
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

 if(_manualUrgency && _selectedUrgency == null){
_showToast('Pick an urgency level in Manual mode', isError: true);
return;
 }

 final effectiveUrgency = _manualUrgency ? (_selectedUrgency ?? 'Later') : _autoUrgency;

 if(_activeTab == 0){

  final newTask = {
'id'  : DateTime.now().millisecondsSinceEpoch.toString(),
'taskName' : _taskNameController.text.trim(),
'notes' : _notesController.text.trim(),
'dueDate' : _taskDueDateController.text.trim(),
'dueDateTimestamp' : _pickedDate?.millisecondsSinceEpoch,
'urgency':  effectiveUrgency,
'urgencyManual':  _manualUrgency,
'category' :  'Personal',
'isCompleted' : false,
'preReminderMinutes': _overrideMinutes,
  };

  _showToast('Task added');

  FocusScope.of(context).unfocus();

  if(mounted) Navigator.pop(context, newTask);
 }

 else{
if (!_canBroadcast) {
  _showToast('Only reps can broadcast announcements', isError: true);
  return;
}

final user = FirebaseAuth.instance.currentUser;
if(user == null){
  _showToast('Error: user not logged in', isError: true);
  return;
}

setState(() => _isSubmitting = true);

FocusScope.of(context).unfocus();

try{
await FirebaseFirestore.instance.collection('broadcast').add({

  'title': _titleController.text.trim(),
  'body' : _bodyController.text.trim(),
  'source': _sourceController.text.trim(),
  'dueDate' : _broadcastDueDateController.text.trim(),
  'dueDateTimestamp' : _pickedBroadcastDate?.millisecondsSinceEpoch,
  'audience' : _selectedAudience,
  'category' : _selectedCategory,
  'urgency' : effectiveUrgency,
  'uid' : user.uid,

   'createdAt' : FieldValue.serverTimestamp(),

});

_showToast('Task update broadcasted!');

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
