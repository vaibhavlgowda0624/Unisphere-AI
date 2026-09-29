import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.eventId,
    required this.data,
  });
  final String eventId;
  final Map<String, dynamic> data;
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool busy = false;
  Future<void> changeRegistration(bool registered) async {
    setState(() => busy = true);
    try {
      final api = ApiClient();
      final path = '/api/events/${widget.eventId}/registrations';
      if (registered) {
        await api.delete(path);
      } else {
        await api.post(path);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              registered ? 'Registration cancelled' : 'Registration confirmed',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final registrationId = '${widget.eventId}_$uid';
    final startsAt = widget.data['startsAt'];
    final endsAt = widget.data['endsAt'];
    final count = (widget.data['registeredCount'] as num?)?.toInt() ?? 0;
    final capacity = (widget.data['maxSeats'] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(widget.data['title'] as String? ?? 'Event')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.data['description'] as String? ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(widget.data['venue'] as String? ?? 'Venue not set'),
          ),
          ListTile(
            leading: const Icon(Icons.groups_outlined),
            title: Text(
              widget.data['organizer'] as String? ?? 'Organizer not set',
            ),
          ),
          if (startsAt is Timestamp)
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text('Starts ${startsAt.toDate().toLocal()}'),
            ),
          if (endsAt is Timestamp)
            ListTile(
              leading: const Icon(Icons.event_busy_outlined),
              title: Text('Ends ${endsAt.toDate().toLocal()}'),
            ),
          ListTile(
            title: Text(
              capacity == 0
                  ? '$count registered'
                  : '$count of $capacity seats filled',
            ),
          ),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('event_registrations')
                .doc(registrationId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Registration status unavailable: ${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final registered = snapshot.data!.exists;
              final expired =
                  endsAt is Timestamp &&
                  !endsAt.toDate().isAfter(DateTime.now());
              return FilledButton(
                onPressed: busy || (expired && !registered)
                    ? null
                    : () => changeRegistration(registered),
                child: Text(
                  registered
                      ? 'Cancel registration'
                      : expired
                      ? 'Event ended'
                      : 'Register',
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({super.key});
  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final description = TextEditingController();
  final venue = TextEditingController();
  final organizer = TextEditingController();
  final category = TextEditingController();
  final seats = TextEditingController(text: '0');
  DateTime? startsAt;
  DateTime? endsAt;
  bool busy = false;

  @override
  void dispose() {
    for (final controller in [
      title,
      description,
      venue,
      organizer,
      category,
      seats,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> pickDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (value == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;
    setState(() {
      final date = DateTime(
        value.year,
        value.month,
        value.day,
        time.hour,
        time.minute,
      );
      if (start) {
        startsAt = date;
      } else {
        endsAt = date;
      }
    });
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (startsAt == null || endsAt == null || !endsAt!.isAfter(startsAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose valid start and end times.')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final api = ApiClient();
      final result = await api.post('/api/events', {
        'title': title.text,
        'description': description.text,
        'venue': venue.text,
        'organizer': organizer.text,
        'category': category.text,
        'maxSeats': int.parse(seats.text),
        'startsAt': startsAt!.toUtc().toIso8601String(),
        'endsAt': endsAt!.toUtc().toIso8601String(),
      });
      await api.post('/api/events/${result['id']}/publish');
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Event not saved: $error')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create event')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (controller, label) in [
            (title, 'Title'),
            (description, 'Description'),
            (venue, 'Venue'),
            (organizer, 'Organizer'),
            (category, 'Category'),
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
            controller: seats,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Maximum seats (0 = unlimited)',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                int.tryParse(value ?? '') == null || int.parse(value!) < 0
                ? 'Enter zero or a positive number'
                : null,
          ),
          ListTile(
            title: Text(startsAt == null ? 'Choose start' : 'Starts $startsAt'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => pickDate(true),
          ),
          ListTile(
            title: Text(endsAt == null ? 'Choose end' : 'Ends $endsAt'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => pickDate(false),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : save,
            child: busy
                ? const CircularProgressIndicator()
                : const Text('Create and publish'),
          ),
        ],
      ),
    ),
  );
}
