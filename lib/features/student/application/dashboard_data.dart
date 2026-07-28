import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activities_report_controller.dart';
import 'clubs_controller.dart';
import 'portfolio_controller.dart';
import 'tests_controller.dart';
import 'university_targets_controller.dart';
import '../domain/fit_status.dart';
import '../domain/university_catalog.dart';

/// Which of the JS's 4 `fitInner` branches applies. Kept as an enum
/// discriminant + nullable payload fields (matching this codebase's own
/// established style — see `_DocStatus`/`FitTone`) rather than a sealed
/// class, since this is the first place in the app that would need one
/// and a plain discriminant is consistent with everything already here.
enum DashboardFitKind { noTargets, noIelts, found, nonIeltsRoute }

class DashboardFit {
  const DashboardFit._({required this.kind, this.status, this.universityName});

  const DashboardFit.noTargets() : this._(kind: DashboardFitKind.noTargets);
  const DashboardFit.noIelts() : this._(kind: DashboardFitKind.noIelts);
  const DashboardFit.nonIeltsRoute() : this._(kind: DashboardFitKind.nonIeltsRoute);
  const DashboardFit.found({required FitStatus status, required String universityName})
      : this._(kind: DashboardFitKind.found, status: status, universityName: universityName);

  final DashboardFitKind kind;

  /// Only non-null when [kind] is [DashboardFitKind.found].
  final FitStatus? status;

  /// Only non-null when [kind] is [DashboardFitKind.found]. NOTE: the
  /// JS's `f.detail` (an optional extra requirements string) has no
  /// equivalent here — `fit_status.dart`'s `FitStatus` only exposes
  /// `label`/`tier`, never a `detail` field, so this shows label +
  /// university name only. A deliberate gap, not an oversight: adding
  /// `detail` would mean extending `fit_status.dart` itself, which is
  /// out of today's scope.
  final String? universityName;
}

/// Mirrors the JS exactly:
/// ```js
/// const ft=targets.map(t=>{const u=(UNIVERSITIES[t.country]||[])
///   .find(x=>x.n===t.uni);return u&&u.ielts?{t,u}:null;}).filter(Boolean)[0];
/// if(!targets.length)fitInner=...no targets...
/// else if(!sc.ielts)fitInner=...add IELTS...
/// else if(ft){const f=fitStatus(ft.u,sc,ft.t.country);...}
/// else fitInner=...non-IELTS routes...
/// ```
/// [ft] here is the FIRST shortlisted target whose catalog entry both
/// exists AND has a tracked IELTS requirement — not simply the first
/// target overall (a target with no IELTS-requirement match is skipped
/// over, not treated as "no fit data").
final dashboardFitProvider = Provider<DashboardFit>((ref) {
  final targets = ref.watch(universityTargetsControllerProvider);
  if (targets.isEmpty) return const DashboardFit.noTargets();

  final tests = ref.watch(testsControllerProvider);
  final ielts = studentIeltsScore(tests);
  if (ielts == null) return const DashboardFit.noIelts();

  for (final target in targets) {
    final entry = findUniversityEntry(target.country, target.university);
    if (entry != null && entry.ielts != null) {
      final status = fitStatusFor(entry, ielts);
      return DashboardFit.found(status: status, universityName: target.university);
    }
  }

  return const DashboardFit.nonIeltsRoute();
});

/// Bundle for Dashboard's "Activities" panel/mini-stat — three counts
/// combined from three otherwise-unrelated controllers.
class DashboardActivitiesSummary {
  const DashboardActivitiesSummary({
    required this.activityRows,
    required this.clubsCount,
    required this.portfolioWorks,
  });

  /// Rows across Activities Report's sections A/C/D/E/F with a non-blank
  /// `activity` field — mirrors the JS's `actCount` exactly:
  /// `["A","C","D","E","F"].reduce((s,k)=>s+(P[k]||[]).filter(r=>r.act&&
  /// r.act.trim()).length,0)`. A ROW COUNT, not the `hasAnyData` boolean
  /// `StudentActivitiesReport` otherwise exposes.
  final int activityRows;

  /// Distinct clubs actually in the student's confirmed plan — mirrors
  /// the JS's `clubsCount` (`new Set(studentPlan[stu.n].map(p=>p.club))
  /// .length`), simplified to `1 (required club) + rankedOthers.length`
  /// when submitted. This is exact, not an approximation of the JS's own
  /// dedup: `rankedOthers` is already guaranteed duplicate-free by
  /// `ClubRankingController.addClub`'s own guard
  /// (`if(state.contains(club))return false;`), and the required club is
  /// a DIFFERENT club from every ranked one by construction — so the
  /// distinct-club count is exactly this sum, without needing the full
  /// day-by-day schedule-assignment engine `studentPlan` itself is built
  /// from (whether a club runs on 1 day or 3 doesn't change how many
  /// DISTINCT clubs that is).
  final int clubsCount;

  /// Portfolio works with a non-blank title — mirrors the JS's `works`
  /// exactly: `portfolioWorks[stu.n].works.filter(w=>w.title&&w.title
  /// .trim()).length`. Deliberately DIFFERENT from the Application
  /// Materials Hub's own "N works" chip, which is a raw, unfiltered
  /// count (`student_portfolio_hive_test.dart`'s own note on that) — two
  /// different JS call sites read `works.length` differently, and this
  /// preserves that distinction rather than reusing the Hub's number.
  final int portfolioWorks;

  /// Mirrors the JS's `actCount+clubsCount` (used for BOTH the Overview
  /// mini-stat's number and the Activities panel's big number) — [portfolioWorks]
  /// is tracked separately and shown only as supporting detail text, per
  /// the JS's own `${works?' · '+works+' works':''}` — it's not added
  /// into this total.
  int get total => activityRows + clubsCount;
}

final dashboardActivitiesProvider = Provider<DashboardActivitiesSummary>((ref) {
  final report = ref.watch(activitiesReportControllerProvider);
  final submission = ref.watch(clubSubmissionProvider);
  final portfolio = ref.watch(portfolioControllerProvider);

  bool hasText(String? value) => value != null && value.trim().isNotEmpty;

  final activityRows = report.sectionA.where((r) => hasText(r.activity)).length +
      report.sectionC.where((r) => hasText(r.activity)).length +
      report.sectionD.where((r) => hasText(r.activity)).length +
      report.sectionE.where((r) => hasText(r.activity)).length +
      report.sectionF.where((r) => hasText(r.activity)).length;

  final clubsCount = submission != null ? 1 + submission.rankedOthers.length : 0;

  final portfolioWorks = portfolio.works.where((w) => hasText(w.title)).length;

  return DashboardActivitiesSummary(
    activityRows: activityRows,
    clubsCount: clubsCount,
    portfolioWorks: portfolioWorks,
  );
});
