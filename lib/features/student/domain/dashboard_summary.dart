/// Dashboard's two genuinely computational pieces — everything else on
/// the screen is re-display of data that already exists elsewhere.
/// Deliberately pure, plain Dart (no Riverpod) so both can be unit
/// tested directly against hand-picked boolean combinations, without
/// needing a `ProviderContainer` at all.
library;

/// The 5 possible "next step" destinations — mirrors the JS's `steps`
/// array in `renderDashboard()` exactly, in the same order. Kept as an
/// enum (not the route string directly) so this file stays Riverpod/
/// routing-free; the screen maps each kind to its real `AppRoutes`
/// constant and `onTap` handler.
enum DashboardStepKind { targetUniversities, clubs, tests, grades, materials }

class DashboardNextStep {
  const DashboardNextStep({required this.kind, required this.title});

  final DashboardStepKind kind;
  final String title;
}

/// Mirrors the JS exactly:
/// ```js
/// const done=[targets.length>0,submitted,tests.length>0,gf.avgs.length>0,
///   (actCount>0||clubsCount>0||works>0),matN>0];
/// const dc=done.filter(Boolean).length,pct=Math.round(dc/6*100);
/// ```
/// **Not the same 6 signals as Nav Grid's roadmap** — this swaps
/// `profile` out entirely and adds `hasActivities` (itself a 3-way OR
/// over activity rows / clubs / portfolio works) instead. Two genuinely
/// different "6 things" in the original JS, not one reused everywhere;
/// preserved as two different signatures here rather than collapsing
/// them into one shared shape that would blur that distinction.
int dashboardCompletionPercent({
  required bool hasTargets,
  required bool clubsSubmitted,
  required bool hasTests,
  required bool hasGradeAverages,
  required bool hasActivities,
  required bool materialsStarted,
}) {
  final flags = [
    hasTargets,
    clubsSubmitted,
    hasTests,
    hasGradeAverages,
    hasActivities,
    materialsStarted,
  ];
  final doneCount = flags.where((f) => f).length;
  return (doneCount / flags.length * 100).round();
}

/// Mirrors the JS exactly:
/// ```js
/// const steps=[{go:"unipath",t:"Target universities",done:targets.length>0},
///   {go:"clubs",t:"My clubs",done:submitted},
///   {go:"tests",t:"My tests",done:tests.length>0},
///   {go:"grades",t:"My grades",done:gf.avgs.length>0},
///   {go:"materials",t:"Application materials",done:matN>0}];
/// const next=steps.filter(s=>!s.done).slice(0,3);
/// ```
/// Filters out anything already done, keeping the first 3 remaining IN
/// THE ORIGINAL ORDER — not sorted by any priority, not re-ordered.
/// `profile` is not one of the 5 candidates here either, same as
/// [dashboardCompletionPercent]'s ring.
List<DashboardNextStep> dashboardNextSteps({
  required bool hasTargets,
  required bool clubsSubmitted,
  required bool hasTests,
  required bool hasGradeAverages,
  required bool materialsStarted,
}) {
  final steps = [
    if (!hasTargets)
      const DashboardNextStep(
        kind: DashboardStepKind.targetUniversities,
        title: 'Target universities',
      ),
    if (!clubsSubmitted)
      const DashboardNextStep(kind: DashboardStepKind.clubs, title: 'My clubs'),
    if (!hasTests)
      const DashboardNextStep(kind: DashboardStepKind.tests, title: 'My tests'),
    if (!hasGradeAverages)
      const DashboardNextStep(kind: DashboardStepKind.grades, title: 'My grades'),
    if (!materialsStarted)
      const DashboardNextStep(
        kind: DashboardStepKind.materials,
        title: 'Application materials',
      ),
  ];
  return steps.take(3).toList();
}
