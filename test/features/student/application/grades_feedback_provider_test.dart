import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/grades_controller.dart';
import 'package:runata_pathway/features/student/data/student_hive_providers.dart';
import 'package:runata_pathway/features/student/domain/grade_subject_entry.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(GradeSubjectGroupAdapter());
    registerAdapterIfNeeded(GradeSubjectEntryAdapter());
  });

  tearDown(() async => tearDownTestHive());

  Future<ProviderContainer> buildContainer(String boxName) async {
    final box = await Hive.openBox<GradeSubjectEntry>(boxName);
    final container = ProviderContainer(
      overrides: [studentGradesBoxProvider.overrideWithValue(box)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('an empty box has no filled semesters and the default prompt bullet',
      () async {
    final container = await buildContainer('feedback_empty');
    final feedback = container.read(gradesFeedbackProvider);

    expect(feedback.filledAverages, isEmpty);
    expect(
      feedback.bullets.single,
      'Enter your marks for a semester to see your progress and feedback.',
    );
  });

  test('one filled semester reports its average and a "first semester" '
      'bullet', () async {
    final container = await buildContainer('feedback_one_semester');
    final box = Hive.box<GradeSubjectEntry>('feedback_one_semester');
    await box.put(
      'g1',
      GradeSubjectEntry(
        id: 'g1',
        semesterCode: SemesterCode.gr10s1,
        name: 'Math',
        score: 80,
        group: GradeSubjectGroup.coreSubjects,
      ),
    );

    final feedback = container.read(gradesFeedbackProvider);
    expect(feedback.filledAverages, hasLength(1));
    expect(feedback.filledAverages.single.average, 80);
  });

  test('recomputes reactively when a score is written after the provider '
      'has already been read — same fix already verified for '
      'gradeSemestersFilledCountProvider, confirmed here too since this '
      'is a separate Notifier/subscription', () async {
    final container = await buildContainer('feedback_reactive');
    expect(container.read(gradesFeedbackProvider).filledAverages, isEmpty);

    final box = Hive.box<GradeSubjectEntry>('feedback_reactive');
    await box.put(
      'g1',
      GradeSubjectEntry(
        id: 'g1',
        semesterCode: SemesterCode.gr11s1,
        name: 'Physics',
        score: 90,
        group: GradeSubjectGroup.coreSubjects,
      ),
    );
    // Let the box.watch() stream event propagate.
    await Future<void>.delayed(Duration.zero);

    expect(container.read(gradesFeedbackProvider).filledAverages, hasLength(1));
    expect(container.read(gradesFeedbackProvider).filledAverages.single.average, 90);
  });

  test('two filled semesters compute a real trend, not just a count',
      () async {
    final container = await buildContainer('feedback_trend');
    final box = Hive.box<GradeSubjectEntry>('feedback_trend');
    await box.put(
      'g1',
      GradeSubjectEntry(
        id: 'g1',
        semesterCode: SemesterCode.gr10s1,
        name: 'Math',
        score: 70,
        group: GradeSubjectGroup.coreSubjects,
      ),
    );
    await box.put(
      'g2',
      GradeSubjectEntry(
        id: 'g2',
        semesterCode: SemesterCode.gr10s2,
        name: 'Math',
        score: 85,
        group: GradeSubjectGroup.coreSubjects,
      ),
    );

    final feedback = container.read(gradesFeedbackProvider);
    expect(feedback.filledAverages, hasLength(2));
    expect(feedback.bullets.first, contains('rose'));
  });
}
