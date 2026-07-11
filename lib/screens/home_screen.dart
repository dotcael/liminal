// John 3:16-17
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum _Urgency {urgent, soon , later}

class HomeScreen extends StatefulWidget{

final String name;
final String role;

const HomeScreen({super.key, required this.name, required this.role});

@override 
State<HomeScreen> createState()=> _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
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

  //load tasks from local storage
  List<Map<String, dynamic>> _tasks= [];

  //loader
  bool _isLoading = true;

  //key used to store and retrieve task list 
  static const _storageKey = 'personal_tasks';

  @override
  void initState(){
super.initState(); //call superclass initState

_loadTasks();
  }

  Future<void> _loadTasks() async{
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_storageKey);
if(raw != null){

final decoded = jsonDecode(raw) as List<dynamic>;
setState((){
_tasks = decoded.cast<Map<String,dynamic>>();

});


}
 setState(() => _isLoading = false);
  }

  Future<void> _saveTasks() async{
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_storageKey, jsonEncode(_tasks));
  }

//convert urgency string n local storge to enum

_Urgency _parseUrgency (String? value){
switch (value){
  case 'Urgent' : return _Urgency.urgent;
  case 'Soon' : return _Urgency.soon;
  default : return _Urgency.later;
}

}

//deletion. takss gets removed (using its id) and redrawn first, 
// then _saveTasks updates the local storage in the background
Future<void> _deleteTask(String id) async{

setState((){
_tasks.removeWhere((task) => task['id'] == id);

});
await _saveTasks();

}

//called by upload sheet
Future<void> _addTask(Map<String,dynamic> task) async{
  setState((){

//insert at index 0 so its the first
_tasks.insert(0,task);
 });

 await _saveTasks(); //to save it so it stays when the app is restarted
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

// renders the header + scrollable task list grouped by urgency 
// counts tasks per urgency bucket first for the summary chips and section labels stay accurate
Widget _buildContent(){
//loops through tasks  to count urgency fields tobuid the summary chips

int urgentCount = 0;
int soonCount = 0;
int laterCount = 0;

for (final task in _tasks){
final urgency = _parseUrgency(task['urgency'] as String?);
if(urgency == _Urgency.urgent) urgentCount++;
else if (urgency == _Urgency.soon) soonCount++;
else laterCount++;
}

return Column(
  children: [_buildHeader(urgentCount, soonCount, laterCount),

  Expanded(child: _tasks.isEmpty ? _buildEmptyState() : SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [ 
 // each section only renders if it has tasks
// if urgentCount is 0 the entire urgent block is skipped
                      if (urgentCount > 0) ...[
_buildSectionLabel('Urgent'), ..._tasks.where((task)=> _parseUrgency(task['urgency']
as String?) == _Urgency.urgent).map((task) => _buildDismissibleCard(taskId: task['id'] as String,
title: task['taskName'] as String? ?? '', meta: task['dueDate'] as String? ?? '', urgency: _Urgency.urgent,)),

                      ],
                      if (soonCount > 0) ...[
                        _buildSectionLabel('Up next'),
                        ..._tasks.where((task)=> _parseUrgency(task['urgency'] as String?) == _Urgency.soon).map((task)
                        => _buildDismissibleCard(
                          taskId: task['id'] as String,
                        title: task['taskName'] as String? ??'',
                        meta: task['dueDate'] as String? ??'',
                        urgency: _Urgency.soon,
                        )),
                      ],

                      if(laterCount > 0) ...[
                        _buildSectionLabel('Later'), ..._tasks.where((task)=>
                         _parseUrgency(task['urgency'] as String?) == _Urgency.later).map((task) => _buildDismissibleCard(
                          taskId: task['id'] as String,
                          title: task['taskName'] as String? ??'',
                          meta: task['dueDate'] as String? ?? '',
                          urgency: _Urgency.later,

                         )),
                      ],
                      const SizedBox(height: 80),

],

),

  ), ),
],);


}

// renders a swipeable wrapper around a task card — swiping left reveals a red
// delete background with a bin icon, then removes the task from the list and local storage

Widget _buildDismissibleCard({required String taskId, required String title, 
required String meta, required _Urgency urgency,}) {
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

//called when user lifts finget after swipe.true confirms deletion, false snaps the card back
confirmDismiss: (direction) async{
await _deleteTask(taskId); //delete locally
return true;
},

//for further actions like undo
// BUG FIX: was `onDismissed(direction){}` — that's a method definition, not a named parameter
// named parameters use a colon, not parens: onDismissed: (direction) {}
onDismissed: (direction) {},

child: _buildTaskCard(title: title, meta : meta, urgency: urgency,),
  );
}

