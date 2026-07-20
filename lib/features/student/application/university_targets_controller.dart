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
}
