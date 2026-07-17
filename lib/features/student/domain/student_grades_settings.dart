import 'package:hive_ce/hive_ce.dart';

part 'student_grades_settings.g.dart';

/// The Science/Social stream toggle shown only for Gr 11/12 semester tabs
/// (Gr 10 uses one shared curriculum for everyone — see curriculum.dart).
///
/// The JS (`inferTrack()`) tries to auto-derive this from the student's
/// Target Universities anchor major, defaulting to `social` when no
/// anchor major exists yet. Target Universities is Day 3 work — it
/// doesn't exist yet — so that auto-inference has nothing to read from
/// today. [StudentGradesSettings.track] defaults to [GradeTrack.social]
/// for the same reason the JS's fallback does (no anchor major → treated
/// as not-a-science-field), and the student can override it manually via
/// the toggle either way, exactly like the live site allows regardless of
/// how the default got picked. Auto-inference from a real anchor major
/// can be wired in once Day 3 exists — noted here rather than guessed at.
@HiveType(typeId: 7)
enum GradeTrack {
  @HiveField(0)
  science,
  @HiveField(1)
  social,
}

/// Single settings record for My Grades — one per student, same "fixed
/// key in a single-record box" pattern as [StudentProfile].
///
/// `customSubjects` are the "Other" section's student-added subject
/// NAMES only (not their scores). Per the JS (`G.extra`), a custom
/// subject is added ONCE and then appears as an editable row in EVERY
/// semester tab — its actual per-semester SCORES live in
/// [GradeSubjectEntry] records, keyed by (semesterCode, name), same as
/// fixed-curriculum subjects. Deleting a custom subject here removes it
/// from every semester at once (see `StudentGradesRepository.deleteCustomSubject`).
@HiveType(typeId: 8)
class StudentGradesSettings {
  StudentGradesSettings({
    this.track = GradeTrack.social,
    List<String>? customSubjects,
  }) : customSubjects = customSubjects ?? [];

  @HiveField(0)
  GradeTrack track;

  @HiveField(1)
  List<String> customSubjects;
}
