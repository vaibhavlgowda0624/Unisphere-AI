import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../notes/notes_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final busy = <String>{};

  Future<void> decide(String kind, String id, bool approve) async {
    setState(() => busy.add(id));
    try {
      final action = approve ? 'approve' : 'reject';
      await ApiClient().post('/api/admin/$kind/$id/$action');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(approve ? 'Approved' : 'Rejected')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not review: $error')));
      }
    } finally {
      if (mounted) setState(() => busy.remove(id));
    }
  }

  Widget queue(
    String collection,
    String kind,
    String title,
    String Function(Map<String, dynamic>) label,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection(collection)
        .where('status', isEqualTo: 'PENDING')
        .limit(30)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ListTile(
          title: Text('$title unavailable'),
          subtitle: Text('${snapshot.error}'),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final docs = snapshot.data!.docs;
      if (docs.isEmpty) return ListTile(title: Text('No pending $title'));
      return Column(
        children: docs
            .map(
              (doc) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(label(doc.data())),
                        subtitle: Text(doc.id),
                        onTap: collection == 'notes'
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => NoteDetailScreen(
                                    noteId: doc.id,
                                    data: doc.data(),
                                    allowPendingReview: true,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: busy.contains(doc.id)
                                ? null
                                : () => decide(kind, doc.id, false),
                            child: const Text('Reject'),
                          ),
                          FilledButton(
                            onPressed: busy.contains(doc.id)
                                ? null
                                : () => decide(kind, doc.id, true),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administration')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Role requests', style: Theme.of(context).textTheme.titleLarge),
        queue(
          'role_requests',
          'role-requests',
          'role requests',
          (data) => '${data['uid']} requests ${data['requestedRole']}',
        ),
        const SizedBox(height: 24),
        Text(
          'Notes awaiting review',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        queue(
          'notes',
          'notes',
          'notes',
          (data) => data['title'] as String? ?? 'Untitled note',
        ),
      ],
    ),
  );
}
