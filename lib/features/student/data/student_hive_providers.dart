import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/grade_subject_entry.dart';
import '../domain/student_grades_settings.dart';
import '../domain/student_majors_settings.dart';
import '../domain/student_profile.dart';
import '../domain/test_entry.dart';

/// Box access providers — thin wrappers around boxes already opened by
/// `initHive()` in `main.dart` (before `ProviderScope` even exists, so
/// these providers can't open the boxes themselves; they just expose the
/// already-open instances).
///
/// Repository/controller classes built for each form screen should depend
/// on these rather than calling `Hive.box<T>(...)` directly at scattered
/// call sites — this keeps every box-name reference in one place (see
/// [HiveBoxes]) and makes each box swappable for a `hive_ce_test`-backed
/// fake in widget tests via `ProviderScope` overrides, the same way
/// `studentAuthRepositoryProvider` gets overridden in the existing auth
/// tests. These are plain `Provider`s, not `Notifier`/`NotifierProvider`s,
/// on purpose — a box handle itself has no mutable app state to notify
/// listeners about; any controller that reads from one of these and needs
/// to notify the UI of changes should still follow the modern `Notifier`
/// pattern from `auth_controller.dart`.
final studentProfileBoxProvider = Provider<Box<StudentProfile>>((ref) {
  return Hive.box<StudentProfile>(HiveBoxes.studentProfile);
});

final studentTestsBoxProvider = Provider<Box<TestEntry>>((ref) {
  return Hive.box<TestEntry>(HiveBoxes.studentTests);
});

final studentGradesBoxProvider = Provider<Box<GradeSubjectEntry>>((ref) {
  return Hive.box<GradeSubjectEntry>(HiveBoxes.studentGrades);
});

final studentGradesSettingsBoxProvider =
    Provider<Box<StudentGradesSettings>>((ref) {
  return Hive.box<StudentGradesSettings>(HiveBoxes.studentGradesSettings);
});

/// Explore Majors' single-record box (see [StudentMajorsSettings]) — same
/// role as [studentGradesSettingsBoxProvider]: one fixed-key record per
/// student rather than a natural collection.
final studentMajorsSettingsBoxProvider =
    Provider<Box<StudentMajorsSettings>>((ref) {
  return Hive.box<StudentMajorsSettings>(HiveBoxes.studentMajors);
});