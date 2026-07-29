import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/fit_chip.dart';
import '../../auth/application/auth_controller.dart';
import '../application/clubs_controller.dart';
import '../application/dashboard_data.dart';
import '../application/grades_controller.dart';
import '../application/materials_progress.dart';
import '../application/tests_controller.dart';
import '../application/university_targets_controller.dart';
import '../domain/application_materials_catalog.dart';
import '../domain/dashboard_summary.dart';
import '../domain/fit_status.dart';
import '../domain/student_grades_settings.dart';
import '../domain/test_entry.dart';
import '../domain/university_target.dart';

/// Day 6 item 7: Dashboard. Mirrors the JS's `renderDashboard()` — a
/// header (avatar, greeting, subtitle, completion ring), a 7-item side
/// menu (Overview/Target/Tests/Fit/Grades/Activities/Materials), and
/// whichever one panel is currently selected.
///
/// **Which panel is showing is ephemeral UI state**, not persisted —
/// same shape as `ApplicationMaterialsScreen`'s `_openDocKey` — so this
/// is a plain `ConsumerStatefulWidget` holding one `DashboardPanel` field,
/// not a Riverpod-tracked selection.
///
/// **All 7 panels are complete** — Overview (6 mini-stats + next-3-steps)
/// plus the 6 detail panels (Target/Tests/Fit/Grades/Activities/
/// Materials), each mirroring its own `panels.<key>` template in the JS
/// verbatim (chip lists, big-number + subtitle layout, the progress bar,
/// and each panel's own "Open X →" button routing to the right screen).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

enum DashboardPanel { overview, target, tests, fit, grades, activities, materials }

class _DashboardMenuItem {
  const _DashboardMenuItem({
    required this.panel,
    required this.icon,
    required this.label,
    required this.accent,
    required this.accentSoft,
  });

  final DashboardPanel panel;
  final String icon;
  final String label;
  final Color accent;
  final Color accentSoft;
}

const _menuItems = <_DashboardMenuItem>[
  _DashboardMenuItem(
    panel: DashboardPanel.overview,
    icon: '🏠',
    label: 'Overview',
    accent: AppColors.teal,
    accentSoft: AppColors.tealSoft,
  ),
  _DashboardMenuItem(
    panel: DashboardPanel.target,
    icon: '🎯',
    label: 'Target unis',
    accent: AppColors.teal,
    accentSoft: AppColors.tealSoft,
  ),
  _DashboardMenuItem(
    panel: DashboardPanel.tests,
    icon: '📝',
    label: 'Tests',
    accent: AppColors.dashPurple,
    accentSoft: AppColors.dashPurpleSoft,
  ),
  _DashboardMenuItem(
    panel: DashboardPanel.fit,
    icon: '🧭',
    label: 'Fit',
    accent: AppColors.orangeDeep,
    accentSoft: AppColors.orangeSoft,
  ),
  _DashboardMenuItem(
    panel: DashboardPanel.grades,
    icon: '📈',
    label: 'Grades',
    accent: AppColors.dashGreen,
    accentSoft: AppColors.dashGreenSoft,
  ),
  _DashboardMenuItem(
    panel: DashboardPanel.activities,
    icon: '🏆',
    label: 'Activities',
    accent: AppColors.dashPink,
    accentSoft: AppColors.dashPinkSoft,
  ),
  _DashboardMenuItem(
    panel: DashboardPanel.materials,
    icon: '📎',
    label: 'Materials',
    accent: AppColors.dashBlue,
    accentSoft: AppColors.dashBlueSoft,
  ),
];

