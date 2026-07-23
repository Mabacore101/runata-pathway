import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/activities_report_controller.dart';
import '../application/portfolio_controller.dart';
import '../domain/application_materials_catalog.dart';
import '../domain/student_activities_report.dart';
import '../domain/student_portfolio.dart';
import 'activities_report_screen.dart';

/// Application Materials — Pathway form 6. Day 5 item 1: the Hub shell
/// only. Mirrors the JS's `renderMaterials()`: 3 grade-level tabs over
/// all 8 `DOCS` rows, each with a status chip.
///
/// Only 2 of the 8 rows open real content today (Student Activities
/// Report, Portfolio — Day 5 items 2–3, landing in this same screen next
/// by replacing `_DocPlaceholderScreen`'s body with the real section
/// widgets, keyed off the same `_openDocKey`). The other 6 (5 essay docs
/// + Recommendation Letters) are Day 6 scope: visibly present with a
/// live subtitle, but their "Open" action is disabled with a "Day 6"
/// tag — same "visibly disabled, not hidden" pattern as Day 1's
/// Parent/Staff role buttons.
///
/// One screen owns all of this internally via `_openDocKey` (null = the
/// row list; a `MaterialDoc.key` = that doc's content shown in place)
/// rather than separate go_router routes — same shape as
/// `MyClubsScreen`'s `ClubsView` enum-switch and
/// `TargetUniversitiesScreen`'s tab controller, both already-established
/// single-screen-owns-substates precedents in this codebase.
class ApplicationMaterialsScreen extends ConsumerStatefulWidget {
  const ApplicationMaterialsScreen({super.key});

  @override
  ConsumerState<ApplicationMaterialsScreen> createState() =>
      _ApplicationMaterialsScreenState();
}

class _ApplicationMaterialsScreenState
    extends ConsumerState<ApplicationMaterialsScreen> {
  late int _ayIndex;
  String? _openDocKey;

  @override
  void initState() {
    super.initState();
    final grade = ref.read(authControllerProvider).session?.grade;
    _ayIndex = defaultAcademicYearIndexForGrade(grade);
  }

  void _openDoc(String key) => setState(() => _openDocKey = key);
  void _closeDoc() => setState(() => _openDocKey = null);

  @override
  Widget build(BuildContext context) {
    if (_openDocKey != null) {
      if (_openDocKey == 'activities') {
        return ActivitiesReportScreen(onBack: _closeDoc);
      }
      final doc = materialDocs.firstWhere((d) => d.key == _openDocKey);
      return _DocPlaceholderScreen(doc: doc, onBack: _closeDoc);
    }

    final report = ref.watch(activitiesReportControllerProvider);
    final portfolio = ref.watch(portfolioControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Application materials')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  const Text('📎', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Application materials',
                      style:
                          AppFonts.display(fontSize: 20, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                "Fill these in any order — whatever's ready. Each writing "
                'document gets instant feedback against university '
                'standards; your advisor sees your progress.',
                style: AppFonts.body(fontSize: 13, color: AppColors.muted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AyTabs(
                selectedIndex: _ayIndex,
                onChanged: (i) => setState(() => _ayIndex = i),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                itemCount: materialDocs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final doc = materialDocs[i];
                  return _MaterialRow(
                    key: Key('material_row_${doc.key}'),
                    doc: doc,
                    status: _statusFor(doc, report, portfolio),
                    onOpen:
                        doc.availableToday ? () => _openDoc(doc.key) : null,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(AppRoutes.studentHome),
                  child: const Text('← Back to home'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mirrors the JS's per-kind chip logic in `renderMaterials()` exactly
  /// for the 2 real docs (`actStarted`/`portfolioWorks[...].works.length`
  /// — see the domain models' own doc comments); the other 6 kinds show
  /// a plain "Day 6" tag today rather than the JS's `scoreDoc`-derived
  /// chip, since that needs Day 6's rubric data which doesn't exist yet.
  _DocStatus _statusFor(
    MaterialDoc doc,
    StudentActivitiesReport report,
    StudentPortfolio portfolio,
  ) {
    switch (doc.kind) {
      case MaterialDocKind.report:
        return report.hasAnyData
            ? const _DocStatus(label: 'Started', tone: _StatusTone.met)
            : const _DocStatus(label: 'Not started', tone: _StatusTone.none);
      case MaterialDocKind.builder:
        final n = portfolio.works.length;
        return n > 0
            ? _DocStatus(
                label: '$n work${n > 1 ? 's' : ''}',
                tone: _StatusTone.met,
              )
            : const _DocStatus(label: 'Not started', tone: _StatusTone.none);
      case MaterialDocKind.text:
      case MaterialDocKind.upload:
        return const _DocStatus(label: 'Day 6', tone: _StatusTone.none);
    }
  }
}

enum _StatusTone { met, none }

class _DocStatus {
  const _DocStatus({required this.label, required this.tone});
  final String label;
  final _StatusTone tone;
}

/// Pill-style grade tabs (`.aytabs` in the original CSS) — Gr 10/11/12.
class _AyTabs extends StatelessWidget {
  const _AyTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < academicYearTabs.length; i++)
            _AyTabButton(
              key: Key('ay_tab_${academicYearTabs[i].id}'),
              label: academicYearTabs[i].label,
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _AyTabButton extends StatelessWidget {
  const _AyTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.teal : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
          child: Text(
            label,
            style: AppFonts.body(
              weight: FontWeight.w600,
              fontSize: 12,
              color: selected ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// One row on the Hub — name, subtitle, status chip, Open action.
class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    super.key,
    required this.doc,
    required this.status,
    required this.onOpen,
  });

  final MaterialDoc doc;
  final _DocStatus status;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: AppFonts.body(
                    weight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.subtitle,
                  style: AppFonts.mono(fontSize: 9.5, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusChip(status: status),
          const SizedBox(width: 10),
          if (onOpen != null)
            OutlinedButton(
              key: Key('open_doc_${doc.key}'),
              onPressed: onOpen,
              child: const Text('Open'),
            )
          else
            const _SoonTag(),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _DocStatus status;

  @override
  Widget build(BuildContext context) {
    final met = status.tone == _StatusTone.met;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: met ? AppColors.greenSoft : AppColors.surface2,
        border: met ? null : Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: AppFonts.mono(
          fontSize: 9,
          weight: FontWeight.w600,
          color: met ? AppColors.green : AppColors.muted,
        ),
      ),
    );
  }
}

/// Matches the original CSS's `.soontag` — same visual language Day 1
/// already used for the disabled Parent/Staff role buttons.
class _SoonTag extends StatelessWidget {
  const _SoonTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'DAY 6',
        style: AppFonts.mono(
          fontSize: 8,
          weight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Temporary placeholder body for the 2 real docs, shown when
/// `_openDocKey` is set — Day 5 items 2/3 replace this with the real
/// Activities Report / Portfolio content, keyed off the same state, so
/// nothing about the Hub's navigation model changes when that lands.
class _DocPlaceholderScreen extends StatelessWidget {
  const _DocPlaceholderScreen({required this.doc, required this.onBack});

  final MaterialDoc doc;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc.name)),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${doc.name} — coming next',
                  style: AppFonts.body(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const Key('materials_back_to_hub'),
                  onPressed: onBack,
                  child: const Text('← Back to materials'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}