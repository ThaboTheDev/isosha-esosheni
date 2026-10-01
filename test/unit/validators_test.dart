import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/utils/validators.dart';

void main() {
  group('registration validators', () {
    test('full name bounds', () {
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName('Ab'), isNull);
      expect(Validators.fullName('Naledi Dlamini'), isNull);
      expect(Validators.fullName('x' * 121), isNotNull);
    });

    test('preferred name optional and capped', () {
      expect(Validators.preferredName(''), isNull);
      expect(Validators.preferredName('y' * 61), isNotNull);
    });

    test('date of birth exact messages', () {
      final now = DateTime(2026, 10, 1);
      expect(
        Validators.dateOfBirth(DateTime(2010, 1, 1), now),
        'Isosha Esosheni is open to members aged 18 and older.',
      );
      expect(
        Validators.dateOfBirth(DateTime(1900, 1, 1), now),
        'Check your date of birth.',
      );
      expect(Validators.dateOfBirth(DateTime(1994, 5, 12), now), isNull);
      // 18th birthday today is allowed.
      expect(
        Validators.dateOfBirth(DateTime(2008, 10, 1), now),
        isNull,
      );
    });

    test('password rules with exact messages', () {
      expect(Validators.password('Ab1'), 'Password must be at least 10 characters.');
      expect(Validators.password('abcd1234567'),
          'Password must include an uppercase letter.');
      expect(Validators.password('ABCD1234567'),
          'Password must include a lowercase letter.');
      expect(Validators.password('Abcdefghijk'),
          'Password must include a number.');
      expect(Validators.password('Abcdefgh1jk'), isNull);
    });

    test('confirm password', () {
      expect(Validators.confirm('Abcdefgh1jk', 'Abcdefgh1jk'), isNull);
      expect(Validators.confirm('Abcdefgh1jk', 'Abcdefgh1jx'),
          'Passwords do not match.');
    });

    test('age calculation', () {
      expect(
        Validators.ageInYears(DateTime(2000, 6, 15), DateTime(2026, 6, 14)),
        25,
      );
      expect(
        Validators.ageInYears(DateTime(2000, 6, 15), DateTime(2026, 6, 15)),
        26,
      );
    });

    test('age range ordering message', () {
      expect(Validators.ageRange(30, 25),
          'Maximum age must be at least the minimum age.');
      expect(Validators.ageRange(25, 30), isNull);
    });

    test('membership number and phone', () {
      expect(Validators.membershipNumber('AB'), isNotNull);
      expect(Validators.membershipNumber('TRSH-123/45'), isNull);
      expect(Validators.phone('+27 82 123 4567'), isNull);
      expect(Validators.phone('abc'), isNotNull);
    });
  });
}
