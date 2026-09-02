import 'package:civicpulse_frontend/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators Test', () {
    test('validateFullName should return error if empty', () {
      expect(Validators.validateFullName(''), 'Full name is required');
      expect(Validators.validateFullName('  '), 'Full name is required');
      expect(Validators.validateFullName(null), 'Full name is required');
      expect(Validators.validateFullName('A'), 'Full name must be at least 2 characters');
      expect(Validators.validateFullName('John Doe'), isNull);
    });

    test('validateEmail should return error for invalid emails', () {
      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail(null), 'Email address is required');
      expect(Validators.validateEmail('notanemail'), 'Enter a valid email address');
      expect(Validators.validateEmail('john@'), 'Enter a valid email address');
      expect(Validators.validateEmail('john@example'), 'Enter a valid email address');
      expect(Validators.validateEmail('john@example.com'), isNull);
    });

    test('validatePassword should enforce minimum length', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
      expect(Validators.validatePassword('Password123!'), isNull);
    });

    test('validateConfirmPassword should check match', () {
      expect(Validators.validateConfirmPassword('pass123', ''), 'Please confirm your password');
      expect(Validators.validateConfirmPassword('pass123', 'pass456'), 'Passwords do not match');
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), isNull);
    });

    test('validatePhoneNumber should validate format when provided', () {
      expect(Validators.validatePhoneNumber(''), isNull);
      expect(Validators.validatePhoneNumber(null), isNull);
      expect(Validators.validatePhoneNumber('0771234567'), isNull);
      expect(Validators.validatePhoneNumber('+94771234567'), isNull);
      expect(Validators.validatePhoneNumber('invalidphone'), 'Enter a valid phone number (e.g., 0771234567)');
    });
  });
}
