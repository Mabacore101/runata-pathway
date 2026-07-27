import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/counsellor_corner.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(CounsellorCornerAdapter());
  });

  tearDown(() async => tearDownTestHive());

  group('Hive round-trip', () {
    test('writes and reads back a fully-populated record, keyed by a '
        'fixed key', () async {
      final box = await Hive.openBox<CounsellorCorner>('counsel_box_full');

      final record = CounsellorCorner(
        qualityTime: 'Dinner together every night',
        addressedBy: 'Other',
        addressedOther: 'Grandmother',
        talksWith: 'Both',
        eduAdult: 'Mother',
        hadTherapy: 'Yes',
        currentTherapy: 'Weekly speech therapy',
        runataNotes: 'Needs encouragement in Math',
      );

      await box.put('counsel', record);
      await box.close();

      final reopened = await Hive.openBox<CounsellorCorner>('counsel_box_full');
      final result = reopened.get('counsel');

      expect(result, isNotNull);
      expect(result!.qualityTime, 'Dinner together every night');
      expect(result.addressedBy, 'Other');
      expect(result.addressedOther, 'Grandmother');
      expect(result.talksWith, 'Both');
      expect(result.eduAdult, 'Mother');
      expect(result.hadTherapy, 'Yes');
      expect(result.currentTherapy, 'Weekly speech therapy');
      expect(result.runataNotes, 'Needs encouragement in Math');
    });

    test('a key with nothing written returns null, not a default instance '
        '— same contract as every other single-record model in this app',
        () async {
      final box = await Hive.openBox<CounsellorCorner>('counsel_box_missing');
      expect(box.get('counsel'), isNull);
    });

    test('every field round-trips independently — a spot-check across all '
        '3 "who" dropdowns plus the Yes/No dropdown together', () async {
      final box = await Hive.openBox<CounsellorCorner>('counsel_box_all_dropdowns');

      await box.put(
        'counsel',
        CounsellorCorner(
          addressedBy: 'Father',
          talksWith: 'Mother',
          eduAdult: 'Both',
          hadTherapy: 'No',
        ),
      );
      await box.close();

      final reopened =
          await Hive.openBox<CounsellorCorner>('counsel_box_all_dropdowns');
      final result = reopened.get('counsel')!;

      expect(result.addressedBy, 'Father');
      expect(result.talksWith, 'Mother');
      expect(result.eduAdult, 'Both');
      expect(result.hadTherapy, 'No');
    });
  });

  group('defaults', () {
    test('a new CounsellorCorner() starts with every field as an empty '
        'string, never null — matching the JS\'s counsel[name] '
        'initializer exactly', () {
      final record = CounsellorCorner();

      expect(record.qualityTime, '');
      expect(record.addressedBy, '');
      expect(record.addressedOther, '');
      expect(record.hadTherapy, '');
      expect(record.runataNotes, '');
    });
  });

  group('hasAnyData', () {
    test('false when every field is blank or whitespace-only', () {
      expect(CounsellorCorner().hasAnyData, isFalse);
      expect(CounsellorCorner(qualityTime: '   ').hasAnyData, isFalse);
    });

    test('true once any single field has real text', () {
      expect(CounsellorCorner(famOther: 'A short note.').hasAnyData, isTrue);
    });

    test('true when only a dropdown field (not free text) has been '
        'answered', () {
      expect(CounsellorCorner(hadTherapy: 'No').hasAnyData, isTrue);
    });
  });

  group('copyWith', () {
    test('updates only the specified field, preserving every other field',
        () {
      final original = CounsellorCorner(
        qualityTime: 'Original quality time',
        rules: 'Original rules',
      );

      final updated = original.copyWith(rules: 'New rules');

      expect(updated.qualityTime, 'Original quality time');
      expect(updated.rules, 'New rules');
    });

    test('can explicitly clear a field back to an empty string — passing '
        "'' is not the same as not passing the argument at all", () {
      final original = CounsellorCorner(famOther: 'Some note');
      final cleared = original.copyWith(famOther: '');
      expect(cleared.famOther, '');
    });

    test('updating one "who" dropdown never touches the other two, or '
        'their own "Other" fields', () {
      final original = CounsellorCorner(
        addressedBy: 'Other',
        addressedOther: 'Grandmother',
        talksWith: 'Father',
        eduAdult: 'Mother',
      );

      final updated = original.copyWith(talksWith: 'Both');

      expect(updated.addressedBy, 'Other');
      expect(updated.addressedOther, 'Grandmother');
      expect(updated.talksWith, 'Both');
      expect(updated.eduAdult, 'Mother');
    });
  });

  group('familyAddresserOptions / therapyOptions', () {
    test('familyAddresserOptions matches the JS\'s cwho() options array '
        'exactly, including the leading blank "not yet answered" option',
        () {
      expect(
        familyAddresserOptions,
        ['', 'Father', 'Mother', 'Both', 'None', 'Other'],
      );
    });

    test('therapyOptions matches the JS\'s inline Yes/No select exactly',
        () {
      expect(therapyOptions, ['', 'Yes', 'No']);
    });
  });
}
