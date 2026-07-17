import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../application/grades_controller.dart';
import '../data/student_grades_repository.dart';
import '../domain/curriculum.dart';
import '../domain/grade_subject_entry.dart';
import '../domain/student_grades_settings.dart';

/// My Grades — Pathway form 4. 6 semester tabs, identical template.
///
/// A tab switch (or a track toggle) reloads that tab's rows fresh from
/// Hive, discarding any unsaved edits left in the tab you switched away
/// from — same explicit-Save, deferred-edit pattern as Profile/Tests, just
/// scoped per-tab instead of per-screen. This is a deliberate
/// simplification: the site's own JS re-renders the whole tab on every
/// switch too (`renderGrades()` rebuilds `rowsHtml` from `G.marks`, not
/// from some separately-tracked draft), so this matches rather than
/// under-builds.
///
/// Also simplified: the JS defaults the initial tab to the student's
/// CURRENT academic year (`studentAY(stu)+"s1"`), which needs a grade
/// level on the session — `StudentSession` only has studentId+name today.
/// Defaults to the first tab (Gr 10 · S1) instead; wiring a real default
/// would mean extending `StudentSession` with a grade field, out of scope
/// here.
class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradeRowControllers {
  _GradeRowControllers({
    required this.name,
    required this.group,
    required this.isCustom,
    GradeSubjectEntry? from,
  }) : score = TextEditingController(
          text: from?.score != null ? _formatScore(from!.score!) : '',
        );

  final String name;
  final GradeSubjectGroup group;
  final bool isCustom;
  final TextEditingController score;

  GradeSubjectEntry toEntry(String semesterCode) => GradeSubjectEntry(
        id: StudentGradesRepository.scoreKey(semesterCode, name),
        semesterCode: semesterCode,
        name: name,
        score: double.tryParse(score.text.trim()),
        group: group,
        isCustom: isCustom,
      );

  void dispose() => score.dispose();

