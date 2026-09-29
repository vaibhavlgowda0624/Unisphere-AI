import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'grade_calculator.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});
  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final subjects = <_SubjectInput>[];
  final semesters = <TextEditingController>[];
  final history = <Map<String, dynamic>>[];
  double? result;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    addSubject();
    addSemester();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('grade_history') ?? [];
    if (mounted) {
      setState(() {
        history.addAll(
          raw.map(
            (entry) => Map<String, dynamic>.from(jsonDecode(entry) as Map),
          ),
        );
      });
    }
  }

  void addSubject() => setState(() => subjects.add(_SubjectInput()));
  void addSemester() => setState(() => semesters.add(TextEditingController()));

  Future<void> calculate() async {
    try {
      final value = tab == 0
          ? GradeCalculator.sgpa(
              subjects
                  .map(
                    (input) => SubjectGrade(
                      input.name.text,
                      double.tryParse(input.credits.text) ?? 0,
                      input.grade,
                    ),
                  )
                  .toList(),
            )
          : GradeCalculator.cgpa(
              semesters
                  .map((input) => double.tryParse(input.text) ?? double.nan)
                  .toList(),
            );
      final entry = <String, dynamic>{
        'type': tab == 0 ? 'SGPA' : 'CGPA',
        'value': value,
        'createdAt': DateTime.now().toIso8601String(),
        'inputs': tab == 0
            ? subjects
                  .map(
                    (input) => {
                      'name': input.name.text,
                      'credits': input.credits.text,
                      'grade': input.grade,
                    },
                  )
                  .toList()
            : semesters.map((input) => input.text).toList(),
      };
      final prefs = await SharedPreferences.getInstance();
      history.insert(0, entry);
      await prefs.setStringList(
        'grade_history',
        history.map(jsonEncode).toList(),
      );
      if (mounted) setState(() => result = value);
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message.toString())));
      }
    }
  }

  void restore(Map<String, dynamic> entry) {
    for (final input in subjects) {
      input.dispose();
    }
    for (final input in semesters) {
      input.dispose();
    }
    subjects.clear();
    semesters.clear();
    final isSgpa = entry['type'] == 'SGPA';
    if (isSgpa) {
      for (final raw in entry['inputs'] as List) {
        final value = Map<String, dynamic>.from(raw as Map);
        subjects.add(
          _SubjectInput(
            name: value['name'] as String,
            credits: value['credits'] as String,
            grade: value['grade'] as String,
          ),
        );
      }
      semesters.add(TextEditingController());
    } else {
      subjects.add(_SubjectInput());
      semesters.addAll(
        (entry['inputs'] as List).map(
          (value) => TextEditingController(text: value as String),
        ),
      );
    }
    setState(() {
      tab = isSgpa ? 0 : 1;
      result = null;
    });
  }

  @override
  void dispose() {
    for (final input in subjects) {
      input.dispose();
    }
    for (final input in semesters) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Grades')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('SGPA')),
            ButtonSegment(value: 1, label: Text('CGPA')),
          ],
          selected: {tab},
          onSelectionChanged: (selection) => setState(() {
            tab = selection.first;
            result = null;
          }),
        ),
        const SizedBox(height: 16),
        if (tab == 0) ...[
          for (var i = 0; i < subjects.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: subjects[i].name,
                      decoration: const InputDecoration(labelText: 'Subject'),
                    ),
                    TextField(
                      controller: subjects[i].credits,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Credits'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: subjects[i].grade,
                      decoration: const InputDecoration(labelText: 'Grade'),
                      items: GradeCalculator.gradePoints.keys
                          .map(
                            (grade) => DropdownMenuItem(
                              value: grade,
                              child: Text(grade),
                            ),
                          )
                          .toList(),
                      onChanged: (grade) =>
                          setState(() => subjects[i].grade = grade ?? 'S'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Remove subject',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => subjects.removeAt(i).dispose()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: addSubject,
            icon: const Icon(Icons.add),
            label: const Text('Add subject'),
          ),
        ] else ...[
          const Text('CGPA is the equal-weight average of semester SGPAs.'),
          for (var i = 0; i < semesters.length; i++)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: semesters[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Semester ${i + 1} SGPA',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove semester',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () =>
                      setState(() => semesters.removeAt(i).dispose()),
                ),
              ],
            ),
          OutlinedButton.icon(
            onPressed: addSemester,
            icon: const Icon(Icons.add),
            label: const Text('Add semester'),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: calculate,
          child: const Text('Calculate and save'),
        ),
        if (result != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${tab == 0 ? 'SGPA' : 'CGPA'}: ${result!.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        const SizedBox(height: 20),
        Text(
          'Saved calculations',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (history.isEmpty)
          const ListTile(title: Text('No calculations saved yet.')),
        for (final entry in history)
          ListTile(
            title: Text(
              '${entry['type']}: ${(entry['value'] as num).toStringAsFixed(2)}',
            ),
            subtitle: Text((entry['createdAt'] as String).split('T').first),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => restore(entry),
          ),
      ],
    ),
  );
}

class _SubjectInput {
  _SubjectInput({String name = '', String credits = '', this.grade = 'S'})
    : name = TextEditingController(text: name),
      credits = TextEditingController(text: credits);
  final TextEditingController name;
  final TextEditingController credits;
  String grade;
  void dispose() {
    name.dispose();
    credits.dispose();
  }
}
