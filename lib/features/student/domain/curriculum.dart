import 'grade_subject_entry.dart';
import 'student_grades_settings.dart';

/// Ordered (code, label) pairs for the 6 semester tabs — ported from the
/// JS `SEMS` array. Deliberately kept separate from [SemesterCode] (which
/// only holds the bare codes used as a Hive-entry filter key): this pairs
/// each code with its display label, and JS/site parity for label text
/// ("Gr 10 · S1", not "Grade 10 Semester 1") only matters at the UI layer.
class SemesterInfo {
  const SemesterInfo(this.code, this.label);

  final String code;
  final String label;

  static const all = [
    SemesterInfo(SemesterCode.gr10s1, 'Gr 10 · S1'),
    SemesterInfo(SemesterCode.gr10s2, 'Gr 10 · S2'),
    SemesterInfo(SemesterCode.gr11s1, 'Gr 11 · S1'),
    SemesterInfo(SemesterCode.gr11s2, 'Gr 11 · S2'),
    SemesterInfo(SemesterCode.gr12s1, 'Gr 12 · S1'),
    SemesterInfo(SemesterCode.gr12s2, 'Gr 12 · S2'),
  ];

  /// True for the two Gr 10 tabs — Gr 10 has one shared curriculum for
  /// everyone (see [Curriculum.subjectGroupsFor]), so those two tabs never
  /// show the Science/Social toggle.
  bool get isGrade10 => code.startsWith('gr10');
}

/// One curriculum group ("Core Essentials" etc.) and its fixed subject
/// list for a given grade/track combination.
class SubjectGroup {
  const SubjectGroup(this.group, this.subjects);

  final GradeSubjectGroup group;
  final List<String> subjects;
}

/// Ported 1:1 from the JS `CURRICULUM` object
/// (`day2-trimmed-source.md`) — these exact subject lists weren't in
/// either the field/datatype doc or the behavioral spec (both only named
/// the group headers), so the JS is the sole source for the actual
/// subject names. Deliberately NOT reformatted/reordered from the
/// original — copy fidelity matters more than tidiness here, since
/// there's nothing else to cross-check a "corrected" list against.
class Curriculum {
  Curriculum._();

  static const _grade10 = [
    SubjectGroup(GradeSubjectGroup.coreEssentials, [
      'Religion Studies',
      'Civics | Indonesian Studies',
      'Bahasa Indonesia',
    ]),
    SubjectGroup(GradeSubjectGroup.coreSubjects, [
      'English',
      'Co-ordinated Sciences',
      'Business',
      'Mathematics',
      'ICT',
    ]),
    SubjectGroup(GradeSubjectGroup.coreGeneral, [
      'German / Mandarin',
      'Physical Education',
      'Music',
      'Arts',
      'Theory of Knowledge',
    ]),
  ];

  static const _science = [
    SubjectGroup(GradeSubjectGroup.coreEssentials, [
      'Religion Studies',
      'Civics | Indonesian Studies',
      'Bahasa Indonesia',
    ]),
    SubjectGroup(GradeSubjectGroup.coreSubjects, [
      'English',
      'Biology',
      'Chemistry',
      'Physics',
      'Mathematics',
      'ICT',
    ]),
    SubjectGroup(GradeSubjectGroup.coreGeneral, [
      'German / Mandarin',
      'Physical Education',
      'Music',
      'Arts',
      'Theory of Knowledge',
    ]),
  ];

  static const _social = [
    SubjectGroup(GradeSubjectGroup.coreEssentials, [
      'Religion Studies',
      'Civics | Indonesian Studies',
      'Bahasa Indonesia',
    ]),
    SubjectGroup(GradeSubjectGroup.coreSubjects, [
      'English',
      'Business',
      'Economics',
      'Accounting',
      'Business Mathematics',
      'ICT',
    ]),
    SubjectGroup(GradeSubjectGroup.coreGeneral, [
      'German / Mandarin',
      'Physical Education',
      'Music',
      'Arts',
      'Theory of Knowledge',
    ]),
  ];

  /// Mirrors the JS `curForSem(G, semId, track)`: Gr 10 ignores [track]
  /// entirely (same subjects for everyone, no stream yet), Gr 11/12 use
  /// whichever track is currently selected.
  static List<SubjectGroup> subjectGroupsFor(
    SemesterInfo semester,
    GradeTrack track,
  ) {
    if (semester.isGrade10) return _grade10;
    return track == GradeTrack.science ? _science : _social;
  }
}
