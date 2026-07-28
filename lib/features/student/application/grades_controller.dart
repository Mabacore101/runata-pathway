import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../data/student_grades_repository.dart';
import '../data/student_hive_providers.dart';
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

/// Mirrors the JS's `gcnt=gG?SEMS.filter(s=>semAvg(gG,s.id)!==null)
/// .length:0` — counts how many of the 6 semesters have at least one
/// scored entry. Used by Nav Grid's roadmap "My grades" step and its
/// 8-tile subtitle, and will be reused by Dashboard tomorrow.
///
/// Reads [studentGradesBoxProvider] directly rather than going through
/// [GradesController] — that controller's own doc comment explains why
/// per-semester SCORES were deliberately left out of its reactive
/// `Notifier` state (only track/customSubjects are). That means this
/// provider is NOT reactive across screens the way profile/tests/clubs
/// are: a Hive box mutation doesn't notify Riverpod on its own, so this
/// recomputes fresh only when ITS OWN watchers next rebuild — correct
/// when navigating back to a screen that reads it (a fresh build reads
/// fresh data), just not a live cross-screen push while both screens are
/// mounted simultaneously. Same "pull fresh on next build" behavior
/// every Hive-backed read in this app already has; called out explicitly
/// here since this is the first place reading grades from OUTSIDE the
/// Grades screen itself.
/// Mirrors the JS's `gcnt=gG?SEMS.filter(s=>semAvg(gG,s.id)!==null)
/// .length:0` — counts how many of the 6 semesters have at least one
/// scored entry. Used by Nav Grid's roadmap "My grades" step and its
/// 8-tile subtitle, and will be reused by Dashboard tomorrow.
///
/// **A `Notifier`, not a plain `Provider` — this genuinely needs to be,
/// not a style choice.** An earlier version of this file used a plain
/// `Provider<int>` that read [studentGradesBoxProvider] via `ref.watch`,
/// on the assumption that would recompute whenever a consumer next
/// rebuilt (e.g. navigating back to Home from Grades). That assumption
/// was wrong, confirmed by manual testing: entering a grade never marked
/// the roadmap step done, even after returning to Home. The reason:
/// Hive's `Box` object reference never changes — mutations happen
/// in-place — so from Riverpod's perspective the watched value never
/// changed, and the count was computed once and cached for the rest of
/// the app's lifetime, not just "until the next rebuild." Every OTHER
/// roadmap signal (profile/targets/clubs/tests/materials) goes through a
/// proper `Notifier` whose `state` is explicitly reassigned on save,
/// which Riverpod correctly propagates — grades scores are the one piece
/// of data in this app read directly from Hive with no controller in
/// between (see [GradesController]'s own doc comment for why), which is
/// exactly why this was the one place this bug could hide. Fixed by
/// subscribing directly to Hive's own `Box.watch()` change stream, so
/// this recomputes the instant a score is actually written, regardless
/// of whether/when some other widget happens to rebuild.
final gradeSemestersFilledCountProvider =
    NotifierProvider<GradeSemestersFilledCountNotifier, int>(
  GradeSemestersFilledCountNotifier.new,
);

class GradeSemestersFilledCountNotifier extends Notifier<int> {
  StreamSubscription<BoxEvent>? _subscription;

  @override
  int build() {
    final box = ref.watch(studentGradesBoxProvider);

    // Defensive: build() should only run once in practice (its one
    // watched dependency, the box itself, never changes value), but
    // cancel-then-resubscribe is correct regardless if it ever does.
    _subscription?.cancel();
    _subscription = box.watch().listen((_) {
      state = _countFilledSemesters(box);
    });
    ref.onDispose(() => _subscription?.cancel());

    return _countFilledSemesters(box);
  }

  int _countFilledSemesters(Box<GradeSubjectEntry> box) {
    final allEntries = box.values.toList();
    var count = 0;
    for (final code in SemesterCode.all) {
      final semesterEntries = allEntries.where((e) => e.semesterCode == code).toList();
      if (semesterAverage(semesterEntries) != null) count++;
    }
    return count;
  }
}

/// Dashboard's version of the same underlying need [gradeSemestersFilledCountProvider]
/// serves — but exposing the FULL [GradesFeedback] (every filled semester's
/// average, in order, plus the generated trend bullets) rather than just a
/// count, since Dashboard's Grades panel needs the latest average and the
/// up/down/steady trend arrow, not just "how many."
///
/// A separate `Notifier`/box subscription from
/// [GradeSemestersFilledCountNotifier] rather than deriving one from the
/// other — both watch the same box independently. Slightly more
/// subscription overhead than sharing one, but keeps the already-working,
/// already-tested count provider untouched rather than refactoring it
/// while fixing an unrelated screen; the overhead itself is negligible
/// for a small local Hive box.
final gradesFeedbackProvider = NotifierProvider<GradesFeedbackNotifier, GradesFeedback>(
  GradesFeedbackNotifier.new,
);

class GradesFeedbackNotifier extends Notifier<GradesFeedback> {
  StreamSubscription<BoxEvent>? _subscription;

  @override
  GradesFeedback build() {
    final box = ref.watch(studentGradesBoxProvider);

    _subscription?.cancel();
    _subscription = box.watch().listen((_) {
      state = _compute(box);
    });
    ref.onDispose(() => _subscription?.cancel());

    return _compute(box);
  }

  GradesFeedback _compute(Box<GradeSubjectEntry> box) {
    final allEntries = box.values.toList();
    final bySemester = [
      for (final semester in SemesterInfo.all)
        MapEntry(
          semester,
          allEntries.where((e) => e.semesterCode == semester.code).toList(),
        ),
    ];
    return gradesFeedbackBullets(bySemester);
  }
}