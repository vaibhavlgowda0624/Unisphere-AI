import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../grades/grades_screen.dart';
import '../events/event_screens.dart';
import '../notes/notes_screen.dart';
import '../admin/admin_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.profile});
  final UserProfile profile;
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int index = 0;
  void open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(profile: widget.profile, open: open),
      _ExploreTab(open: open),
      _AcademicsTab(profile: widget.profile, open: open),
      _CampusTab(open: open),
      _ProfileTab(profile: widget.profile),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('UniSphere AI')),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Academics',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            label: 'Campus',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.profile, required this.open});
  final UserProfile profile;
  final void Function(Widget) open;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Hello, ${profile.name.split(' ').first}',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      Text(
        '${profile.branch} · Year ${profile.year} · ${profile.role.replaceAll('_', ' ')}',
      ),
      const SizedBox(height: 24),
      Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.calculate_outlined),
            label: const Text('Grades'),
            onPressed: () => open(const GradesScreen()),
          ),
          ActionChip(
            avatar: const Icon(Icons.event_outlined),
            label: const Text('Events'),
            onPressed: () => open(
              const CampusListScreen(collection: 'events', title: 'Events'),
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.groups_outlined),
            label: const Text('Clubs'),
            onPressed: () => open(
              const CampusListScreen(collection: 'clubs', title: 'Clubs'),
            ),
          ),
          ActionChip(
            avatar: const Icon(Icons.description_outlined),
            label: const Text('Notes'),
            onPressed: () => open(NotesScreen(profile: profile)),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text('Upcoming events', style: Theme.of(context).textTheme.titleLarge),
      const CampusPreview(collection: 'events'),
    ],
  );
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab({required this.open});
  final void Function(Widget) open;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ListTile(
        leading: const Icon(Icons.event_outlined),
        title: const Text('Events'),
        subtitle: const Text('Browse campus activities'),
        onTap: () =>
            open(const CampusListScreen(collection: 'events', title: 'Events')),
      ),
      ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: const Text('Clubs'),
        subtitle: const Text('Find student communities'),
        onTap: () =>
            open(const CampusListScreen(collection: 'clubs', title: 'Clubs')),
      ),
    ],
  );
}

class _AcademicsTab extends StatelessWidget {
  const _AcademicsTab({required this.profile, required this.open});
  final UserProfile profile;
  final void Function(Widget) open;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ListTile(
        leading: const Icon(Icons.description_outlined),
        title: const Text('Notes'),
        subtitle: const Text('Browse and upload reviewed resources'),
        onTap: () => open(NotesScreen(profile: profile)),
      ),
      ListTile(
        leading: const Icon(Icons.calculate_outlined),
        title: const Text('SGPA and CGPA'),
        subtitle: const Text('Calculate and save grades offline'),
        onTap: () => open(const GradesScreen()),
      ),
    ],
  );
}

class _CampusTab extends StatelessWidget {
  const _CampusTab({required this.open});
  final void Function(Widget) open;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ListTile(
        leading: const Icon(Icons.groups_outlined),
        title: const Text('Clubs'),
        onTap: () =>
            open(const CampusListScreen(collection: 'clubs', title: 'Clubs')),
      ),
      ListTile(
        leading: const Icon(Icons.event_outlined),
        title: const Text('Events'),
        onTap: () =>
            open(const CampusListScreen(collection: 'events', title: 'Events')),
      ),
    ],
  );
}

class CampusPreview extends StatelessWidget {
  const CampusPreview({super.key, required this.collection});
  final String collection;
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(collection)
            .where('status', isEqualTo: 'PUBLISHED')
            .limit(3)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListTile(
              title: const Text('Could not load events'),
              subtitle: Text(snapshot.error.toString()),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const ListTile(title: Text('No events yet'));
          }
          return Column(
            children: snapshot.data!.docs
                .map(
                  (doc) => ListTile(
                    title: Text(
                      doc.data()['title'] as String? ?? 'Untitled event',
                    ),
                    subtitle: Text(doc.data()['venue'] as String? ?? ''),
                  ),
                )
                .toList(),
          );
        },
      );
}

