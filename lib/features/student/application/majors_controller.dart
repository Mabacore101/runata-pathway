import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_majors_repository.dart';
import '../domain/major_entry.dart';
import '../domain/student_majors_settings.dart';

final majorsControllerProvider =
    NotifierProvider<MajorsController, StudentMajorsSettings>(
  MajorsController.new,
);

/// Explore Majors — add/remove majors (max 6), mark up to 3 as Top,
/// choose exactly 1 anchor (must be Top-marked). Every mutation here is
/// immediately persisted, matching the JS: `persistMajors()` runs inside
/// every `data-maddm`/`data-mrmm`/`data-mtop`/`data-manchor` handler, with
/// no separate "Save" step for this tab (unlike Profile/Tests, which
/// defer field edits to an explicit Save).
class MajorsController extends Notifier<StudentMajorsSettings> {
  @override
  StudentMajorsSettings build() =>
      ref.read(studentMajorsRepositoryProvider).loadSettings();

  StudentMajorsRepository get _repository =>
      ref.read(studentMajorsRepositoryProvider);

  static const _maxMajors = 6;
  static const _maxTop = 3;

  /// Mirrors `data-maddm`: no-op if already at 6 majors or [major] is
  /// already present — same double guard as the JS
  /// (`s.majors.length<6&&!s.majors.some(x=>x.m===maddm...)`).
  Future<void> addMajor(String major) async {
    if (state.majors.length >= _maxMajors) return;
    if (state.majors.any((m) => m.major == major)) return;

    await _persist(
      StudentMajorsSettings(
        majors: [...state.majors, MajorEntry(major: major)],
      ),
    );
  }

  /// Mirrors `data-mrmm`: splice the entry out, nothing else. No explicit
  /// anchor-clearing code here — if [index] held the anchor,
  /// [MajorsDerived.anchor] simply stops finding it on the next read,
  /// exactly like the JS's from-scratch `persistMajors()` rescan. This is
  /// the "free" half of the delete-a-major cascade
  /// day3-trimmed-source.md calls out.
  Future<void> removeMajor(int index) async {
    final majors = [...state.majors]..removeAt(index);
    await _persist(StudentMajorsSettings(majors: majors));
  }

  /// Mirrors `data-mtop`. Two guards, same order as the JS:
  /// 1. Blocks turning Top ON if 3 are already marked and this one isn't
  ///    one of them (`cur>=3`) — returns `false` so the UI can surface
  ///    the same "only 3 as Top 3" message the JS toasts.
  /// 2. Turning Top OFF also clears this entry's own `anchor` flag
  ///    (`if(!s.majors[i].top)s.majors[i].anchor=false`) — kept inline
  ///    here rather than as a separate cascade step, because it's the
  ///    same single-entry mutation the JS performs in one handler.
  Future<bool> toggleTop(int index) async {
    final entry = state.majors[index];
    final currentTopCount = state.majors.where((m) => m.top).length;
    if (!entry.top && currentTopCount >= _maxTop) return false;

    final willBeTop = !entry.top;
    final majors = [...state.majors];
    majors[index] = MajorEntry(
      major: entry.major,
      country: entry.country,
      top: willBeTop,
      anchor: willBeTop ? entry.anchor : false,
    );
    await _persist(StudentMajorsSettings(majors: majors));
    return true;
  }

  /// Mirrors `data-manchor`: no-op if [index] isn't currently Top-marked
  /// — anchor can ONLY be set on an already-Top major. Otherwise clears
  /// every entry's anchor first, then sets only [index]'s, enforcing
  /// exactly 1 anchor at a time.
  Future<void> setAnchor(int index) async {
    if (!state.majors[index].top) return;

    final majors = [
      for (var i = 0; i < state.majors.length; i++)
        MajorEntry(
          major: state.majors[i].major,
          country: state.majors[i].country,
          top: state.majors[i].top,
          anchor: i == index,
        ),
    ];
    await _persist(StudentMajorsSettings(majors: majors));
  }

  Future<void> _persist(StudentMajorsSettings updated) async {
    await _repository.saveSettings(updated);
    state = updated;
  }
}

/// Always-fresh derived reads over the current majors list — the
/// intentional replacement for the JS's separately-stored
/// `s.anchorMajor`/`s.top3` cache fields.
extension MajorsDerived on StudentMajorsSettings {
  /// Equivalent to the JS's `s.majors.find(x=>x.anchor)`.
  MajorEntry? get anchor {
    for (final m in majors) {
      if (m.anchor) return m;
    }
    return null;
  }

  /// Equivalent to `s.top3`. Name inherited from the UI label ("Top 3");
  /// the behavioral spec confirms only 1 is actually required, so this
  /// can be length 1–3 in practice.
  List<MajorEntry> get topMarked =>
      majors.where((m) => m.top).toList(growable: false);

  /// Gates the "Continue to universities →" CTA (`pickReady` in the JS:
  /// `top3===3 && !!anchor`) — stricter than the Find Universities TAB's
  /// own entry gate, which only needs 1+ Top-marked major per the
  /// behavioral spec's "At Least 1 Marked as Top?" diamond. This getter
  /// is for the CTA button only, not tab reachability.
  bool get readyToContinue => topMarked.length == 3 && anchor != null;
}