// renders the top section of the screen showing the user's name and three
// summary chips (urgent / soon / later) with live counts from the task list
Widget _buildHeader(int urgentCount,int soonCount, int laterCount){
return Container(
padding : const EdgeInsets.fromLTRB(18,14,18,10),
decoration:  const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.5)),
),
child : Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
Text('Greetings, ${widget.name}',
style:  const TextStyle(fontSize:20, fontWeight: FontWeight.w500, color : _textPrimary,),),
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
  child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: _textSecondary,
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
// a title, a due date string (meta), and a badge pill showing the urgency level
Widget _buildTaskCard({required String title, required String meta,
 required _Urgency urgency}){

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
decoration : BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16),
border : Border.all(color: _border,  width: 0.5),),

child : ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Container(padding: const EdgeInsets.all(14),decoration : BoxDecoration(
border: Border(left: BorderSide(color: borderColor, width : 4)),
), child : Row(
crossAxisAlignment: CrossAxisAlignment.start, children : [
Expanded(child: Column(
crossAxisAlignment: CrossAxisAlignment.start,  children: [Text(title, style:
const TextStyle(fontSize:12, fontWeight: FontWeight.w500, color : _textPrimary,),),

const SizedBox(height: 4),

  // meta is the due date string the user typed

  Text(meta, style: const TextStyle(fontSize:10.5, color : _textSecondary,),),


],


),),

Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical:3),
decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(10),),
child: Text(urgency == _Urgency.urgent ? 'Urgent' : urgency == _Urgency.soon ?
 'Soon' : 'Later', style: TextStyle(fontSize: 9.5, color : badgeText),),
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

final newTask = await showModalBottomSheet<Map<String, dynamic>>(
  context : context, isScrollControlled: true, backgroundColor: Colors.transparent,
  builder : (context) => const _UploadSheet(),
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

//upload SHeet
//make broadcasr exclusive to reps(per role)


class _UploadSheet extends StatefulWidget{
const _UploadSheet();

@override
// BUG FIX: was State<_UploadSheetState> — should extend the state of _UploadSheet
State<_UploadSheet> createState() => _UploadSheetState();

}

// BUG FIX: was `extends State<_UploadSheetState>` — a State must be typed to its
// owning StatefulWidget (_UploadSheet), not to itself
class _UploadSheetState extends State<_UploadSheet>{

 static const _bg = Color(0xFF1a1a2e);
  static const _surface = Color(0xFF22223a);
  static const _border = Color(0xFF2d2d4a);
  static const _accent = Color(0xFF4a4aaa);
  static const _textPrimary = Color(0xFFe8e8f4);
  static const _textMuted = Color(0xFF6b6b9a);

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
final _titleController = TextEditingController();
final _bodyController = TextEditingController();
final _sourceController = TextEditingController();
final _broadcastDueDateController = TextEditingController();

String? _selectedUrgency;
// BUG FIX: default didn't match the new audience chip options below — no chip
// would show as selected on first open. Defaulting to the first option instead.
String _selectedAudience = 'Software Engineering';
String _selectedCategory = 'Academic';

//dispose controllers after use
@override
void dispose(){
  _taskNameController.dispose();
_taskDueDateController.dispose();
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
  decoration:const BoxDecoration(color : _surface, 
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
const Text('New Post', style : TextStyle(fontSize:15, fontWeight: FontWeight.w500,
color : _textPrimary),),

const SizedBox(height : 14),
_buildTabRow(), // show personal / broadcast tabs wilddget
const SizedBox(height:16),

// BUG FIX: was calling undefined _buildBroadcastFrom() in both branches —
// personal tab now correctly routes to _buildPersonalForm(),
// broadcast tab routes to _buildBroadcastForm()
_activeTab == 0 ? _buildPersonalForm() : _buildBroadcastForm(),

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
  return Expanded(child: GestureDetector(onTap:() => setState((){_activeTab = index;
  //reset urgency selection when switching tabs
  _selectedUrgency = null;
  
  }), child:  Container(padding:const EdgeInsets.symmetric(vertical:7), decoration : 
  BoxDecoration(color : isActive? const Color (0xFF3a3a7a) : Colors.transparent,
  borderRadius : BorderRadius.circular(8),),
  child: Text(label, textAlign: TextAlign.center, style : TextStyle(fontSize: 11, color: 
  isActive? _textPrimary  : _textMuted,),),),),);
}

// BUG FIX: this used to contain the broadcast fields (title/body/source/etc) —
// restored to the personal tab's actual two fields: task name + due date
Widget _buildPersonalForm(){
return Column(crossAxisAlignment : CrossAxisAlignment.start, children : [
  _buildField('Task name', _taskNameController),
  const SizedBox(height: 10),
  _buildField('Due date', _taskDueDateController, hint: 'e.g. Friday, Dec 20'),
],);
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
   // BUG FIX: was _broadcastdueDateController (lowercase d) — actual controller is _broadcastDueDateController
   Expanded(child: _buildField('Due date', _broadcastDueDateController, hint: 'e.g Wednesday'),
   ),],),
   
   
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
TextField(controller: controller, maxLines : tall? 3 : 1, style : const TextStyle(fontSize: 11, color: _textPrimary),
decoration : InputDecoration( border : InputBorder.none, contentPadding:
 const EdgeInsets.symmetric(horizontal : 12, vertical: 9,),
hintText: hint, hintStyle: const TextStyle(fontSize: 11, color : Color(0xFF4a4a6a),),
 
 ),

),),

],);
}

