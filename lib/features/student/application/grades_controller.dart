import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_grades_repository.dart';
import '../domain/curriculum.dart';
import '../domain/grade_subject_entry.dart';
import '../domain/student_grades_settings.dart';

final gradesControllerProvider =
    NotifierProvider<GradesController, StudentGradesSettings>(
  GradesController.new,
);

/// Manages the two genuinely GLOBAL pieces of My Grades state: the
/// Science/Social track choice and the list of custom subject NAMES.
/// Per-semester SCORES are handled directly via
/// [StudentGradesRepository] from the screen (same deferred-edit,
/// explicit-Save pattern as Profile/Tests) — they don't need to be
/// reactive Notifier state the way track/customSubjects do, since editing
/// scores only ever affects the one currently-open tab, not every screen
/// watching this controller.
class GradesController extends Notifier<StudentGradesSettings> {
  @override
  StudentGradesSettings build() =>
      ref.read(studentGradesRepositoryProvider).loadSettings();

  StudentGradesRepository get _repository =>
      ref.read(studentGradesRepositoryProvider);

  Future<void> setTrack(GradeTrack track) async {
    final updated = StudentGradesSettings(
      track: track,
      customSubjects: state.customSubjects,
    );
    await _repository.saveSettings(updated);
    state = updated;
  }

  /// Adds a new custom subject NAME globally — it becomes an editable row
  /// in every semester tab from now on, matching the JS's `G.extra`
  /// behavior (added once, not per-semester). No-op if [name] is blank or
  /// already present (exact, case-sensitive match — the JS does no
  /// normalization either, so neither does this).
  Future<void> addCustomSubject(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || state.customSubjects.contains(trimmed)) return;

    final updated = StudentGradesSettings(
      track: state.track,
      customSubjects: [...state.customSubjects, trimmed],
    );
    await _repository.saveSettings(updated);
    state = updated;
  }

  /// Removes a custom subject globally — from the settings list AND its
  /// score in every semester at once, mirroring the JS's single "Other"
  /// row delete button removing the subject everywhere, not just the
  /// currently-open tab.
  Future<void> deleteCustomSubject(String name) async {
    await _repository.deleteScoreEverywhere(name);
    final updated = StudentGradesSettings(
      track: state.track,
      customSubjects: state.customSubjects.where((s) => s != name).toList(),
    );
    await _repository.saveSettings(updated);
    state = updated;
  }
}

/// One semester's computed average, paired with which semester it's for —
/// used by [gradesFeedbackBullets] to compare across semesters.
class SemesterAverage {
  const SemesterAverage(this.semester, this.average);

  final SemesterInfo semester;
  final double average;
}

/// Mirrors the JS `semAvg(G, sem)` exactly: the mean of every scored
/// (non-null) entry, nothing else. Deliberately NOT clamped — per
/// planning.md §6 and the flow spec's clamp-bypass bug, an out-of-range
/// manually-typed score must visibly skew this average, not be silently
/// corrected here. Returns null (not zero) when there's nothing scored
/// yet — an empty semester is "not filled", not "averages to zero".
double? semesterAverage(List<GradeSubjectEntry> entries) {
  final scores = [
    for (final e in entries)
      if (e.score != null) e.score!,
  ];
  if (scores.isEmpty) return null;
  return scores.reduce((a, b) => a + b) / scores.length;
}

/// Bundle returned by [gradesFeedbackBullets]: every semester that has at
/// least one score, in chronological order, plus the generated trend
/// bullets (mirrors the JS `gradesFeedback()`'s `{avgs, bullets}`).
class GradesFeedback {
  const GradesFeedback({required this.filledAverages, required this.bullets});

  final List<SemesterAverage> filledAverages;
  final List<String> bullets;
}

/// Mirrors the JS `gradesFeedback(G)`. [allSemesterScores] must cover all
/// 6 semesters in [SemesterInfo.all] order (an empty list for a semester
/// with nothing entered yet is fine — it just won't count as "filled").
GradesFeedback gradesFeedbackBullets(
  List<MapEntry<SemesterInfo, List<GradeSubjectEntry>>> allSemesterScores,
) {
  final filled = <SemesterAverage>[
    for (final entry in allSemesterScores)
      if (semesterAverage(entry.value) != null)
        SemesterAverage(entry.key, semesterAverage(entry.value)!),
  ];

  if (filled.isEmpty) {
    return const GradesFeedback(
      filledAverages: [],
      bullets: [
        'Enter your marks for a semester to see your progress and feedback.',
      ],
    );
  }

  if (filled.length == 1) {
    return GradesFeedback(
      filledAverages: filled,
      bullets: [
        'First semester recorded — average '
            '${filled[0].average.toStringAsFixed(1)}. Add your next '
            'semester to see the trend.',
      ],
    );
  }

  final prev = filled[filled.length - 2];
  final last = filled[filled.length - 1];
  final delta = _roundTo1(last.average - prev.average);

  final bullets = <String>[];
  if (delta > 0.5) {
    bullets.add(
      'Your average rose from ${prev.average.toStringAsFixed(1)} to '
      '${last.average.toStringAsFixed(1)} (+${delta.toStringAsFixed(1)}) — '
      'great progress, keep it up.',
    );
  } else if (delta < -0.5) {
    bullets.add(
      'Your average moved from ${prev.average.toStringAsFixed(1)} to '
      '${last.average.toStringAsFixed(1)} (${delta.toStringAsFixed(1)}). '
      'A small dip — pick one subject to focus on next term.',
    );
  } else {
    bullets.add(
      'Your average held steady around '
      '${last.average.toStringAsFixed(1)} — nice consistency.',
    );
  }

  // Biggest single-subject swing between prev and last — only subjects
  // scored in BOTH semesters count, matching the JS's guard.
  final prevScores = {
    for (final e in allSemesterScores
        .firstWhere((x) => x.key.code == prev.semester.code)
        .value)
      if (e.score != null) e.name: e.score!,
  };
  final lastScores = {
    for (final e in allSemesterScores
        .firstWhere((x) => x.key.code == last.semester.code)
        .value)
      if (e.score != null) e.name: e.score!,
  };

  String? bestSubject;
  double? bestDelta;
  String? worstSubject;
  double? worstDelta;

  for (final subject in lastScores.keys) {
    if (!prevScores.containsKey(subject)) continue;
    final dd = _roundTo1(lastScores[subject]! - prevScores[subject]!);
    if (bestDelta == null || dd > bestDelta) {
      bestDelta = dd;
      bestSubject = subject;
    }
    if (worstDelta == null || dd < worstDelta) {
      worstDelta = dd;
      worstSubject = subject;
    }
  }

  if (bestSubject != null && bestDelta != null && bestDelta > 0) {
    bullets.add(
      'Biggest improvement: $bestSubject (+${bestDelta.toStringAsFixed(1)}). '
      'Well done.',
    );
  }
  if (worstSubject != null && worstDelta != null && worstDelta < 0) {
    bullets.add(
      'Worth attention: $worstSubject (${worstDelta.toStringAsFixed(1)}). A '
      'little extra practice — or a chat with your teacher — can help.',
    );
  }

  return GradesFeedback(filledAverages: filled, bullets: bullets);
}

double _roundTo1(double value) =>
    double.parse(value.toStringAsFixed(1));
