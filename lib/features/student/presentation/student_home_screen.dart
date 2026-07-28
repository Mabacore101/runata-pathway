import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/clubs_controller.dart';
import '../application/counsellor_corner_controller.dart';
import '../application/grades_controller.dart';
import '../application/materials_progress.dart';
import '../application/profile_controller.dart';
import '../application/tests_controller.dart';
import '../application/university_targets_controller.dart';
import '../domain/application_materials_catalog.dart';

/// Day 6 item 6: the real homepage, replacing Day 1's 3-card
/// placeholder now that all 6 Pathway forms + Counsellor's Corner +
/// Pathways exist. Extends this SAME file/class rather than a new
/// screen — see the (now superseded) Day 1 scope note this doc comment
/// replaces.
///
/// Three pieces, top to bottom, matching the JS's `renderHome()`
/// exactly (the Parent-mode branch is out of scope — no Parent role
/// exists in this rebuild):
/// 1. The "My dashboard" CTA (`.dashcta`) — links to Dashboard, still a
///    stub until item 7.
/// 2. The 6-step roadmap card (`.roadcard`/`.rstep`) — done/next/later
///    computed fresh every build from every prior day's own state.
/// 3. The full 8-tile Nav Grid (`.home`) + Sign out.
///
/// **The JS's `locked` banner (Academic Coordinator lock) is
/// deliberately omitted** — it depends on a Staff-side lock action that
/// has no equivalent anywhere in this Student-only rebuild, same
/// reasoning every other Staff-dependent JS branch has been dropped
/// throughout this project (e.g. `renderHome()`'s own Parent-mode
/// branch, right above this one in source).
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final firstName = (session?.name ?? 'Student').split(' ').first;

    // ---- Every roadmap/tile "done"/count signal, read once up top ----
    final profile = ref.watch(profileControllerProvider).profile;
    final targets = ref.watch(universityTargetsControllerProvider);
    final clubSubmission = ref.watch(clubSubmissionProvider);
    final tests = ref.watch(testsControllerProvider);
    final gradeSemestersFilled = ref.watch(gradeSemestersFilledCountProvider);
    final materialsStarted = ref.watch(materialsStartedCountProvider);
    final counsellorCorner = ref.watch(counsellorCornerControllerProvider);

    final profileDone = profile.hasAnyData;
    final targetsDone = targets.isNotEmpty;
    final clubsDone = clubSubmission != null;
    final testsDone = tests.isNotEmpty;
    final gradesDone = gradeSemestersFilled > 0;
    final materialsDone = materialsStarted > 0;

    final steps = <_RoadmapStep>[
      _RoadmapStep(
        route: AppRoutes.studentProfile,
        title: "Student's Profile",
        description: 'Your personal, family & medical details',
        done: profileDone,
      ),
      _RoadmapStep(
        route: AppRoutes.studentTargetUniversities,
        title: 'Target universities',
        description: 'Read majors, see requirements, shortlist unis',
        done: targetsDone,
      ),
      _RoadmapStep(
        route: AppRoutes.studentClubs,
        title: 'My clubs',
        description: 'Lock your anchor major → required club',
        done: clubsDone,
      ),
      _RoadmapStep(
        route: AppRoutes.studentTests,
        title: 'My tests',
        description: 'IELTS, CSCA, SAT — only what you take',
        done: testsDone,
      ),
      _RoadmapStep(
        route: AppRoutes.studentGrades,
        title: 'My grades',
        description: 'Input marks after each semester report',
        done: gradesDone,
      ),
      _RoadmapStep(
        route: AppRoutes.studentMaterials,
        title: 'Application materials',
        description: 'Statement, study plan, CV, portfolio',
        done: materialsDone,
      ),
    ];
    final statuses = _computeRoadmapStatuses(steps);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runata Pathway'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Hi $firstName 👋',
                    style: AppFonts.display(fontSize: 22, color: AppColors.ink),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Your Runata clubs & university pathway — follow the '
                    'steps below, or jump to any section.',
                    style: AppFonts.body(fontSize: 13, color: AppColors.muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DashboardCta(onTap: () => context.push(AppRoutes.studentDashboard)),
            const SizedBox(height: 16),
            _RoadmapCard(steps: steps, statuses: statuses),
            const SizedBox(height: 16),
            _NavGrid(
              clubsDone: clubsDone,
              targetsCount: targets.length,
              materialsStarted: materialsStarted,
              testsCount: tests.length,
              gradeSemestersFilled: gradeSemestersFilled,
              profileDone: profileDone,
              counsellorCornerDone: counsellorCorner.hasAnyData,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('home_sign_out'),
                onPressed: () => _signOut(context, ref),
                child: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut(BuildContext context, WidgetRef ref) {
    ref.read(authControllerProvider.notifier).signOut();
    context.go(AppRoutes.chooseRole);
  }
}

/// `.dashcta` equivalent.
class _DashboardCta extends StatelessWidget {
  const _DashboardCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home_dashboard_cta'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.teal, AppColors.tealDeep, AppColors.orange],
              stops: [0, 0.6, 1],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: const Text('✨', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My dashboard',
                      style: AppFonts.display(
                        fontSize: 16,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Your whole profile & fit in one place',
                      style: AppFonts.body(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Open →',
                style: AppFonts.mono(
                  fontSize: 12,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One roadmap step's data — mirrors one entry of the JS's inline
/// `steps` array in `renderHome()`.
class _RoadmapStep {
  const _RoadmapStep({
    required this.route,
    required this.title,
    required this.description,
    required this.done,
  });

  final String route;
  final String title;
  final String description;
  final bool done;
}

enum _RoadmapStatus { done, next, later }

/// Mirrors the JS exactly:
/// ```js
/// let nx=false;
/// steps.map((s,i)=>{
///   let st=s.done?'done':(!nx?'next':'later');
///   if(st==='next')nx=true;
///   return {...};
/// });
/// ```
/// A step's OWN `done` flag always wins regardless of position — only
/// not-done steps get the next/later split, and only the FIRST not-done
/// step in the list becomes "next"; every not-done step after that is
/// "later", even if a LATER step in the list happens to be done (that
/// one still shows as done — being "behind" the next-marker doesn't
/// retroactively make an already-done step something else).
List<_RoadmapStatus> _computeRoadmapStatuses(List<_RoadmapStep> steps) {
  final statuses = <_RoadmapStatus>[];
  var nextAssigned = false;
  for (final step in steps) {
    if (step.done) {
      statuses.add(_RoadmapStatus.done);
    } else if (!nextAssigned) {
      statuses.add(_RoadmapStatus.next);
      nextAssigned = true;
    } else {
      statuses.add(_RoadmapStatus.later);
    }
  }
  return statuses;
}

/// `.roadcard` equivalent.
class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({required this.steps, required this.statuses});
  final List<_RoadmapStep> steps;
  final List<_RoadmapStatus> statuses;

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
          Text(
            '🪜 Your pathway — start here',
            style: AppFonts.display(fontSize: 15, weight: FontWeight.w700, color: AppColors.tealDeep),
          ),
          const SizedBox(height: 9),
          for (var i = 0; i < steps.length; i++)
            _RoadmapStepRow(
              key: Key('roadmap_step_$i'),
              index: i,
              step: steps[i],
              status: statuses[i],
              isLast: i == steps.length - 1,
              onTap: () => context.push(steps[i].route),
            ),
        ],
      ),
    );
  }
}

class _RoadmapStepRow extends StatelessWidget {
  const _RoadmapStepRow({
    super.key,
    required this.index,
    required this.step,
    required this.status,
    required this.isLast,
    required this.onTap,
  });

  final int index;
  final _RoadmapStep step;
  final _RoadmapStatus status;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = status == _RoadmapStatus.done;
    final next = status == _RoadmapStatus.next;
    final later = status == _RoadmapStatus.later;

    return Material(
      color: next ? AppColors.orangeSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _StepCircle(number: index + 1, done: done, next: next),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 22,
                      color: done ? AppColors.teal : AppColors.line,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: AppFonts.body(
                          weight: FontWeight.w600,
                          fontSize: 13.5,
                          color: later ? AppColors.muted : AppColors.ink,
                        ),
                      ),
                      Text(
                        step.description,
                        style: AppFonts.body(fontSize: 11.5, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
                child: Text(
                  done
                      ? 'Done'
                      : next
                          ? 'Start →'
                          : '',
                  style: AppFonts.mono(
                    fontSize: 10,
                    weight: FontWeight.w700,
                    color: done
                        ? AppColors.teal
                        : next
                            ? AppColors.orangeDeep
                            : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.rnum` equivalent.
class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.number, required this.done, required this.next});
  final int number;
  final bool done;
  final bool next;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.teal : AppColors.surface2,
        border: Border.all(
          color: done ? AppColors.teal : (next ? AppColors.orange : AppColors.line),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        done ? '✓' : '$number',
        style: AppFonts.mono(
          fontSize: 13,
          weight: FontWeight.w700,
          color: done ? Colors.white : (next ? AppColors.orangeDeep : AppColors.muted),
        ),
      ),
    );
  }
}

/// `.home` equivalent — the 8-tile grid. Sign out is handled by the
/// parent, kept separate here, matching the JS's own `.tile.full`
/// sign-out row visually standing apart from the 8 destination tiles.
class _NavGrid extends StatelessWidget {
  const _NavGrid({
    required this.clubsDone,
    required this.targetsCount,
    required this.materialsStarted,
    required this.testsCount,
    required this.gradeSemestersFilled,
    required this.profileDone,
    required this.counsellorCornerDone,
  });

  final bool clubsDone;
  final int targetsCount;
  final int materialsStarted;
  final int testsCount;
  final int gradeSemestersFilled;
  final bool profileDone;
  final bool counsellorCornerDone;

  @override
  Widget build(BuildContext context) {
    final tiles = <_NavTile>[
      _NavTile(
        key: const Key('nav_tile_clubs'),
        icon: '🗓️',
        title: 'My clubs',
        subtitle: clubsDone
            ? 'Submitted · view or edit your week'
            : 'Not started · choose your clubs',
        onTap: () => context.push(AppRoutes.studentClubs),
      ),
      _NavTile(
        key: const Key('nav_tile_unipath'),
        icon: '🎓',
        title: 'Target universities',
        subtitle: targetsCount > 0
            ? '$targetsCount on your list · check fit'
            : 'Find universities by major & country',
        onTap: () => context.push(AppRoutes.studentTargetUniversities),
      ),
      _NavTile(
        key: const Key('nav_tile_materials'),
        icon: '📎',
        title: 'Application materials',
        subtitle: materialsStarted > 0
            ? '$materialsStarted of ${materialDocs.length} started · get feedback'
            : 'Portfolio · statement · study plan · CV',
        onTap: () => context.push(AppRoutes.studentMaterials),
      ),
      _NavTile(
        key: const Key('nav_tile_tests'),
        icon: '📝',
        title: 'My tests',
        subtitle: testsCount > 0
            ? '$testsCount added · feeds your fit check'
            : 'IELTS · CSCA · HSK · SAT',
        onTap: () => context.push(AppRoutes.studentTests),
      ),
      _NavTile(
        key: const Key('nav_tile_grades'),
        icon: '📈',
        title: 'My grades',
        subtitle: gradeSemestersFilled > 0
            ? '$gradeSemestersFilled semester'
                '${gradeSemestersFilled > 1 ? 's' : ''} recorded · see progress'
            : 'Input marks after each semester report',
        onTap: () => context.push(AppRoutes.studentGrades),
      ),
      _NavTile(
        key: const Key('nav_tile_profile'),
        icon: '🪪',
        title: "Student's Profile",
        subtitle: profileDone
            ? 'Filled · view or edit your details'
            : 'Your personal, family & medical details',
        onTap: () => context.push(AppRoutes.studentProfile),
      ),
      _NavTile(
        key: const Key('nav_tile_counsel'),
        icon: '🧭',
        title: "Counsellor's Corner",
        subtitle: counsellorCornerDone
            ? 'Filled · view or edit your answers'
            : 'Family & education background for the counsellor',
        onTap: () => context.push(AppRoutes.studentCounsellorCorner),
      ),
      _NavTile(
        key: const Key('nav_tile_pathways'),
        icon: '🌏',
        title: 'Pathways',
        subtitle: 'Country guides — Germany, China & more',
        onTap: () => context.push(AppRoutes.studentCountryPathways),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: tiles,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.body(weight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppFonts.body(fontSize: 11, color: AppColors.muted),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}