/// `steps[i].kind` → route, kept in the screen layer (not
/// `dashboard_summary.dart`, which is deliberately Riverpod/routing-free).
extension _StepRoute on DashboardStepKind {
  String get route => switch (this) {
        DashboardStepKind.targetUniversities => AppRoutes.studentTargetUniversities,
        DashboardStepKind.clubs => AppRoutes.studentClubs,
        DashboardStepKind.tests => AppRoutes.studentTests,
        DashboardStepKind.grades => AppRoutes.studentGrades,
        DashboardStepKind.materials => AppRoutes.studentMaterials,
      };
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DashboardPanel _panel = DashboardPanel.overview;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final firstName = (session?.name ?? 'Student').split(' ').first;
    final grade = session?.grade;
    final ay = academicYearTabs[defaultAcademicYearIndexForGrade(grade)].id;

    final clubSubmission = ref.watch(clubSubmissionProvider);
    final anchorMajor = clubSubmission?.anchorMajor;
    final gradesSettings = ref.watch(gradesControllerProvider);
    final targets = ref.watch(universityTargetsControllerProvider);
    final tests = ref.watch(testsControllerProvider);
    final ielts = studentIeltsScore(tests);
    final gradesFeedback = ref.watch(gradesFeedbackProvider);
    final activities = ref.watch(dashboardActivitiesProvider);
    final materialsStarted = ref.watch(materialsStartedCountProvider);
    final fit = ref.watch(dashboardFitProvider);

    final streamLabel = ay == 'g10'
        ? 'Grade 10 · no stream yet'
        : (gradesSettings.track == GradeTrack.science ? 'Science stream' : 'Social stream');

    final percent = dashboardCompletionPercent(
      hasTargets: targets.isNotEmpty,
      clubsSubmitted: clubSubmission != null,
      hasTests: tests.isNotEmpty,
      hasGradeAverages: gradesFeedback.filledAverages.isNotEmpty,
      hasActivities: activities.total > 0 || activities.portfolioWorks > 0,
      materialsStarted: materialsStarted > 0,
    );
    final nextSteps = dashboardNextSteps(
      hasTargets: targets.isNotEmpty,
      clubsSubmitted: clubSubmission != null,
      hasTests: tests.isNotEmpty,
      hasGradeAverages: gradesFeedback.filledAverages.isNotEmpty,
      materialsStarted: materialsStarted > 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DashboardHero(
              firstName: firstName,
              anchorMajor: anchorMajor,
              streamLabel: streamLabel,
              percent: percent,
            ),
            const SizedBox(height: 16),
            _DashboardSideMenu(
              selected: _panel,
              onSelect: (panel) => setState(() => _panel = panel),
            ),
            const SizedBox(height: 12),
            _buildPanel(
              targets: targets,
              tests: tests,
              gradesFeedback: gradesFeedback,
              activities: activities,
              materialsStarted: materialsStarted,
              fit: fit,
              ielts: ielts,
              nextSteps: nextSteps,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('dashboard_back_to_home'),
                onPressed: () => context.go(AppRoutes.studentHome),
                child: const Text('← Back to home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({
    required List<UniversityTarget> targets,
    required List<TestEntry> tests,
    required GradesFeedback gradesFeedback,
    required DashboardActivitiesSummary activities,
    required int materialsStarted,
    required DashboardFit fit,
    required double? ielts,
    required List<DashboardNextStep> nextSteps,
  }) {
    switch (_panel) {
      case DashboardPanel.overview:
        return _OverviewPanel(
          targetsCount: targets.length,
          testsCount: tests.length,
          lastAverage: gradesFeedback.filledAverages.isEmpty
              ? null
              : gradesFeedback.filledAverages.last.average,
          activitiesTotal: activities.total,
          materialsStarted: materialsStarted,
          hasFitData: targets.isNotEmpty && ielts != null,
          nextSteps: nextSteps,
          onOpenStep: (kind) => context.push(kind.route),
          onSelectPanel: (panel) => setState(() => _panel = panel),
        );
      case DashboardPanel.target:
        return _TargetPanel(targets: targets, onOpen: () => context.push(AppRoutes.studentTargetUniversities));
      case DashboardPanel.tests:
        return _TestsPanel(tests: tests, onOpen: () => context.push(AppRoutes.studentTests));
      case DashboardPanel.fit:
        return _FitPanel(fit: fit, onOpen: () => context.push(AppRoutes.studentTargetUniversities));
      case DashboardPanel.grades:
        return _GradesPanel(feedback: gradesFeedback, onOpen: () => context.push(AppRoutes.studentGrades));
      case DashboardPanel.activities:
        return _ActivitiesPanel(summary: activities, onOpen: () => context.push(AppRoutes.studentMaterials));
      case DashboardPanel.materials:
        return _MaterialsPanel(started: materialsStarted, onOpen: () => context.push(AppRoutes.studentMaterials));
    }
  }
}

/// `.dhero2` equivalent — avatar, greeting, subtitle, completion ring.
class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.firstName,
    required this.anchorMajor,
    required this.streamLabel,
    required this.percent,
  });

  final String firstName;
  final String? anchorMajor;
  final String streamLabel;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '🙂';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.tealDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppFonts.display(fontSize: 18, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hey $firstName 👋',
                  style: AppFonts.display(fontSize: 16, weight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  '${anchorMajor ?? 'major not set'} · $streamLabel',
                  style: AppFonts.body(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          _CompletionRing(percent: percent),
        ],
      ),
    );
  }
}

