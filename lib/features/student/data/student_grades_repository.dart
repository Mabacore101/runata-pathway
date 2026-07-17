import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/curriculum.dart';
import '../domain/grade_subject_entry.dart';
import '../domain/student_grades_settings.dart';
import 'student_hive_providers.dart';

/// Wraps two boxes:
/// - [_scoresBox] — one [GradeSubjectEntry] per (semester, subject) pair,
///   keyed by a deterministic composite key (see [scoreKey]) rather than a
///   random id. Re-saving the same subject in the same semester just
///   overwrites its existing entry instead of accumulating duplicates.
///   The box is deliberately SPARSE: a subject with no score entered yet
///   simply has no row here at all — nothing gets pre-created just
///   because a subject exists in the curriculum, matching the JS's
///   `G.marks[sem]` being a plain sparse object.
/// - [_settingsBox] — single [StudentGradesSettings] record (track choice
///   + custom subject names), same "fixed key" pattern as
///   [StudentProfile].
class StudentGradesRepository {
  StudentGradesRepository(this._scoresBox, this._settingsBox);

  final Box<GradeSubjectEntry> _scoresBox;
  final Box<StudentGradesSettings> _settingsBox;

  static String scoreKey(String semesterCode, String subjectName) =>
      '$semesterCode::$subjectName';

  List<GradeSubjectEntry> scoresForSemester(String semesterCode) {
    return _scoresBox.values
        .where((e) => e.semesterCode == semesterCode)
        .toList();
  }

  Future<void> upsertScore(GradeSubjectEntry entry) {
    return _scoresBox.put(scoreKey(entry.semesterCode, entry.name), entry);
  }

  /// Deletes a subject's score in every one of the 6 semesters at once —
  /// used when a custom subject is removed entirely (see
  /// `GradesController.deleteCustomSubject`), mirroring the JS's `G.extra`
  /// being a single global list rather than a per-semester one. Missing
  /// entries (a semester the student never scored) are silently skipped.
  Future<void> deleteScoreEverywhere(String subjectName) async {
    for (final semester in SemesterInfo.all) {
      final key = scoreKey(semester.code, subjectName);
      if (_scoresBox.containsKey(key)) {
        await _scoresBox.delete(key);
      }
    }
  }

  StudentGradesSettings loadSettings() {
    return _settingsBox.get(HiveKeys.studentGradesSettings) ??
        StudentGradesSettings();
  }

  Future<void> saveSettings(StudentGradesSettings settings) {
    return _settingsBox.put(HiveKeys.studentGradesSettings, settings);
  }
}

final studentGradesRepositoryProvider =
    Provider<StudentGradesRepository>((ref) {
  final scoresBox = ref.watch(studentGradesBoxProvider);
  final settingsBox = ref.watch(studentGradesSettingsBoxProvider);
  return StudentGradesRepository(scoresBox, settingsBox);
});
