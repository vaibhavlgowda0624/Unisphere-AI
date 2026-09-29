import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../auth/auth_repository.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key, required this.profile});
  final UserProfile profile;
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final search = TextEditingController();
  bool mine = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = mine
        ? FirebaseFirestore.instance
              .collection('notes')
              .where('uploaderUid', isEqualTo: widget.profile.uid)
        : FirebaseFirestore.instance
              .collection('notes')
              .where('status', isEqualTo: 'APPROVED');
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => _UploadNoteScreen(profile: widget.profile),
          ),
        ),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search loaded notes',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('My uploads'),
            value: mine,
            onChanged: (value) => setState(() => mine = value),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.limit(50).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Notes unavailable: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final term = search.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return term.isEmpty ||
                      [
                        data['title'],
                        data['subject'],
                        data['branch'],
                        ...(data['tags'] as List? ?? []),
                      ].any(
                        (value) =>
                            value.toString().toLowerCase().contains(term),
                      );
                }).toList();
                if (docs.isEmpty) {
                  return const Center(child: Text('No matching notes.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(data['title'] as String? ?? 'Untitled note'),
                      subtitle: Text(
                        '${data['subject'] ?? ''} · ${data['status'] ?? ''}',
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              NoteDetailScreen(noteId: doc.id, data: data),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadNoteScreen extends StatefulWidget {
  const _UploadNoteScreen({required this.profile});
  final UserProfile profile;
  @override
  State<_UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<_UploadNoteScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final subject = TextEditingController();
  final tags = TextEditingController();
  PlatformFile? selectedFile;
  bool busy = false;
  @override
  void dispose() {
    for (final controller in [title, description, subject, tags]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
    );
    if (result != null && mounted) setState(() => selectedFile = result);
  }

  Future<void> upload() async {
    if (!form.currentState!.validate()) return;
    final file = selectedFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a PDF or DOCX smaller than 10 MB.'),
        ),
      );
      return;
    }
    final length = await file.length();
    if (!mounted) return;
    if (length == null || length <= 0 || length > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a PDF or DOCX smaller than 10 MB.'),
        ),
      );
      return;
    }
    final extension = file.extension?.toLowerCase();
    if (extension != 'pdf' && extension != 'docx') return;
    setState(() => busy = true);
    final db = FirebaseFirestore.instance;
    final ref = db.collection('notes').doc();
    final path = 'notes/${widget.profile.uid}/${ref.id}';
    try {
      await ref.set({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'subject': subject.text.trim(),
        'branch': widget.profile.branch,
        'year': widget.profile.year,
        'tags': tags.text
            .split(',')
            .map((tag) => tag.trim().toLowerCase())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        'uploaderUid': widget.profile.uid,
        'filePath': path,
        'fileType': extension!.toUpperCase(),
        'status': 'PENDING',
        'downloadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final bytes = await file.readAsBytes();
      await FirebaseStorage.instance
          .ref(path)
          .putData(
            bytes,
            SettableMetadata(
              contentType: extension == 'pdf' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Uploaded for moderation. Check My uploads for status.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      try {
        await ref.delete();
      } catch (_) {
        /* Keep original failure. */
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Upload note')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (controller, label) in [
            (title, 'Title'),
            (subject, 'Subject'),
          ]) ...[
            TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '$label is required'
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: description,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: tags,
            decoration: const InputDecoration(
              labelText: 'Tags, separated by commas',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(selectedFile?.name ?? 'Choose PDF or DOCX'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : upload,
            child: busy
                ? const CircularProgressIndicator()
                : const Text('Upload for review'),
          ),
        ],
      ),
    ),
  );
}

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({
    super.key,
    required this.noteId,
    required this.data,
    this.allowPendingReview = false,
  });
  final String noteId;
  final Map<String, dynamic> data;
  final bool allowPendingReview;
  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool busy = false;
  Future<void> openFile() async {
    setState(() => busy = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/${widget.noteId}.${(widget.data['fileType'] as String).toLowerCase()}';
      final file = File(path);
      if (!await file.exists()) {
        await FirebaseStorage.instance
            .ref(widget.data['filePath'] as String)
            .writeToFile(file);
      }
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) throw StateError(result.message);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open file: $error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.data['title'] as String? ?? 'Note')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(widget.data['description'] as String? ?? ''),
        ListTile(
          title: const Text('Subject'),
          subtitle: Text(widget.data['subject'] as String? ?? ''),
        ),
        ListTile(
          title: const Text('Branch'),
          subtitle: Text(widget.data['branch'] as String? ?? ''),
        ),
        ListTile(
          title: const Text('Review status'),
          subtitle: Text(widget.data['status'] as String? ?? ''),
        ),
        if (widget.allowPendingReview ||
            widget.data['status'] == 'APPROVED' ||
            widget.data['uploaderUid'] ==
                FirebaseAuth.instance.currentUser?.uid)
          FilledButton.icon(
            onPressed: busy ? null : openFile,
            icon: const Icon(Icons.download_outlined),
            label: Text(busy ? 'Opening…' : 'Download and open'),
          ),
      ],
    ),
  );
}
