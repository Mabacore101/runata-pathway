import 'package:flutter_test/flutter_test.dart';

import 'package:runata_pathway/features/student/domain/dashboard_summary.dart';

void main() {
  group('dashboardCompletionPercent', () {
    test('0 of 6 done is 0%', () {
      expect(
        dashboardCompletionPercent(
          hasTargets: false,
          clubsSubmitted: false,
          hasTests: false,
          hasGradeAverages: false,
          hasActivities: false,
          materialsStarted: false,
        ),
        0,
      );
    });

    test('6 of 6 done is 100%', () {
      expect(
        dashboardCompletionPercent(
          hasTargets: true,
          clubsSubmitted: true,
          hasTests: true,
          hasGradeAverages: true,
          hasActivities: true,
          materialsStarted: true,
        ),
        100,
      );
    });

    test('3 of 6 done is exactly 50%', () {
      expect(
        dashboardCompletionPercent(
          hasTargets: true,
          clubsSubmitted: true,
          hasTests: true,
          hasGradeAverages: false,
          hasActivities: false,
          materialsStarted: false,
        ),
        50,
      );
    });

    test('1 of 6 done rounds 16.66...% to 17%, matching JS\'s Math.round',
        () {
      expect(
        dashboardCompletionPercent(
          hasTargets: true,
          clubsSubmitted: false,
          hasTests: false,
          hasGradeAverages: false,
          hasActivities: false,
          materialsStarted: false,
        ),
        17,
      );
    });

    test('2 of 6 done rounds 33.33...% down to 33%', () {
      expect(
        dashboardCompletionPercent(
          hasTargets: true,
          clubsSubmitted: true,
          hasTests: false,
          hasGradeAverages: false,
          hasActivities: false,
          materialsStarted: false,
        ),
        33,
      );
    });

    test('5 of 6 done rounds 83.33...% to 83%', () {
      expect(
        dashboardCompletionPercent(
          hasTargets: true,
          clubsSubmitted: true,
          hasTests: true,
          hasGradeAverages: true,
          hasActivities: true,
          materialsStarted: false,
        ),
        83,
      );
    });

    test('which specific 3 of 6 are done doesn\'t matter — only the count '
        'does', () {
      final a = dashboardCompletionPercent(
        hasTargets: true,
        clubsSubmitted: true,
        hasTests: true,
        hasGradeAverages: false,
        hasActivities: false,
        materialsStarted: false,
      );
      final b = dashboardCompletionPercent(
        hasTargets: false,
        clubsSubmitted: false,
        hasTests: false,
        hasGradeAverages: true,
        hasActivities: true,
        materialsStarted: true,
      );
      expect(a, b);
      expect(a, 50);
    });
  });

  group('dashboardNextSteps', () {
    test('nothing done returns all 5, in original order', () {
      final steps = dashboardNextSteps(
        hasTargets: false,
        clubsSubmitted: false,
        hasTests: false,
        hasGradeAverages: false,
        materialsStarted: false,
      );

      // Only the first 3 are actually returned (capped), but they must
      // be the FIRST 3 in the JS's declared order.
      expect(steps, hasLength(3));
      expect(steps[0].kind, DashboardStepKind.targetUniversities);
      expect(steps[1].kind, DashboardStepKind.clubs);
      expect(steps[2].kind, DashboardStepKind.tests);
    });

    test('done steps are filtered out, not just skipped visually — the '
        'next 3 are whatever remains, still in order', () {
      final steps = dashboardNextSteps(
        hasTargets: true, // done — excluded
        clubsSubmitted: false,
        hasTests: true, // done — excluded
        hasGradeAverages: false,
        materialsStarted: false,
      );

      expect(steps, hasLength(3));
      expect(steps[0].kind, DashboardStepKind.clubs);
      expect(steps[1].kind, DashboardStepKind.grades);
      expect(steps[2].kind, DashboardStepKind.materials);
    });

    test('exactly 3 remaining returns all 3, no padding/truncation issue',
        () {
      final steps = dashboardNextSteps(
        hasTargets: true,
        clubsSubmitted: true,
        hasTests: false,
        hasGradeAverages: false,
        materialsStarted: false,
      );

      expect(steps, hasLength(3));
      expect(steps[0].kind, DashboardStepKind.tests);
      expect(steps[1].kind, DashboardStepKind.grades);
      expect(steps[2].kind, DashboardStepKind.materials);
    });

    test('more than 3 remaining is capped at 3, dropping the rest — not '
        'just the ones checked above', () {
      final steps = dashboardNextSteps(
        hasTargets: false,
        clubsSubmitted: false,
        hasTests: false,
        hasGradeAverages: false,
        materialsStarted: false,
      );

      expect(steps, hasLength(3));
      // materials (the 5th/last candidate) must NOT appear — it's
      // beyond the cap of 3.
      expect(steps.any((s) => s.kind == DashboardStepKind.materials), isFalse);
    });

    test('everything done returns an empty list, not a placeholder entry',
        () {
      final steps = dashboardNextSteps(
        hasTargets: true,
        clubsSubmitted: true,
        hasTests: true,
        hasGradeAverages: true,
        materialsStarted: true,
      );

      expect(steps, isEmpty);
    });

    test('each step carries its own display title', () {
      final steps = dashboardNextSteps(
        hasTargets: false,
        clubsSubmitted: true,
        hasTests: true,
        hasGradeAverages: true,
        materialsStarted: true,
      );

      expect(steps, hasLength(1));
      expect(steps.single.title, 'Target universities');
    });
  });
}