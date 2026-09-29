class SubjectGrade {
  const SubjectGrade(this.name, this.credits, this.grade);
  final String name;
  final double credits;
  final String grade;
}

class GradeCalculator {
  static const gradePoints = <String, double>{
    'S': 10,
    'A': 9,
    'B': 8,
    'C': 7,
    'D': 6,
    'E': 5,
    'F': 0,
  };

  static double sgpa(List<SubjectGrade> subjects) {
    if (subjects.isEmpty) throw ArgumentError('Add at least one subject');
    var credits = 0.0;
    var weightedPoints = 0.0;
    for (final subject in subjects) {
      if (subject.name.trim().isEmpty ||
          subject.credits <= 0 ||
          !subject.credits.isFinite ||
          !gradePoints.containsKey(subject.grade)) {
        throw ArgumentError(
          'Each subject needs a name, positive credits and valid grade',
        );
      }
      credits += subject.credits;
      weightedPoints += subject.credits * gradePoints[subject.grade]!;
    }
    return weightedPoints / credits;
  }

  static double cgpa(List<double> semesters) {
    if (semesters.isEmpty ||
        semesters.any((gpa) => !gpa.isFinite || gpa < 0 || gpa > 10)) {
      throw ArgumentError('Add semester GPAs between 0 and 10');
    }
    return semesters.reduce((a, b) => a + b) / semesters.length;
  }
}
