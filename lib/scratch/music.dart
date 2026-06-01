import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Then replace the _buildSubmitButton method with this
Widget _buildSubmitButton() {
  final isPersonal = _activeTab == 0;
  return GestureDetector(
    onTap: _handleSubmit,
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


// Then add the _handleSubmit method and a _showToast helper below _buildSubmitButton:\

Future<void> _handleSubmit() async {
  // grab the currently logged in user
  final user = FirebaseAuth.instance.currentUser;

  // if somehow no user is logged in, bail out
  if (user == null) {
    _showToast('Not logged in', isError: true);
    return;
  }

  try {
    if (_activeTab == 0) {
      // personal tab — validate then write to personal collection

      if (_taskNameController.text.trim().isEmpty) {
        _showToast('Please enter a task name', isError: true);
        return;
      }

      if (_selectedUrgency == null) {
        _showToast('Please select an urgency level', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('personal').add({
        'taskName': _taskNameController.text.trim(),
        'dueDate': _taskDueDateController.text.trim(),
        'urgency': _selectedUrgency,
        'category': 'Personal',
        'uid': user.uid,
        // server timestamp — Firestore stamps the exact time the doc was created
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showToast('Task added');

    } else {
      // broadcast tab — validate then write to broadcast collection

      if (_titleController.text.trim().isEmpty) {
        _showToast('Please enter a title', isError: true);
        return;
      }

      if (_selectedUrgency == null) {
        _showToast('Please select an urgency level', isError: true);
        return;
      }

      await FirebaseFirestore.instance.collection('broadcast').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'source': _sourceController.text.trim(),
        'dueDate': _broadcastDueDateController.text.trim(),
        'audience': _selectedAudience,
        'category': _selectedCategory,
        'urgency': _selectedUrgency,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showToast('Broadcast sent');
    }

    // close the sheet after a successful write
    if (mounted) Navigator.pop(context);

  } catch (e) {
    _showToast('Something went wrong', isError: true);
  }
}

void _showToast(String msg, {bool isError = false}) {
  Fluttertoast.showToast(
    msg: msg,
    backgroundColor: isError ? const Color(0xFF8a3a3a) : const Color(0xFF4a4aaa),
    textColor: const Color(0xFFe8e8f4),
    toastLength: Toast.LENGTH_LONG,
  );
}