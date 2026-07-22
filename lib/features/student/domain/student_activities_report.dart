import 'package:hive_ce/hive_ce.dart';

import 'activity_entry.dart';
import 'community_service_entry.dart';

part 'student_activities_report.g.dart';

/// Student Activities Report — Pathway form 6a. One owning record with 5
/// embedded repeatable lists (A, C, D, E, F) — same "owning record with
/// typed `List<T>` fields" shape as `StudentProfile.parents`, not
/// standalone per-section repositories (day5-codebase-reference.md's
/// explicit steer, citing `ParentGuardianEntry` as the closer precedent
/// over `TestEntry`'s flat per-row Hive entries).
///
/// **Section B (Student Organizations) is deliberately absent from this
/// model.** Unlike A/C/D/E/F, Section B is never user-entered — it's
/// recomputed live every time it's shown, from `previewClubWeek` run
/// against the student's persisted `StudentClubSelection` (see
/// `activities_report_controller.dart`'s doc comment for the wiring).
/// Storing a 6th list here would create two sources of truth for the
/// same data that could go stale against each other; the JS's own
/// `portfolios[name]={A:[],C:[],D:[],E:[],F:[]}` already omits B for
/// exactly this reason.
@HiveType(typeId: 15)
class StudentActivitiesReport {
  StudentActivitiesReport({
    List<ActivityEntry>? sectionA,
    List<CommunityServiceEntry>? sectionC,
    List<ActivityEntry>? sectionD,
    List<ActivityEntry>? sectionE,
    List<ActivityEntry>? sectionF,
  })  : sectionA = sectionA ?? [],
        sectionC = sectionC ?? [],
        sectionD = sectionD ?? [],
        sectionE = sectionE ?? [],
        sectionF = sectionF ?? [];

  /// A. Mandatory Grade Level Program
  @HiveField(0)
  List<ActivityEntry> sectionA;

  /// C. Community Services
  @HiveField(1)
  List<CommunityServiceEntry> sectionC;

  /// D. Competitions & School Representative
  @HiveField(2)
  List<ActivityEntry> sectionD;

  /// E. Event Committees
  @HiveField(3)
  List<ActivityEntry> sectionE;

  /// F. School Teams
  @HiveField(4)
  List<ActivityEntry> sectionF;

  /// Drives the Hub's "Started"/"Not started" status chip — mirrors the
  /// JS's `actStarted(n)` exactly: any row across A/C/D/E/F with a
  /// non-blank `activity` field counts. Deliberately checks `activity`
  /// only, even for Section C's richer shape — a row with just a `role`,
  /// `months`, or `proof` filled in but no activity name does NOT count,
  /// same as the JS's `r.act&&r.act.trim()` check.
  bool get hasAnyData =>
      sectionA.any((r) => _hasText(r.activity)) ||
      sectionC.any((r) => _hasText(r.activity)) ||
      sectionD.any((r) => _hasText(r.activity)) ||
      sectionE.any((r) => _hasText(r.activity)) ||
      sectionF.any((r) => _hasText(r.activity));

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
