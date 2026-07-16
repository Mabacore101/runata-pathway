import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/student_profile.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(StudentProfileAdapter());
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('StudentProfile Hive round-trip', () {
    test('writes and reads back a fully-populated profile', () async {
      final box = await Hive.openBox<StudentProfile>('profile_box_full');

      final profile = StudentProfile(
        dateOfBirth: DateTime(2008, 4, 12),
        phoneNumber: '+62 812-3456-7890',
        address: 'Jl. Contoh No. 1, Jakarta',
        parentName: 'Budi Santoso',
        parentPhone: '+62 813-0000-1111',
        parentEmail: 'budi@example.com',
        parentAvailableTime: 'Weekdays after 6pm',
        siblings: '1 older sister',
        allergies: 'Peanuts',
        regularMedicine: 'None',
        hospital: 'RS Contoh',
        transportation: 'School bus',
        emergencyContact: 'Budi Santoso, +62 813-0000-1111',
      );

      await box.put('profile', profile);
      await box.close();

      final reopened = await Hive.openBox<StudentProfile>('profile_box_full');
      final result = reopened.get('profile');

      expect(result, isNotNull);
      expect(result!.dateOfBirth, DateTime(2008, 4, 12));
      expect(result.phoneNumber, '+62 812-3456-7890');
      expect(result.address, 'Jl. Contoh No. 1, Jakarta');
      expect(result.parentName, 'Budi Santoso');
      expect(result.parentPhone, '+62 813-0000-1111');
      expect(result.parentEmail, 'budi@example.com');
      expect(result.parentAvailableTime, 'Weekdays after 6pm');
      expect(result.siblings, '1 older sister');
      expect(result.allergies, 'Peanuts');
      expect(result.regularMedicine, 'None');
      expect(result.hospital, 'RS Contoh');
      expect(result.transportation, 'School bus');
      expect(result.emergencyContact, 'Budi Santoso, +62 813-0000-1111');
    });

    test(
        'every field is independently nullable — an all-empty profile '
        'round-trips too (spec: "Required: No, across every field")',
        () async {
      final box = await Hive.openBox<StudentProfile>('profile_box_empty');

      await box.put('profile', StudentProfile());
      await box.close();

      final reopened = await Hive.openBox<StudentProfile>('profile_box_empty');
      final result = reopened.get('profile');

      expect(result, isNotNull);
      expect(result!.dateOfBirth, isNull);
      expect(result.phoneNumber, isNull);
      expect(result.emergencyContact, isNull);
      expect(result.hasAnyData, isFalse);
    });

    test('hasAnyData flips true once a single field is set', () {
      final withSiblingsOnly = StudentProfile(siblings: 'An only child');
      expect(withSiblingsOnly.hasAnyData, isTrue);

      final withDobOnly = StudentProfile(dateOfBirth: DateTime(2009, 1, 1));
      expect(withDobOnly.hasAnyData, isTrue);
    });

    test(
        'a whitespace-only text field does not count as "has data" '
        '(guards the Homepage checkmark against a false-positive)', () {
      final whitespaceOnly = StudentProfile(address: '   ');
      expect(whitespaceOnly.hasAnyData, isFalse);
    });
  });
}
