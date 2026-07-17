import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/parent_guardian_entry.dart';
import 'package:runata_pathway/features/student/domain/student_profile.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(ParentGuardianEntryAdapter());
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
        parents: [
          ParentGuardianEntry(
            name: 'Budi Santoso',
            phone: '+62 813-0000-1111',
            email: 'budi@example.com',
            availableTime: 'Weekdays after 6pm',
            address: 'Jl. Contoh No. 1, Jakarta',
          ),
        ],
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
      expect(result.parents, hasLength(1));
      expect(result.parents.single.name, 'Budi Santoso');
      expect(result.parents.single.phone, '+62 813-0000-1111');
      expect(result.parents.single.email, 'budi@example.com');
      expect(result.parents.single.availableTime, 'Weekdays after 6pm');
      expect(result.parents.single.address, 'Jl. Contoh No. 1, Jakarta');
      expect(result.siblings, '1 older sister');
      expect(result.allergies, 'Peanuts');
      expect(result.regularMedicine, 'None');
      expect(result.hospital, 'RS Contoh');
      expect(result.transportation, 'School bus');
      expect(result.emergencyContact, 'Budi Santoso, +62 813-0000-1111');
    });

    test('multiple parent/guardian entries round-trip in order', () async {
      final box = await Hive.openBox<StudentProfile>('profile_box_multi_parent');

      final profile = StudentProfile(
        parents: [
          ParentGuardianEntry(name: 'Ayah'),
          ParentGuardianEntry(name: 'Ibu'),
          ParentGuardianEntry(name: 'Wali'),
        ],
      );

      await box.put('profile', profile);
      await box.close();

      final reopened =
          await Hive.openBox<StudentProfile>('profile_box_multi_parent');
      final result = reopened.get('profile');

      expect(result!.parents, hasLength(3));
      expect(result.parents.map((p) => p.name), ['Ayah', 'Ibu', 'Wali']);
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
      // A brand-new profile still seeds exactly one blank parent block,
      // matching the JS `prof()` factory — not zero.
      expect(result.parents, hasLength(1));
      expect(result.parents.single.hasAnyData, isFalse);
      expect(result.hasAnyData, isFalse);
    });

    test('hasAnyData flips true once a single field is set', () {
      final withSiblingsOnly = StudentProfile(siblings: 'An only child');
      expect(withSiblingsOnly.hasAnyData, isTrue);

      final withDobOnly = StudentProfile(dateOfBirth: DateTime(2009, 1, 1));
      expect(withDobOnly.hasAnyData, isTrue);
    });

    test('hasAnyData flips true from parent data alone, even with every '
        'other field blank', () {
      final profile = StudentProfile(
        parents: [ParentGuardianEntry(phone: '0812')],
      );
      expect(profile.hasAnyData, isTrue);
    });

    test(
        'a whitespace-only text field does not count as "has data" '
        '(guards the Homepage checkmark against a false-positive)', () {
      final whitespaceOnly = StudentProfile(address: '   ');
      expect(whitespaceOnly.hasAnyData, isFalse);

      final blankParent = StudentProfile(
        parents: [ParentGuardianEntry(name: '   ', phone: '')],
      );
      expect(blankParent.hasAnyData, isFalse);
    });
  });
}