/// `.dring`/the SVG ring equivalent — a track circle + a progress arc
/// starting at 12 o'clock, matching the JS's `stroke-dasharray`/
/// `stroke-dashoffset`/`rotate(-90 37 37)` combination exactly.
class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 74,
          height: 74,
          child: CustomPaint(
            painter: _CompletionRingPainter(percent: percent),
            child: Center(
              child: Text(
                '$percent%',
                style: AppFonts.mono(fontSize: 17, weight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'complete',
          style: AppFonts.body(fontSize: 10, color: Colors.white.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _CompletionRingPainter extends CustomPainter {
  _CompletionRingPainter({required this.percent});
  final int percent;

  static const _strokeWidth = 7.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (percent > 0) {
      final progressPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweep = 2 * math.pi * (percent.clamp(0, 100) / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) =>
      oldDelegate.percent != percent;
}

/// `.dside` equivalent — 7 buttons, one highlighted (`on`).
class _DashboardSideMenu extends StatelessWidget {
  const _DashboardSideMenu({required this.selected, required this.onSelect});

  final DashboardPanel selected;
  final ValueChanged<DashboardPanel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in _menuItems)
          _MenuButton(
            key: Key('dashboard_menu_${item.panel.name}'),
            item: item,
            selected: item.panel == selected,
            onTap: () => onSelect(item.panel),
          ),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({super.key, required this.item, required this.selected, required this.onTap});

  final _DashboardMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? item.accent : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? item.accent : AppColors.line, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.25) : item.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(item.icon, style: const TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: AppFonts.body(
                  weight: FontWeight.w700,
                  fontSize: 12.5,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Overview panel — 6 mini-stats + "your next steps" queue.
class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.targetsCount,
    required this.testsCount,
    required this.lastAverage,
    required this.activitiesTotal,
    required this.materialsStarted,
    required this.hasFitData,
    required this.nextSteps,
    required this.onOpenStep,
    required this.onSelectPanel,
  });

  final int targetsCount;
  final int testsCount;
  final double? lastAverage;
  final int activitiesTotal;
  final int materialsStarted;
  final bool hasFitData;
  final List<DashboardNextStep> nextSteps;
  final ValueChanged<DashboardStepKind> onOpenStep;

  /// Mirrors the JS's shared `[data-dv]` click handler — every mini-stat
  /// tile carries the same `data-dv` attribute the side-menu buttons do,
  /// so tapping one is a shortcut to that same detail panel, not just a
  /// static number.
  final ValueChanged<DashboardPanel> onSelectPanel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppFonts.display(fontSize: 16, color: AppColors.ink)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _MiniStat(
                key: const Key('dashboard_mini_stat_target'),
                icon: '🎯',
                value: '$targetsCount',
                label: 'Target unis',
                accent: AppColors.teal,
                onTap: () => onSelectPanel(DashboardPanel.target),
              ),
              _MiniStat(
                key: const Key('dashboard_mini_stat_tests'),
                icon: '📝',
                value: '$testsCount',
                label: 'Tests',
                accent: AppColors.dashPurple,
                onTap: () => onSelectPanel(DashboardPanel.tests),
              ),
              _MiniStat(
                key: const Key('dashboard_mini_stat_grades'),
                icon: '📈',
                value: lastAverage?.toStringAsFixed(1) ?? '—',
                label: 'Latest avg',
                accent: AppColors.dashGreen,
                onTap: () => onSelectPanel(DashboardPanel.grades),
              ),
              _MiniStat(
                key: const Key('dashboard_mini_stat_activities'),
                icon: '🏆',
                value: '$activitiesTotal',
                label: 'Activities',
                accent: AppColors.dashPink,
                onTap: () => onSelectPanel(DashboardPanel.activities),
              ),
              _MiniStat(
                key: const Key('dashboard_mini_stat_materials'),
                icon: '📎',
                value: '$materialsStarted/${materialDocs.length}',
                label: 'Materials',
                accent: AppColors.dashBlue,
                onTap: () => onSelectPanel(DashboardPanel.materials),
              ),
              _MiniStat(
                key: const Key('dashboard_mini_stat_fit'),
                icon: '🧭',
                value: hasFitData ? '✓' : '–',
                label: 'Fit',
                accent: AppColors.orangeDeep,
                onTap: () => onSelectPanel(DashboardPanel.fit),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'YOUR NEXT STEPS',
            style: AppFonts.mono(fontSize: 10, color: AppColors.muted, letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          if (nextSteps.isEmpty)
            Container(
              key: const Key('dashboard_next_steps_all_done'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'All core steps done — keep refining. 🎉',
                style: AppFonts.body(fontSize: 13, color: AppColors.muted),
              ),
            )
          else
            for (final step in nextSteps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _NextStepButton(step: step, onTap: () => onOpenStep(step.kind)),
              ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String icon;
  final String value;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The `.dmini{border-top:4px solid var(--ac)}` accent —
                // kept as a separate strip, not part of the Border above,
                // since Flutter's BoxDecoration doesn't allow a borderRadius
                // when a Border's sides have different colors (this one did:
                // accent on top, line color on the other 3).
                Container(height: 4, color: accent),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppFonts.display(fontSize: 20, weight: FontWeight.w800, color: accent),
                      ),
                      Text(
                        label,
                        style: AppFonts.body(
                          fontSize: 10.5,
                          weight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStepButton extends StatelessWidget {
  const _NextStepButton({required this.step, required this.onTap});
  final DashboardNextStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: Key('dashboard_next_step_${step.kind.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: AppFonts.body(weight: FontWeight.w600, fontSize: 13, color: AppColors.ink),
                ),
              ),
              Text(
                'GO →',
                style: AppFonts.mono(
                  fontSize: 10,
                  weight: FontWeight.w700,
                  color: AppColors.tealDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.dpTitle` equivalent — shared by every detail panel.
class _PanelTitle extends StatelessWidget {
  const _PanelTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: AppFonts.display(fontSize: 20, weight: FontWeight.w800, color: AppColors.ink)),
    );
  }
}

/// The card wrapper every detail panel shares (same shape as the
/// Overview panel's own outer Container).
class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [child]),
    );
  }
}

/// `.dbig` equivalent — a big colored number/value with a muted subtitle
/// underneath, in the panel's own accent color.
class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.subtitle, required this.accent});
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppFonts.display(fontSize: 40, weight: FontWeight.w800, color: accent)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppFonts.body(fontSize: 12.5, weight: FontWeight.w600, color: AppColors.muted)),
        ],
      ),
    );
  }
}

/// `.dgoBtn` equivalent — every detail panel's own "Open X →" button.
class _GoButton extends StatelessWidget {
  const _GoButton({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onTap, child: Text(label))),
    );
  }
}

/// `.dchip` equivalent.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.accent, required this.accentSoft});
  final String label;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(color: accentSoft, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppFonts.body(fontSize: 11, weight: FontWeight.w700, color: accent),
      ),
    );
  }
}

/// "Target universities" detail panel.
class _TargetPanel extends StatelessWidget {
  const _TargetPanel({required this.targets, required this.onOpen});
  final List<UniversityTarget> targets;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.teal;
    const accentSoft = AppColors.tealSoft;
    final shown = targets.take(8).toList();
    final extra = targets.length - shown.length;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Target universities'),
          _BigStat(value: '${targets.length}', subtitle: 'on your list', accent: accent),
          if (targets.isEmpty)
            Text('No targets yet.', style: AppFonts.body(fontSize: 11.5, color: AppColors.muted))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in shown) _Chip(label: t.university, accent: accent, accentSoft: accentSoft),
                if (extra > 0) _Chip(label: '+$extra', accent: accent, accentSoft: accentSoft),
              ],
            ),
          _GoButton(
            key: const Key('dashboard_panel_open_target'),
            label: 'Open Target universities →',
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

/// `TestType` → display label — mirrors how test types read elsewhere in
/// this app (e.g. Nav Grid's roadmap description: "IELTS, CSCA, SAT").
String _testTypeLabel(TestType type) => switch (type) {
      TestType.ielts => 'IELTS',
      TestType.toefl => 'TOEFL',
      TestType.duolingo => 'Duolingo',
      TestType.sat => 'SAT',
      TestType.csca => 'CSCA',
      TestType.hsk => 'HSK',
      TestType.ap => 'AP',
      TestType.other => 'Other',
    };

/// "My tests" detail panel.
class _TestsPanel extends StatelessWidget {
  const _TestsPanel({required this.tests, required this.onOpen});
  final List<TestEntry> tests;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.dashPurple;
    const accentSoft = AppColors.dashPurpleSoft;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('My tests'),
          _BigStat(value: '${tests.length}', subtitle: 'added', accent: accent),
          if (tests.isEmpty)
            Text('None added yet.', style: AppFonts.body(fontSize: 11.5, color: AppColors.muted))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in tests)
                  _Chip(
                    label:
                        '${_testTypeLabel(t.type)}${(t.latest != null && t.latest!.trim().isNotEmpty) ? ' ${t.latest}' : ''}',
                    accent: accent,
                    accentSoft: accentSoft,
                  ),
              ],
            ),
          _GoButton(key: const Key('dashboard_panel_open_tests'), label: 'Open My tests →', onTap: onOpen),
        ],
      ),
    );
  }
}

/// Maps `FitTier` (fit_status.dart) → `FitTone` (the shared chip widget)
/// — both enums have identically-named values, so this is a direct
/// 1:1 mapping, not a judgment call.
FitTone _fitTierToTone(FitTier tier) => switch (tier) {
      FitTier.met => FitTone.met,
      FitTier.track => FitTone.track,
      FitTier.work => FitTone.work,
      FitTier.none => FitTone.none,
    };

/// "Fit" detail panel — mirrors the same 4 `fitInner` branches
/// `dashboardFitProvider` already computes.
class _FitPanel extends StatelessWidget {
  const _FitPanel({required this.fit, required this.onOpen});
  final DashboardFit fit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = AppFonts.body(fontSize: 12.5, color: AppColors.muted, height: 1.4);

    Widget body;
    switch (fit.kind) {
      case DashboardFitKind.noTargets:
        body = Text('Pick a target university first.', style: mutedStyle);
      case DashboardFitKind.noIelts:
        body = RichText(
          text: TextSpan(
            style: mutedStyle,
            children: [
              const TextSpan(text: 'Add your '),
              TextSpan(text: 'IELTS', style: mutedStyle.copyWith(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' in My tests to unlock fit.'),
            ],
          ),
        );
      case DashboardFitKind.found:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FitChip(label: fit.status!.label, tone: _fitTierToTone(fit.status!.tier)),
            const SizedBox(height: 6),
            Text(fit.universityName!, style: mutedStyle),
          ],
        );
      case DashboardFitKind.nonIeltsRoute:
        body = Text(
          'Your targets use non-IELTS routes (e.g. rapor / UTBK / HSK).',
          style: mutedStyle,
        );
    }

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Fit'),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: body),
          _GoButton(
            key: const Key('dashboard_panel_open_fit'),
            label: 'Open Target universities →',
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

/// "My grades" detail panel.
class _GradesPanel extends StatelessWidget {
  const _GradesPanel({required this.feedback, required this.onOpen});
  final GradesFeedback feedback;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.dashGreen;
    final avgs = feedback.filledAverages;

    Widget content;
    if (avgs.isEmpty) {
      content = Text(
        'Record your marks after each report.',
        style: AppFonts.body(fontSize: 11.5, color: AppColors.muted),
      );
    } else {
      final last = avgs.last.average;
      final trendText = avgs.length >= 2
          ? (last > avgs[avgs.length - 2].average + 0.5
              ? '↑'
              : last < avgs[avgs.length - 2].average - 0.5
                  ? '↓'
                  : '→')
          : '';
      final trendColor = trendText == '↑'
          ? AppColors.green
          : trendText == '↓'
              ? AppColors.amber
              : accent;

      content = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  last.toStringAsFixed(1),
                  style: AppFonts.display(fontSize: 40, weight: FontWeight.w800, color: accent),
                ),
                if (trendText.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      trendText,
                      style: AppFonts.display(fontSize: 22, weight: FontWeight.w800, color: trendColor),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'latest · ${avgs.length} semester${avgs.length > 1 ? 's' : ''}',
              style: AppFonts.body(fontSize: 12.5, weight: FontWeight.w600, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('My grades'),
          content,
          _GoButton(key: const Key('dashboard_panel_open_grades'), label: 'Open My grades →', onTap: onOpen),
        ],
      ),
    );
  }
}

/// "Activities" detail panel.
class _ActivitiesPanel extends StatelessWidget {
  const _ActivitiesPanel({required this.summary, required this.onOpen});
  final DashboardActivitiesSummary summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.dashPink;
    final worksSuffix = summary.portfolioWorks > 0 ? ' · ${summary.portfolioWorks} works' : '';
    final subtitle =
        '${summary.clubsCount} club${summary.clubsCount != 1 ? 's' : ''} · ${summary.activityRows} entries$worksSuffix';

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Activities'),
          _BigStat(value: '${summary.total}', subtitle: subtitle, accent: accent),
          _GoButton(
            key: const Key('dashboard_panel_open_activities'),
            label: 'Open activities →',
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}

/// "Application materials" detail panel.
class _MaterialsPanel extends StatelessWidget {
  const _MaterialsPanel({required this.started, required this.onOpen});
  final int started;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.dashBlue;
    final total = materialDocs.length;
    final pct = total > 0 ? (started / total * 100).round() : 0;

    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle('Application materials'),
          _BigStat(value: '$started', subtitle: '/ $total started', accent: accent),
          SizedBox(
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 10,
                color: AppColors.surface2,
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct / 100,
                  child: Container(
                    key: const Key('dashboard_materials_progress_bar'),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.teal, AppColors.orange]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _GoButton(
            key: const Key('dashboard_panel_open_materials'),
            label: 'Open materials →',
            onTap: onOpen,
          ),
        ],
      ),
    );
  }
}