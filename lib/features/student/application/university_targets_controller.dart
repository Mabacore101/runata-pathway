import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_university_targets_repository.dart';
import '../domain/university_target.dart';

final universityTargetsControllerProvider =
    NotifierProvider<UniversityTargetsController, List<UniversityTarget>>(
  UniversityTargetsController.new,
);

/// Find Universities' shortlist state — add/remove a university for a
/// given major+country. Every mutation is immediate/persisted, same as
/// Explore Majors (no deferred-edit Save step here).
///
/// Guards the per-major cap and duplicate-add rule itself rather than
/// trusting the UI to have already disabled the relevant button —
/// defense in depth, same style as `TestsController.addTest`'s doc
/// comment describes. The JS's two add paths (`data-addtgt` for a catalog
/// card, `data-addcustom` for a typed-in name) apply these checks
/// slightly differently in source — catalog cards only ever show an "Add"
/// button for universities not already added, so a duplicate is
/// practically unreachable through the UI on that path, while the custom
/// path explicitly checks case-insensitively. [addTarget] applies BOTH
/// checks unconditionally regardless of which path called it — a strict
/// superset of the JS's per-path behavior, not a narrower one.
class UniversityTargetsController extends Notifier<List<UniversityTarget>> {
  @override
  List<UniversityTarget> build() =>
      ref.read(studentUniversityTargetsRepositoryProvider).loadAll();

  StudentUniversityTargetsRepository get _repository =>
      ref.read(studentUniversityTargetsRepositoryProvider);

  static const maxPerMajor = 3;

  /// Returns `false` (no-op) if [major] already has 3 universities, or if
  /// [university] is already on the list for this exact major+country
  /// (case-insensitive name match, matching the JS's custom-add check).
  Future<bool> addTarget({
    required String major,
    required String country,
    required String university,
    bool custom = false,
  }) async {
    final currentForMajor = state.where((t) => t.major == major).length;
    if (currentForMajor >= maxPerMajor) return false;

    final alreadyAdded = state.any((t) =>
        t.university.toLowerCase() == university.toLowerCase() &&
        t.country == country &&
        t.major == major);
    if (alreadyAdded) return false;

    final target = UniversityTarget(
      id: 'target_${DateTime.now().microsecondsSinceEpoch}',
      major: major,
      country: country,
      university: university,
      custom: custom,
    );
    await _repository.upsert(target);
    state = [...state, target];
    return true;
  }

  /// Matches on university+major+country together, same as the JS's
  /// `data-remtgt` handler — a university can independently appear under
  /// several different majors/countries, so removal must be scoped to
  /// exactly one row, not just by name.
  Future<void> removeTarget({
    required String university,
    required String major,
    required String country,
  }) async {
    UniversityTarget? match;
    for (final t in state) {
      if (t.university == university && t.major == major && t.country == country) {
        match = t;
        break;
      }
    }
    if (match == null) return;

    await _repository.delete(match.id);
    state = state.where((t) => t.id != match!.id).toList();
  }

  /// My Shortlist's per-target notes field. Mirrors the JS's `data-tnote`
  /// handler in spirit (free text, one field per row) but NOT in timing —
  /// the JS mutates `U.targets[i].note` on every keystroke with no
  /// explicit save step, since it's a live in-memory object reference.
  /// This is a real persisted Hive write, so the SCREEN (not this method)
  /// is what decides when to call it — on focus-loss, not per keystroke —
  /// to avoid a real disk write on every character typed. This method
  /// itself just does the write + state update; it doesn't know or care
  /// when it was called.
  Future<void> updateNote(String id, String note) async {
    UniversityTarget? match;
    for (final t in state) {
      if (t.id == id) {
        match = t;
        break;
      }
    }
    if (match == null) return;

    final updated = UniversityTarget(
      id: match.id,
      major: match.major,
      country: match.country,
      university: match.university,
      custom: match.custom,
      note: note,
    );
    await _repository.upsert(updated);
    state = [for (final t in state) if (t.id == id) updated else t];
  }

  /// Removes every shortlisted university for [major] at once.
  ///
  /// Called from `MajorsController.removeMajor` when a major is deleted
  /// entirely from Explore Majors — a deleted major has no shortlist rows
  /// to "belong" to anymore, so leaving them behind would show orphaned
  /// entries in My Shortlist for a major that no longer exists in the
  /// student's list at all. Deliberately NOT triggered by un-Top-marking
  /// a major (toggleTop) — a major that's still in the list, just
  /// temporarily off Top 3, keeps its shortlist, since the student might
  /// re-Top it later and losing curated picks over a reshuffle would be
  /// needlessly punishing.
  Future<void> removeAllForMajor(String major) async {
    final toRemove = state.where((t) => t.major == major).toList();
    if (toRemove.isEmpty) return;

    for (final t in toRemove) {
      await _repository.delete(t.id);
    }
    state = state.where((t) => t.major != major).toList();
  }
}