import 'package:hive_ce/hive_ce.dart';

part 'grade_subject_entry.g.dart';

/// Which of My Grades' fixed groups a subject belongs to, or [other] for
/// student-added custom subjects.
///
/// ⚠️ ASSUMPTION FLAGGED, NOT GUESSED PAST: both the field/datatype doc
/// and the flow spec name the three fixed group HEADERS (Core Essentials
/// / Core Subjects / Core General) as always-visible, but neither
/// document lists which actual subjects live inside each group. This enum
/// only fixes the group names; the specific subject list that seeds each
/// group is intentionally left as an open item for whoever builds the My
/// Grades screen itself (Day 2, later step) — don't invent subject names
/// here without confirming them against the live site or client first.
@HiveType(typeId: 5)
enum GradeSubjectGroup {
  @HiveField(0)
  coreEssentials,
  @HiveField(1)
  coreSubjects,
  @HiveField(2)
  coreGeneral,
  @HiveField(3)
  other,
}

/// Canonical semester-tab codes for My Grades' 6 parallel, identical-
/// template tabs. Kept as plain string constants (not a Hive enum) since
/// they're only ever used as a filter tag on
/// [GradeSubjectEntry.semesterCode] — a separate Hive type would be
/// overkill for something that's just a label.
class SemesterCode {
  SemesterCode._();

  static const gr10s1 = 'gr10_s1';
  static const gr10s2 = 'gr10_s2';
  static const gr11s1 = 'gr11_s1';
  static const gr11s2 = 'gr11_s2';
  static const gr12s1 = 'gr12_s1';
  static const gr12s2 = 'gr12_s2';

  static const all = [gr10s1, gr10s2, gr11s1, gr11s2, gr12s1, gr12s2];
}

/// One subject row within one semester tab of My Grades. All rows for all
/// 6 semesters live in a single flat box, filtered by [semesterCode] —
/// mirrors the flat, id-keyed approach used for [TestEntry] rather than
/// nesting a list/map per semester inside one big object.
///
/// `score` is deliberately an unclamped `double?` at the model layer. Per
/// the behavioral spec, the 0–100 (field/datatype doc: "Range from 1 to
/// 100") clamp is a SPINNER-ONLY UI constraint — a manually-typed value
/// can and does exceed it on the live site, and this bug is being
/// knowingly replicated (planning.md §6; confirmed by the flow spec's
/// "Accepted, even if >100 or <0 — NO clamp enforced" node). Enforcing a
/// clamp here would make it structurally impossible to reproduce that
/// bug, so any clamping belongs only in the spinner widget's own
/// increment/decrement logic on the Day 2 form — never in this model.
@HiveType(typeId: 4)
class GradeSubjectEntry {
  GradeSubjectEntry({
    required this.id,
    required this.semesterCode,
    required this.name,
    this.score,
    required this.group,
    this.isCustom = false,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String semesterCode;

  @HiveField(2)
  String name;

  @HiveField(3)
  double? score;

  @HiveField(4)
  GradeSubjectGroup group;

  @HiveField(5)
  bool isCustom;
}
