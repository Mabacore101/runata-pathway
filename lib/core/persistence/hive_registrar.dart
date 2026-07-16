import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../features/student/domain/grade_subject_entry.dart';
import '../../features/student/domain/student_profile.dart';
import '../../features/student/domain/test_entry.dart';
import 'hive_adapter_registration.dart';
import 'hive_boxes.dart';

/// Registers every @HiveType adapter and opens every box the app needs,
/// up front, before `runApp()`.
///
/// This is the Day 2 Step 0 fix: planning.md's Day 0 checklist claimed
/// this was already done, but direct inspection of the actual code found
/// `main.dart` never called `Hive.initFlutter()` and registered no
/// adapters at all — see day2-codebase-reference.md's "CRITICAL GAP"
/// note. Call this once from `main()`, before `ProviderScope`/`runApp`,
/// since Student's Profile / My Tests / My Grades all read/write their
/// boxes as soon as their screens build.
///
/// typeIds below must stay stable and never be reused for a different
/// type later — Hive persists by typeId, not by class name, so changing
/// one after data has already shipped to a device would corrupt that
/// install's existing data on next read.
///
/// Reserved so far: 0 StudentProfile, 1 TestEntry, 2 TestType,
/// 3 TestStatus, 4 GradeSubjectEntry, 5 GradeSubjectGroup.
/// Next free id for Day 3+ models (Target Universities / My Clubs /
/// Application Materials) is **6** — leave those models as a TODO for
/// their respective days, per planning.md's Day 2 Step 0 scope note; don't
/// build ahead of the forms that use them.
Future<void> initHive() async {
  await Hive.initFlutter();

  registerAdapterIfNeeded(StudentProfileAdapter());
  registerAdapterIfNeeded(TestEntryAdapter());
  registerAdapterIfNeeded(TestTypeAdapter());
  registerAdapterIfNeeded(TestStatusAdapter());
  registerAdapterIfNeeded(GradeSubjectEntryAdapter());
  registerAdapterIfNeeded(GradeSubjectGroupAdapter());

  await Future.wait([
    Hive.openBox<StudentProfile>(HiveBoxes.studentProfile),
    Hive.openBox<TestEntry>(HiveBoxes.studentTests),
    Hive.openBox<GradeSubjectEntry>(HiveBoxes.studentGrades),
  ]);
}
