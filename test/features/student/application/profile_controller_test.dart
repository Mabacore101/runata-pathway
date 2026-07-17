import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/profile_controller.dart';
import 'package:runata_pathway/features/student/data/student_profile_repository.dart';
import 'package:runata_pathway/features/student/domain/parent_guardian_entry.dart';
import 'package:runata_pathway/features/student/domain/student_profile.dart';

void main() {
  group('parseDateOfBirth', () {
    test('parses a valid dd/MM/yyyy date', () {
      expect(parseDateOfBirth('12/04/2008'), DateTime(2008, 4, 12));
    });

    test('accepts single-digit day/month', () {
      expect(parseDateOfBirth('3/7/2010'), DateTime(2010, 7, 3));
    });

    test(
        'rejects Feb 30 — Dart\'s DateTime constructor would otherwise '
        'silently roll this over to March 2nd instead of rejecting it',
        () {
      expect(parseDateOfBirth('30/02/2026'), isNull);
    });

    test('rejects a month outside 1-12', () {
      expect(parseDateOfBirth('01/13/2020'), isNull);
    });

    test('rejects a year in the future', () {
      final nextYear = DateTime.now().year + 1;
      expect(parseDateOfBirth('01/01/$nextYear'), isNull);
    });

    test('rejects garbage / wrong-format text', () {
      expect(parseDateOfBirth('not a date'), isNull);
      expect(parseDateOfBirth('2008-04-12'), isNull);
      expect(parseDateOfBirth(''), isNull);
    });
  });

  group('ProfileController.save', () {
    late ProviderContainer container;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(ParentGuardianEntryAdapter());
      registerAdapterIfNeeded(StudentProfileAdapter());
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestHive();
    });

    ProviderContainer buildContainer(Box<StudentProfile> box) {
      return ProviderContainer(
        overrides: [
          studentProfileRepositoryProvider.overrideWithValue(
            StudentProfileRepository(box),
          ),
        ],
      );
    }

    test('a valid date saves normally with no warning', () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_valid');
      container = buildContainer(box);

      await container.read(profileControllerProvider.notifier).save(
            rawDateOfBirth: '12/04/2008',
            siblings: 'An older brother',
            parents: const [],
          );

      final state = container.read(profileControllerProvider);
      expect(state.dateOfBirthWarning, isNull);
      expect(state.justSaved, isTrue);
      expect(state.profile.dateOfBirth, DateTime(2008, 4, 12));
      expect(state.profile.siblings, 'An older brother');
    });

    test(
        'an invalid date does not save, warns, but every other field '
        'still saves — planning.md §6\'s decided fix', () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_invalid');
      container = buildContainer(box);

      await container.read(profileControllerProvider.notifier).save(
            rawDateOfBirth: '30/02/2026',
            phoneNumber: '+62 812-0000-0000',
            emergencyContact: 'Ayah, +62 812-0000-0000',
            parents: const [],
          );

      final state = container.read(profileControllerProvider);
      expect(state.dateOfBirthWarning, isNotNull);
      expect(state.justSaved, isFalse);
      expect(state.profile.dateOfBirth, isNull); // not saved
      expect(state.profile.phoneNumber, '+62 812-0000-0000'); // still saved
      expect(
        state.profile.emergencyContact,
        'Ayah, +62 812-0000-0000',
      ); // still saved
    });

    test('a blank date field clears a previously-saved date', () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_clear');
      container = buildContainer(box);
      final notifier = container.read(profileControllerProvider.notifier);

      await notifier.save(rawDateOfBirth: '01/01/2009', parents: const []);
      expect(
        container.read(profileControllerProvider).profile.dateOfBirth,
        DateTime(2009, 1, 1),
      );

      await notifier.save(rawDateOfBirth: '', parents: const []);
      expect(
        container.read(profileControllerProvider).profile.dateOfBirth,
        isNull,
      );
    });

    test('blank text fields save as null, not empty strings', () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_blank');
      container = buildContainer(box);

      await container.read(profileControllerProvider.notifier).save(
            rawDateOfBirth: '',
            phoneNumber: '   ',
            address: '',
            parents: const [],
          );

      final profile = container.read(profileControllerProvider).profile;
      expect(profile.phoneNumber, isNull);
      expect(profile.address, isNull);
    });

    test('a re-saved invalid date keeps warning on repeated attempts',
        () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_repeat');
      container = buildContainer(box);
      final notifier = container.read(profileControllerProvider.notifier);

      await notifier.save(
        rawDateOfBirth: '31/04/2020', // April has 30 days
        parents: const [],
      );
      expect(
        container.read(profileControllerProvider).dateOfBirthWarning,
        isNotNull,
      );

      await notifier.save(rawDateOfBirth: '31/04/2020', parents: const []);
      expect(
        container.read(profileControllerProvider).dateOfBirthWarning,
        isNotNull,
      );
    });

    test('an empty parents list normalizes to one blank entry, never zero',
        () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_no_parents');
      container = buildContainer(box);

      await container.read(profileControllerProvider.notifier).save(
            rawDateOfBirth: '',
            parents: const [],
          );

      final profile = container.read(profileControllerProvider).profile;
      expect(profile.parents, hasLength(1));
      expect(profile.parents.single.hasAnyData, isFalse);
    });

    test('multiple parent/guardian entries all persist, in order', () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_multi_parent');
      container = buildContainer(box);

      await container.read(profileControllerProvider.notifier).save(
            rawDateOfBirth: '',
            parents: [
              ParentGuardianEntry(name: 'Ayah', phone: '0812'),
              ParentGuardianEntry(name: 'Ibu', phone: '0813'),
            ],
          );

      final profile = container.read(profileControllerProvider).profile;
      expect(profile.parents, hasLength(2));
      expect(profile.parents[0].name, 'Ayah');
      expect(profile.parents[1].name, 'Ibu');
    });

    test(
        'a blank parent entry is kept as-is on save — dropping blank rows '
        'is a UI-only delete-button action, not something save() infers',
        () async {
      final box = await Hive.openBox<StudentProfile>('profile_ctrl_blank_parent');
      container = buildContainer(box);

      await container.read(profileControllerProvider.notifier).save(
            rawDateOfBirth: '',
            parents: [
              ParentGuardianEntry(name: 'Ayah'),
              ParentGuardianEntry(), // fully blank, never deleted explicitly
            ],
          );

      final profile = container.read(profileControllerProvider).profile;
      expect(profile.parents, hasLength(2));
      expect(profile.parents[1].hasAnyData, isFalse);
    });
  });
}