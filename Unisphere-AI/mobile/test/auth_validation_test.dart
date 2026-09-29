import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere_ai/features/auth/auth_validation.dart';

void main() {
  test('registration rejects weak and mismatched passwords', () {
    expect(AuthValidation.password('short'), isNotNull);
    expect(
      AuthValidation.confirmPassword('LongPass123', 'Different123'),
      isNotNull,
    );
    expect(
      AuthValidation.confirmPassword('LongPass123', 'LongPass123'),
      isNull,
    );
  });

  test('configured university domain is required', () {
    expect(
      AuthValidation.email('student@example.com', 'university.edu'),
      isNotNull,
    );
    expect(
      AuthValidation.email('student@university.edu', 'university.edu'),
      isNull,
    );
  });
}
