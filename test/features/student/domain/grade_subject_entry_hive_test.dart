import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/grade_subject_entry.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(GradeSubjectGroupAdapter());
    registerAdapterIfNeeded(GradeSubjectEntryAdapter());
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('GradeSubjectEntry Hive round-trip', () {
    test('writes and reads back a fixed-group subject with a score',
        () async {
      final box = await Hive.openBox<GradeSubjectEntry>('grades_box_basic');

      final entry = GradeSubjectEntry(
        id: 'g1',
        semesterCode: SemesterCode.gr10s1,
        name: 'Mathematics',
        score: 88,
        group: GradeSubjectGroup.coreSubjects,
      );

      await box.put(entry.id, entry);
      await box.close();

      final reopened = await Hive.openBox<GradeSubjectEntry>('grades_box_basic');
      final result = reopened.get('g1');

      expect(result, isNotNull);
      expect(result!.semesterCode, SemesterCode.gr10s1);
      expect(result.name, 'Mathematics');
      expect(result.score, 88);
      expect(result.group, GradeSubjectGroup.coreSubjects);
      expect(result.isCustom, isFalse);
    });

    test(
        'a null score round-trips as null, not 0 — an unscored subject '
        'must stay distinguishable from an actual zero', () async {
      final box = await Hive.openBox<GradeSubjectEntry>('grades_box_null_score');

      final entry = GradeSubjectEntry(
        id: 'g2',
        semesterCode: SemesterCode.gr11s2,
        name: 'Student-Added Elective',
        group: GradeSubjectGroup.other,
        isCustom: true,
      );

      await box.put(entry.id, entry);
      await box.close();

      final reopened =
          await Hive.openBox<GradeSubjectEntry>('grades_box_null_score');
      final result = reopened.get('g2');

      expect(result!.score, isNull);
      expect(result.isCustom, isTrue);
    });

    test(
        'an out-of-range manually-typed score round-trips UNCHANGED — '
        'the model must not clamp (known bug, knowingly replicated per '
        'planning.md §6)', () async {
      // If this test starts failing because the model silently clamps or
      // rejects the value, that's a sign someone "fixed" the bug at the
      // model layer without an explicit decision update — the real fix,
      // whenever it happens, is expected to land as a documented stance
      // change, not a silent model tweak.
      final box = await Hive.openBox<GradeSubjectEntry>('grades_box_bug');

      final entry = GradeSubjectEntry(
        id: 'g3',
        semesterCode: SemesterCode.gr12s1,
        name: 'Physics',
        score: 137,
        group: GradeSubjectGroup.coreEssentials,
      );

      await box.put(entry.id, entry);
      await box.close();

      final reopened = await Hive.openBox<GradeSubjectEntry>('grades_box_bug');
      expect(reopened.get('g3')!.score, 137);

      // Negative manually-typed values are the same bug, mirrored below.
      final negativeEntry = GradeSubjectEntry(
        id: 'g4',
        semesterCode: SemesterCode.gr12s1,
        name: 'Chemistry',
        score: -12,
        group: GradeSubjectGroup.coreEssentials,
      );
      await reopened.put(negativeEntry.id, negativeEntry);
      expect(reopened.get('g4')!.score, -12);
    });

    test('every GradeSubjectGroup value survives a round-trip', () async {
      final box = await Hive.openBox<GradeSubjectEntry>('grades_box_groups');

      for (final group in GradeSubjectGroup.values) {
        final id = group.name;
        await box.put(
          id,
          GradeSubjectEntry(
            id: id,
            semesterCode: SemesterCode.gr10s2,
            name: 'Subject for $id',
            group: group,
          ),
        );
      }
      await box.close();

      final reopened = await Hive.openBox<GradeSubjectEntry>('grades_box_groups');
      for (final group in GradeSubjectGroup.values) {
        expect(reopened.get(group.name)!.group, group);
      }
    });

    test('all 6 SemesterCode values are distinct and filterable', () async {
      final box = await Hive.openBox<GradeSubjectEntry>('grades_box_semesters');

      for (final code in SemesterCode.all) {
        await box.put(
          code,
          GradeSubjectEntry(
            id: code,
            semesterCode: code,
            name: 'Marker Subject',
            group: GradeSubjectGroup.coreGeneral,
          ),
        );
      }

      expect(SemesterCode.all.toSet().length, 6);
      for (final code in SemesterCode.all) {
        final matches =
            box.values.where((e) => e.semesterCode == code).toList();
        expect(matches, hasLength(1));
      }
    });
  });
}
