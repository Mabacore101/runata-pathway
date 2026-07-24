import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/fit_chip.dart';
import '../../auth/application/auth_controller.dart';
import '../application/activities_report_controller.dart';
import '../application/application_documents_controller.dart';
import '../application/materials_context.dart';
import '../application/portfolio_controller.dart';
import '../domain/application_document_state.dart';
import '../domain/application_materials_catalog.dart';
import '../domain/document_rubric.dart';
import '../domain/student_activities_report.dart';
import '../domain/student_portfolio.dart';
import 'activities_report_screen.dart';
import 'essay_doc_screen.dart';
import 'portfolio_screen.dart';

/// Application Materials — Pathway form 6. Mirrors the JS's
/// `renderMaterials()`: 3 grade-level tabs over all 8 `DOCS` rows, each
/// with a status chip.
///
/// All 8 rows open real content as of Day 6: Student Activities Report
/// and Portfolio (report/builder-kind, Day 5) route to their own
/// screens; the 5 shared-template essays + Recommendation Letters
/// (text/upload-kind, Day 6) all route to the same [EssayDocScreen],
/// parameterized by [MaterialDoc.key] — mirroring the JS's own
/// `renderMatDoc(k)` being one function for all 6, not 6 near-identical
/// ones. Nothing is disabled/placeholder anymore; the Day 1
/// "visibly disabled, not hidden" pattern (`_SoonTag`) that covered these
/// 6 rows through Day 5 no longer applies to any row here.
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
      if (_openDocKey == 'portfolio') {
        return PortfolioScreen(onBack: _closeDoc);
      }
      return EssayDocScreen(
        docKey: _openDocKey!,
        ay: academicYearTabs[_ayIndex].id,
        onBack: _closeDoc,
      );
    }

    final report = ref.watch(activitiesReportControllerProvider);
    final portfolio = ref.watch(portfolioControllerProvider);
    final docs = ref.watch(applicationDocumentsControllerProvider);
    final materialsCtx = ref.watch(materialsContextProvider);
    final ay = academicYearTabs[_ayIndex].id;

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
                    status: _statusFor(doc, report, portfolio, docs, materialsCtx, ay),
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
  /// for all 4 kinds now (`actStarted`/`portfolioWorks[...].works.length`
  /// for report/builder — see the domain models' own doc comments;
  /// [_textStatusFor]/[_uploadStatusFor] for text/upload, below).
  _DocStatus _statusFor(
    MaterialDoc doc,
    StudentActivitiesReport report,
    StudentPortfolio portfolio,
    Map<String, ApplicationDocumentState> docs,
    MaterialsContext materialsCtx,
    String ay,
  ) {
    switch (doc.kind) {
      case MaterialDocKind.report:
        return report.hasAnyData
            ? const _DocStatus(label: 'Started', tone: FitTone.met)
            : const _DocStatus(label: 'Not started', tone: FitTone.none);
      case MaterialDocKind.builder:
        final n = portfolio.works.length;
        return n > 0
            ? _DocStatus(label: '$n work${n > 1 ? 's' : ''}', tone: FitTone.met)
            : const _DocStatus(label: 'Not started', tone: FitTone.none);
      case MaterialDocKind.text:
        return _textStatusFor(doc, docs, materialsCtx, ay);
      case MaterialDocKind.upload:
        return _uploadStatusFor(doc, docs);
    }
  }

  /// Mirrors the JS's per-row text-kind chip in `renderMaterials()`
  /// exactly:
  /// ```js
  /// const sc=scoreDoc(d.k,content,ctx);
  /// const r=content.trim()?sc.met/sc.total:0;
  /// chip=!content.trim()?"Not started":r>=.8?"Looks strong":
  ///   r>=.5?"Getting there":"Needs work";
  /// ```
  _DocStatus _textStatusFor(
    MaterialDoc doc,
    Map<String, ApplicationDocumentState> docs,
    MaterialsContext materialsCtx,
    String ay,
  ) {
    final content = docs[doc.key]?.contentFor(ay) ?? '';
    if (content.trim().isEmpty) {
      return const _DocStatus(label: 'Not started', tone: FitTone.none);
    }
    final score = scoreDoc(doc.key, content, materialsCtx.forScoring);
    final ratio = score.total > 0 ? score.met / score.total : 0.0;
    if (ratio >= 0.8) return const _DocStatus(label: 'Looks strong', tone: FitTone.met);
    if (ratio >= 0.5) return const _DocStatus(label: 'Getting there', tone: FitTone.track);
    return const _DocStatus(label: 'Needs work', tone: FitTone.work);
  }

  /// Mirrors the JS's per-row upload-kind chip exactly:
  /// `const up=(D.note&&D.note.trim())||D.submitted;
  /// chip=up?"Uploaded":"Not started";`
  _DocStatus _uploadStatusFor(MaterialDoc doc, Map<String, ApplicationDocumentState> docs) {
    final d = docs[doc.key];
    final uploaded = (d?.note?.trim().isNotEmpty ?? false) || (d?.submitted ?? false);
    return uploaded
        ? const _DocStatus(label: 'Uploaded', tone: FitTone.met)
        : const _DocStatus(label: 'Not started', tone: FitTone.none);
  }
}

class _DocStatus {
  const _DocStatus({required this.label, required this.tone});
  final String label;
  final FitTone tone;
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
          FitChip(label: status.label, tone: status.tone),
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