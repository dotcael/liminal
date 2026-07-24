import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirestoreExplorer extends StatefulWidget {
  const FirestoreExplorer({super.key});

  @override
  State<FirestoreExplorer> createState() => _FirestoreExplorerState();
}

class _FirestoreExplorerState extends State<FirestoreExplorer> {
  String? _selectedCollection;
  String? _selectedDocId;
  Map<String, dynamic>? _selectedDocData;

  static const _collections = ['users', 'broadcast'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF2d2d4a), width: 0.5))),
            child: Row(
              children: [
                const Icon(Icons.storage, size: 16, color: Color(0xFF7b7bcc)),
                const SizedBox(width: 8),
                const Text('Firestore Explorer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFe8e8f4))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 18, color: Color(0xFF6b6b9a)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                VerticalDivider(width: 1, color: const Color(0xFF2d2d4a)),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 120,
      color: const Color(0xFF16162a),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 6),
        children: _collections.map((name) {
          final isSelected = _selectedCollection == name;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCollection = name;
              _selectedDocId = null;
              _selectedDocData = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              color: isSelected ? const Color(0xFF2a2a5a) : Colors.transparent,
              child: Row(
                children: [
                  Icon(
                    name == 'users' ? Icons.people : Icons.campaign,
                    size: 14,
                    color: isSelected ? const Color(0xFFa0a0ee) : const Color(0xFF4a4a6a),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? const Color(0xFFe8e8f4) : const Color(0xFF6b6b9a),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedCollection == null) {
      return const Center(child: Text('Select a collection', style: TextStyle(fontSize: 11, color: Color(0xFF4a4a6a))));
    }

    if (_selectedDocData != null) {
      return _buildDocViewer();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(_selectedCollection!).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF4a4aaa)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 10, color: Color(0xFFd87a5a))));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No documents', style: TextStyle(fontSize: 11, color: Color(0xFF4a4a6a))));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final isSelected = _selectedDocId == doc.id;

            final title = data['name'] as String? ?? data['title'] as String? ?? doc.id;
            final subtitle = data['email'] as String? ?? data['source'] as String? ?? '';

            return GestureDetector(
              onTap: () => setState(() {
                _selectedDocId = doc.id;
                _selectedDocData = data;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isSelected ? const Color(0xFF2a2a5a) : Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isSelected ? const Color(0xFFe8e8f4) : const Color(0xFFc8c8e0)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF6b6b9a)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    Text(doc.id, style: const TextStyle(fontSize: 8, color: Color(0xFF4a4a6a), fontFamily: 'monospace')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocViewer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF2d2d4a), width: 0.5))),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  _selectedDocId = null;
                  _selectedDocData = null;
                }),
                child: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF7b7bcc)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedDocId ?? '',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6b6b9a), fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildFieldTree(_selectedDocData ?? {}, ''),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTree(Map<String, dynamic> data, String prefix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final value = entry.value;
        final keyPath = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';

        if (value is Map<String, dynamic>) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKeyValue(keyPath, '{${value.length} fields}', const Color(0xFFc49040)),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildFieldTree(value, keyPath),
              ),
            ],
          );
        }

        Color valueColor;
        String displayValue;

        if (value is Timestamp) {
          displayValue = value.toDate().toIso8601String();
          valueColor = const Color(0xFF5abba0);
        } else if (value is String) {
          displayValue = '"$value"';
          valueColor = const Color(0xFF5abcd8);
        } else if (value is num) {
          displayValue = value.toString();
          valueColor = const Color(0xFFd87a5a);
        } else if (value is bool) {
          displayValue = value.toString();
          valueColor = const Color(0xFF8888dd);
        } else if (value == null) {
          displayValue = 'null';
          valueColor = const Color(0xFF4a4a6a);
        } else {
          displayValue = value.toString();
          valueColor = const Color(0xFF6b6b9a);
        }

        return _buildKeyValue(keyPath, displayValue, valueColor);
      }).toList(),
    );
  }

  Widget _buildKeyValue(String key, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10, fontFamily: 'monospace', height: 1.5),
          children: [
            TextSpan(text: '$key: ', style: const TextStyle(color: Color(0xFF6b6b9a))),
            TextSpan(text: value, style: TextStyle(color: valueColor)),
          ],
        ),
      ),
    );
  }
}
