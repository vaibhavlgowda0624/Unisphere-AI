import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere_ai/features/grades/grade_calculator.dart';

void main() {
  test('SGPA weights grades by credits', () {
    expect(
      GradeCalculator.sgpa([
        const SubjectGrade('Math', 4, 'S'),
        const SubjectGrade('English', 2, 'B'),
      ]),
      closeTo(56 / 6, 0.00001),
    );
  });

  test('empty subjects and zero credits are invalid', () {
    expect(() => GradeCalculator.sgpa([]), throwsArgumentError);
    expect(
      () => GradeCalculator.sgpa([const SubjectGrade('Math', 0, 'S')]),
      throwsArgumentError,
    );
  });

  test('CGPA uses equal semester weighting from the UniHub report', () {
    expect(GradeCalculator.cgpa([8, 10]), 9);
    expect(() => GradeCalculator.cgpa([11]), throwsArgumentError);
  });
}