Widget _buildLabel(String text){
  return Text(text, style : const TextStyle(fontSize: 10, color: _textMuted, letterSpacing: 0.3),);
}

Widget _buildAudienceChips(){
final options = ['Software Engineering', 'Networking', 'Database', 'All dept.'];
return Wrap(spacing: 6, children: options.map((option){
final isSelected = _selectedAudience == option;

return GestureDetector(onTap: () => setState(()=> _selectedAudience = option),

// BUG FIX: was `const Edgeinsets.symmetric` — class name is EdgeInsets (capital I)
child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

return GestureDetector(onTap:() => setState(() => _selectedCategory = option),

// BUG FIX: was `child Container(` — missing the colon after the named parameter `child`
child: Container( padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10 ),
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
 [_buildLabel('Urgency'),
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

return GestureDetector(

onTap: ()=> setState(()=> _selectedUrgency = label),
child: Container(padding: const EdgeInsets.symmetric(vertical: 5, horizontal:12),
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

return GestureDetector(

onTap: _isSubmitting ? null : _handleSubmit,
child : Container (
width : double.infinity, padding: const EdgeInsets.symmetric(vertical: 11),
decoration: BoxDecoration(
//dim when submitting
color : _isSubmitting ? const Color(0xFF2a2a5a) : _accent, 
borderRadius: BorderRadius.circular(10),
),

child : Text(_isSubmitting ? 'Sending' : isPersonal ? 'Add Task' : 'Broadcast',
textAlign : TextAlign.center, style: const TextStyle(fontSize:12, fontWeight : FontWeight.w500,
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
  } else{
if(_titleController.text.trim().isEmpty){
  _showToast('Title field can not be empty', isError: true);
  return;
}
  }

 if(_selectedUrgency == null){
_showToast('Urgency level must be selected', isError: true);
return;
 }

//submit handler
 if(_activeTab == 0){

//build task map thatll be stored  and returned  to home screen
  final newTask = {
'id'  : DateTime.now().millisecondsSinceEpoch.toString(),
'taskName' : _taskNameController.text.trim(),
'dueDate' : _taskDueDateController.text.trim(),
'urgency':  _selectedUrgency,
'category' :  'Personal',
  };

  _showToast('Task added');

  //dismiss keyboard
  FocusScope.of(context).unfocus();

//send the task map back to the FAB, homescreen uses it to call _addTask
  if(mounted) Navigator.pop(context, newTask);
 }


//broadcast tab
 else{
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
  'audience' : _selectedAudience,
  'category' : _selectedCategory,
  'urgency' : _selectedUrgency,
  'uid' : user.uid,


   // FieldValue.serverTimestamp() to write the server's current time
   'createdAt' : FieldValue.serverTimestamp(),

});

_showToast('Task update broadcasted!');

//pop sheet after success
if(mounted) Navigator.pop(context);

}catch(e){
  _showToast('Error: $e', isError: true);

  if(mounted) setState(()=> _isSubmitting = false);
}

 }
}

void  _showToast(String text, {bool isError = false}){

Fluttertoast.showToast(
  msg: text, backgroundColor: isError ?
   const Color(0xFF4a4aaa) : const Color(0xFFe8e8f4),

    toastLength : Toast.LENGTH_LONG
);


}
 


}