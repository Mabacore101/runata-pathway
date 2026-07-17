import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/grades_controller.dart';
import 'package:runata_pathway/features/student/data/student_grades_repository.dart';
import 'package:runata_pathway/features/student/domain/curriculum.dart';
import 'package:runata_pathway/features/student/domain/grade_subject_entry.dart';
import 'package:runata_pathway/features/student/domain/student_grades_settings.dart';

GradeSubjectEntry _score(String semester, String name, double? score) {
  return GradeSubjectEntry(
    id: StudentGradesRepository.scoreKey(semester, name),
    semesterCode: semester,
    name: name,
    score: score,
    group: GradeSubjectGroup.coreSubjects,
  );
}

void main() {
  group('semesterAverage', () {
    test('returns null for an empty semester — not zero', () {
      expect(semesterAverage([]), isNull);
    });

    test('returns null when every entry is unscored', () {
      final entries = [
        _score(SemesterCode.gr10s1, 'Mathematics', null),
        _score(SemesterCode.gr10s1, 'English', null),
      ];
      expect(semesterAverage(entries), isNull);
    });

    test('averages only the scored entries, ignoring nulls', () {
      final entries = [
        _score(SemesterCode.gr10s1, 'Mathematics', 80),
        _score(SemesterCode.gr10s1, 'English', 90),
        _score(SemesterCode.gr10s1, 'ICT', null), // not yet entered
      ];
      expect(semesterAverage(entries), 85.0);
    });

    test(
        'CLAMP-BYPASS BUG (planning.md §6): an out-of-range manually-typed '
        'score is NOT clamped when averaging — it visibly skews the '
        'result, matching the flow spec\'s "corrupts the Progress & '
        'Feedback average calculation" note', () {
      final entries = [
        _score(SemesterCode.gr10s1, 'Mathematics', 80),
        _score(SemesterCode.gr10s1, 'English', 90),
        _score(SemesterCode.gr10s1, 'Physics', 400), // manually typed, bogus
      ];
      // (80 + 90 + 400) / 3 = 190 — a value that could never occur if the
      // average correctly clamped inputs to 0-100 first. If this test
      // ever starts failing because semesterAverage clamps, that's a sign
      // someone "fixed" the bug without an explicit planning.md decision
      // update — the fix, when it happens, should be a documented stance
      // change, not a silent tweak here.
      expect(semesterAverage(entries), 190.0);
    });

    test('a negative manually-typed score skews the average too', () {
      final entries = [
        _score(SemesterCode.gr10s1, 'Mathematics', 80),
        _score(SemesterCode.gr10s1, 'English', -20),
      ];
      expect(semesterAverage(entries), 30.0);
    });
  });

  group('gradesFeedbackBullets', () {
    List<MapEntry<SemesterInfo, List<GradeSubjectEntry>>> scoresFor(
      Map<String, List<GradeSubjectEntry>> bySemester,
    ) {
      return [
        for (final semester in SemesterInfo.all)
          MapEntry(semester, bySemester[semester.code] ?? const []),
      ];
    }

    test('no semesters filled → the prompt-to-start message only', () {
      final feedback = gradesFeedbackBullets(scoresFor({}));
      expect(feedback.filledAverages, isEmpty);
      expect(feedback.bullets, [
        'Enter your marks for a semester to see your progress and feedback.',
      ]);
    });

    test('exactly one semester filled → "First semester recorded"', () {
      final feedback = gradesFeedbackBullets(scoresFor({
        SemesterCode.gr10s1: [_score(SemesterCode.gr10s1, 'Mathematics', 88)],
      }));
      expect(feedback.filledAverages, hasLength(1));
      expect(feedback.bullets.single, contains('First semester recorded'));
      expect(feedback.bullets.single, contains('88.0'));
    });

    test('a rise of more than 0.5 between the last two filled semesters '
        'reports progress, plus the biggest single-subject improvement',
        () {
      final feedback = gradesFeedbackBullets(scoresFor({
        SemesterCode.gr10s1: [
          _score(SemesterCode.gr10s1, 'Mathematics', 70),
          _score(SemesterCode.gr10s1, 'English', 70),
        ],
        SemesterCode.gr10s2: [
          _score(SemesterCode.gr10s2, 'Mathematics', 90), // +20
          _score(SemesterCode.gr10s2, 'English', 71), // +1
        ],
      }));

      expect(feedback.bullets[0], contains('rose'));
      expect(feedback.bullets.any((b) => b.contains('Mathematics (+20.0)')),
          isTrue);
    });

    test('a drop of more than 0.5 reports a dip, plus the subject most '
        'worth attention', () {
      final feedback = gradesFeedbackBullets(scoresFor({
        SemesterCode.gr10s1: [
          _score(SemesterCode.gr10s1, 'Mathematics', 90),
        ],
        SemesterCode.gr10s2: [
          _score(SemesterCode.gr10s2, 'Mathematics', 70), // -20
        ],
      }));

      expect(feedback.bullets[0], contains('dip'));
      expect(
        feedback.bullets.any((b) => b.contains('Worth attention: Mathematics')),
        isTrue,
      );
    });

    test('a change of 0.5 or less reports steady, not a rise/dip', () {
      final feedback = gradesFeedbackBullets(scoresFor({
        SemesterCode.gr10s1: [_score(SemesterCode.gr10s1, 'Mathematics', 80)],
        SemesterCode.gr10s2: [_score(SemesterCode.gr10s2, 'Mathematics', 80.3)],
      }));
      expect(feedback.bullets[0], contains('steady'));
    });

    test('only subjects scored in BOTH compared semesters count toward '
        'the biggest-improvement/worth-attention bullets', () {
      final feedback = gradesFeedbackBullets(scoresFor({
        SemesterCode.gr10s1: [_score(SemesterCode.gr10s1, 'Mathematics', 70)],
        SemesterCode.gr10s2: [
          _score(SemesterCode.gr10s2, 'Mathematics', 75),
          // Chemistry only exists in S2 — must be ignored in the swing
          // comparison, not treated as "improved from nothing".
          _score(SemesterCode.gr10s2, 'Chemistry', 99),
        ],
      }));
      expect(feedback.bullets.any((b) => b.contains('Chemistry')), isFalse);
    });
  });

  group('GradesController + StudentGradesRepository', () {
    late ProviderContainer container;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(GradeSubjectGroupAdapter());
      registerAdapterIfNeeded(GradeSubjectEntryAdapter());
      registerAdapterIfNeeded(GradeTrackAdapter());
      registerAdapterIfNeeded(StudentGradesSettingsAdapter());
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestHive();
    });

    ProviderContainer buildContainer(
      Box<GradeSubjectEntry> scoresBox,
      Box<StudentGradesSettings> settingsBox,
    ) {
      return ProviderContainer(
        overrides: [
          studentGradesRepositoryProvider.overrideWithValue(
            StudentGradesRepository(scoresBox, settingsBox),
          ),
        ],
      );
    }

    test('defaults to the social track when nothing has been chosen yet — '
        'matches the JS fallback for "no anchor major exists"', () async {
      final scoresBox = await Hive.openBox<GradeSubjectEntry>('grades_ctrl_default_scores');
      final settingsBox =
          await Hive.openBox<StudentGradesSettings>('grades_ctrl_default_settings');
      container = buildContainer(scoresBox, settingsBox);

      expect(container.read(gradesControllerProvider).track, GradeTrack.social);
    });

    test('setTrack persists and updates state', () async {
      final scoresBox = await Hive.openBox<GradeSubjectEntry>('grades_ctrl_track_scores');
      final settingsBox =
          await Hive.openBox<StudentGradesSettings>('grades_ctrl_track_settings');
      container = buildContainer(scoresBox, settingsBox);

      await container.read(gradesControllerProvider.notifier).setTrack(GradeTrack.science);
      expect(container.read(gradesControllerProvider).track, GradeTrack.science);
      expect(settingsBox.values.single.track, GradeTrack.science);
    });

    test('addCustomSubject is a no-op for a blank name or an exact duplicate',
        () async {
      final scoresBox = await Hive.openBox<GradeSubjectEntry>('grades_ctrl_dup_scores');
      final settingsBox =
          await Hive.openBox<StudentGradesSettings>('grades_ctrl_dup_settings');
      container = buildContainer(scoresBox, settingsBox);
      final notifier = container.read(gradesControllerProvider.notifier);

      await notifier.addCustomSubject('Robotics Club');
      await notifier.addCustomSubject('   ');
      await notifier.addCustomSubject('Robotics Club');

      expect(container.read(gradesControllerProvider).customSubjects,
          ['Robotics Club']);
    });

    test('deleteCustomSubject removes the score from every semester at once',
        () async {
      final scoresBox = await Hive.openBox<GradeSubjectEntry>('grades_ctrl_del_scores');
      final settingsBox =
          await Hive.openBox<StudentGradesSettings>('grades_ctrl_del_settings');
      container = buildContainer(scoresBox, settingsBox);
      final repo = StudentGradesRepository(scoresBox, settingsBox);
      final notifier = container.read(gradesControllerProvider.notifier);

      await notifier.addCustomSubject('Robotics Club');
      for (final semester in SemesterInfo.all) {
        await repo.upsertScore(_score(semester.code, 'Robotics Club', 95));
      }
      expect(
        scoresBox.values.where((e) => e.name == 'Robotics Club'),
        hasLength(6),
      );

      await notifier.deleteCustomSubject('Robotics Club');

      expect(container.read(gradesControllerProvider).customSubjects, isEmpty);
      expect(
        scoresBox.values.where((e) => e.name == 'Robotics Club'),
        isEmpty,
      );
    });
  });
}