class CampusListScreen extends StatelessWidget {
  const CampusListScreen({
    super.key,
    required this.collection,
    required this.title,
  });
  final String collection;
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    floatingActionButton: collection == 'events'
        ? StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final role = snapshot.data?.data()?['role'] as String?;
              if (!['FACULTY', 'CLUB_ADMIN', 'SUPER_ADMIN'].contains(role)) {
                return const SizedBox.shrink();
              }
              return FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const EventEditorScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create event'),
              );
            },
          )
        : null,
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('status', isEqualTo: 'PUBLISHED')
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load $title: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text('No ${title.toLowerCase()} published yet.'),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                title: Text(
                  data['title'] as String? ??
                      data['name'] as String? ??
                      'Untitled',
                ),
                subtitle: Text(
                  data['description'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => collection == 'events'
                        ? EventDetailScreen(eventId: docs[index].id, data: data)
                        : _CampusDetailScreen(title: title, data: data),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _CampusDetailScreen extends StatelessWidget {
  const _CampusDetailScreen({required this.title, required this.data});
  final String title;
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(data['title'] as String? ?? data['name'] as String? ?? title),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          data['description'] as String? ?? 'No description provided.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        for (final field in ['category', 'venue', 'organizer', 'branch'])
          if (data[field] != null)
            ListTile(
              title: Text(field[0].toUpperCase() + field.substring(1)),
              subtitle: Text(data[field].toString()),
            ),
      ],
    ),
  );
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab({required this.profile});
  final UserProfile profile;
  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  Future<void> requestRole() async {
    final choices = widget.profile.role == 'FACULTY'
        ? const ['CLUB_ADMIN']
        : const ['FACULTY', 'CLUB_ADMIN'];
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: choices
              .map(
                (choice) => ListTile(
                  title: Text('Request ${choice.replaceAll('_', ' ')}'),
                  onTap: () => Navigator.pop(context, choice),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (role == null) return;
    try {
      await ref
          .read(authRepositoryProvider)
          .requestRole(widget.profile.uid, role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role request submitted for admin review.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  Future<void> edit() async {
    final name = TextEditingController(text: widget.profile.name);
    final branch = TextEditingController(text: widget.profile.branch);
    final bio = TextEditingController(text: widget.profile.bio);
    var year = widget.profile.year;
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: branch,
                  decoration: const InputDecoration(labelText: 'Branch'),
                ),
                TextField(
                  controller: bio,
                  decoration: const InputDecoration(labelText: 'Bio'),
                ),
                DropdownButtonFormField<int>(
                  initialValue: year,
                  items: [1, 2, 3, 4, 5, 6]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('Year $value'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => year = value ?? year,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (saved == true) {
        if (name.text.trim().isEmpty || branch.text.trim().isEmpty) {
          throw ArgumentError('Name and branch are required');
        }
        await ref
            .read(authRepositoryProvider)
            .updateProfile(
              widget.profile.uid,
              name: name.text,
              bio: bio.text,
              branch: branch.text,
              year: year,
            );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      name.dispose();
      branch.dispose();
      bio.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 24),
      CircleAvatar(
        radius: 40,
        child: Text(widget.profile.name.isEmpty ? '?' : widget.profile.name[0]),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          widget.profile.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      Center(child: Text(widget.profile.email)),
      const SizedBox(height: 20),
      ListTile(
        title: const Text('Role'),
        subtitle: Text(widget.profile.role.replaceAll('_', ' ')),
      ),
      ListTile(
        title: const Text('Branch'),
        subtitle: Text(widget.profile.branch),
      ),
      ListTile(
        title: const Text('Academic year'),
        subtitle: Text('${widget.profile.year}'),
      ),
      if (widget.profile.bio.isNotEmpty)
        ListTile(title: const Text('Bio'), subtitle: Text(widget.profile.bio)),
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('Edit profile'),
        onTap: edit,
      ),
      if (widget.profile.role == 'STUDENT' || widget.profile.role == 'FACULTY')
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Request elevated role'),
          onTap: requestRole,
        ),
      if (widget.profile.role == 'SUPER_ADMIN')
        ListTile(
          leading: const Icon(Icons.admin_panel_settings_outlined),
          title: const Text('Administration'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const AdminScreen()),
          ),
        ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sign out'),
        onTap: () => ref.read(authRepositoryProvider).signOut(),
      ),
    ],
  );
}