  static String _formatScore(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  int _currentSemesterIndex = 0;
  late List<_GradeRowControllers> _rows;
  final _newSubjectController = TextEditingController();

  SemesterInfo get _currentSemester => SemesterInfo.all[_currentSemesterIndex];

  @override
  void initState() {
    super.initState();
    _rows = [];
    _rebuildRowsForCurrentTab();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    _newSubjectController.dispose();
    super.dispose();
  }

  void _rebuildRowsForCurrentTab() {
    for (final row in _rows) {
      row.dispose();
    }
    final settings = ref.read(gradesControllerProvider);
    final scores = ref
        .read(studentGradesRepositoryProvider)
        .scoresForSemester(_currentSemester.code);
    final scoreByName = {for (final s in scores) s.name: s};

    final rows = <_GradeRowControllers>[];
    for (final group in Curriculum.subjectGroupsFor(
      _currentSemester,
      settings.track,
    )) {
      for (final subject in group.subjects) {
        rows.add(_GradeRowControllers(
          name: subject,
          group: group.group,
          isCustom: false,
          from: scoreByName[subject],
        ));
      }
    }
    for (final custom in settings.customSubjects) {
      rows.add(_GradeRowControllers(
        name: custom,
        group: GradeSubjectGroup.other,
        isCustom: true,
        from: scoreByName[custom],
      ));
    }
    _rows = rows;
  }

  void _selectSemester(int index) {
    if (index == _currentSemesterIndex) return;
    setState(() {
      _currentSemesterIndex = index;
      _rebuildRowsForCurrentTab();
    });
  }

  Future<void> _setTrack(GradeTrack track) async {
    await ref.read(gradesControllerProvider.notifier).setTrack(track);
    setState(_rebuildRowsForCurrentTab);
  }

  Future<void> _addSubject() async {
    final name = _newSubjectController.text;
    if (name.trim().isEmpty) return;
    await ref.read(gradesControllerProvider.notifier).addCustomSubject(name);
    _newSubjectController.clear();
    setState(_rebuildRowsForCurrentTab);
  }

  Future<void> _deleteSubject(String name) async {
    await ref.read(gradesControllerProvider.notifier).deleteCustomSubject(name);
    setState(_rebuildRowsForCurrentTab);
  }

  Future<void> _handleSave() async {
    final repo = ref.read(studentGradesRepositoryProvider);
    for (final row in _rows) {
      await repo.upsertScore(row.toEntry(_currentSemester.code));
    }
    setState(() {}); // refresh the progress/feedback section below
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grades saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(gradesControllerProvider);
    final repo = ref.read(studentGradesRepositoryProvider);
    final allScores = [
      for (final semester in SemesterInfo.all)
        MapEntry(semester, repo.scoresForSemester(semester.code)),
    ];
    final feedback = gradesFeedbackBullets(allScores);

    final fixedGroups =
        Curriculum.subjectGroupsFor(_currentSemester, settings.track);
    final customRows = _rows.where((r) => r.isCustom).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Grades')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('📈', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'My grades',
                  style: AppFonts.display(fontSize: 20, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'After each semester report, enter your marks (0–100). '
              'Subjects are pre-loaded from the Runata curriculum.',
              style: AppFonts.body(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),

            if (!_currentSemester.isGrade10) ...[
              Row(
                children: [
                  Text(
                    'Stream:',
                    style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Science'),
                    selected: settings.track == GradeTrack.science,
                    onSelected: (_) => _setTrack(GradeTrack.science),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Social'),
                    selected: settings.track == GradeTrack.social,
                    onSelected: (_) => _setTrack(GradeTrack.social),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              Text(
                'Grade 10 — same subjects for everyone (10A & 10B, no '
                'stream yet)',
                style: AppFonts.body(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
            ],

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < SemesterInfo.all.length; i++) ...[
                    _SemesterTabButton(
                      label: SemesterInfo.all[i].label,
                      selected: i == _currentSemesterIndex,
                      hasData: repo
                          .scoresForSemester(SemesterInfo.all[i].code)
                          .any((e) => e.score != null),
                      onTap: () => _selectSemester(i),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            for (final group in fixedGroups) ...[
              Text(
                _groupLabel(group.group),
                style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              for (final subject in group.subjects)
                _GradeRow(
                  controllers: _rows.firstWhere((r) => r.name == subject),
                ),
              const SizedBox(height: 12),
            ],

            if (customRows.isNotEmpty) ...[
              Text(
                'Other',
                style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              for (final row in customRows)
                _GradeRow(
                  controllers: row,
                  onDelete: () => _deleteSubject(row.name),
                ),
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubjectController,
                    decoration: const InputDecoration(
                      hintText: 'Add another subject (optional)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _addSubject,
                  child: const Text('+ Add'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Progress & feedback',
              style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (feedback.filledAverages.isEmpty)
                    Text(
                      'No marks entered yet.',
                      style: AppFonts.body(color: AppColors.muted),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        for (final a in feedback.filledAverages)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.semester.label,
                                style: AppFonts.body(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              Text(
                                a.average.toStringAsFixed(1),
                                style: AppFonts.display(
                                  fontSize: 16,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  for (final bullet in feedback.bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '•  $bullet',
                        style: AppFonts.body(fontSize: 13, color: AppColors.ink),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.studentHome),
                    child: const Text('← Back to home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SemesterTabButton extends StatelessWidget {
  const _SemesterTabButton({
    required this.label,
    required this.selected,
    required this.hasData,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool hasData;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return selected
        ? ElevatedButton(
            onPressed: onTap,
            child: Text(hasData ? '$label •' : label),
          )
        : OutlinedButton(
            onPressed: onTap,
            child: Text(hasData ? '$label •' : label),
          );
  }
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.controllers, this.onDelete});

  final _GradeRowControllers controllers;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              controllers.name,
              style: AppFonts.body(fontSize: 13, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _GradeScoreField(controller: controllers.score),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Delete',
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}

/// The two input paths from the flow spec, in one compact widget — with
/// one deliberate deviation from the spec's literal wording:
/// - **Typing** directly into the text field: [gradeScoreInputFormatter]
///   only allows digits, so a value like "137" passes straight through
///   unclamped (the upper-bound clamp-bypass bug, knowingly kept per
///   planning.md §6) — but a minus sign can never be typed at all, so a
///   negative score is now structurally impossible, not just discouraged.
///   **This intentionally departs from the flow spec's literal "ACCEPTED
///   even if >100 or <0" wording** — a deliberate product decision (there's
///   no scenario where a negative grade is meaningful), not an oversight.
///   The part of the bug actually worth preserving — that the average
///   calculation doesn't secretly clamp — is still fully intact for the
///   upper bound, which is the specific case the spec calls "REAL BUG".
/// - **Tapping ▲/▼**: [clampedSpinnerStep] always clamps into 0–100,
///   regardless of how far out of range manual typing had already pushed
///   the value (even a single tap from "137" snaps straight to 100, not
///   136) — matches the spec's "Spinner (↑↓): Clamped at 0–100 — cannot
///   exceed" exactly.
class _GradeScoreField extends StatefulWidget {
  const _GradeScoreField({required this.controller});

  final TextEditingController controller;

  @override
  State<_GradeScoreField> createState() => _GradeScoreFieldState();
}

class _GradeScoreFieldState extends State<_GradeScoreField> {
  void _step(int delta) {
    setState(() {
      widget.controller.text =
          clampedSpinnerStep(widget.controller.text, delta).toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            keyboardType: const TextInputType.numberWithOptions(signed: false),
            inputFormatters: [gradeScoreInputFormatter],
            decoration: const InputDecoration(hintText: '–', isDense: true),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 28,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 16),
                onPressed: () => _step(1),
                tooltip: 'Increase (clamped 0–100)',
                padding: EdgeInsets.zero,
              ),
            ),
            SizedBox(
              height: 20,
              width: 28,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                onPressed: () => _step(-1),
                tooltip: 'Decrease (clamped 0–100)',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _groupLabel(GradeSubjectGroup group) {
  switch (group) {
    case GradeSubjectGroup.coreEssentials:
      return 'Core Essentials';
    case GradeSubjectGroup.coreSubjects:
      return 'Core Subjects';
    case GradeSubjectGroup.coreGeneral:
      return 'Core General';
    case GradeSubjectGroup.other:
      return 'Other';
  }
}

/// Digits only — no minus sign, no letters, no decimal point. This alone
/// is what makes a negative score structurally impossible to type (see
/// [_GradeScoreField]'s doc comment for why that's a deliberate departure
/// from the flow spec's literal wording). A value over 100 is NOT
/// filtered here on purpose — that's the upper-bound clamp-bypass bug,
/// still knowingly kept.
///
/// Exposed top-level (not inlined into the widget) so it's directly
/// unit-testable via `TextInputFormatter.formatEditUpdate` without
/// pumping any widget.
final TextInputFormatter gradeScoreInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));

/// The spinner's clamp logic, pulled out of `_GradeScoreFieldState._step`
/// so it's a plain, directly-testable function. Always resolves into
/// [0, 100] no matter how far out of range [currentText] already was —
/// e.g. stepping down by 1 from "137" lands on 100, not 136, matching the
/// spec's "cannot exceed" wording (the clamp applies to the RESULT, not
/// as an increment from an already-invalid base). Unparseable/blank text
/// is treated as 0, same as the score field's own blank-means-nothing
/// convention elsewhere.
double clampedSpinnerStep(String currentText, int delta) {
  final current = double.tryParse(currentText) ?? 0;
  return (current + delta).clamp(0, 100).toDouble();
}
