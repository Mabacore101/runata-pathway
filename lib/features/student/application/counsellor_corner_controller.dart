import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_counsellor_corner_repository.dart';
import '../domain/counsellor_corner.dart';

/// Counsellor's Corner — full read/write controller.
///
/// **Every field genuinely autosaves on change** — same shape as
/// `PortfolioController`, not `ActivitiesReportController`'s deferred-
/// until-Save split. Unlike that earlier judgment call (which had to be
/// inferred from the behavioral spec's language), this one is settled
/// directly by the JS's own on-screen copy: "It saves automatically."
/// Tracing every `data-cns` handler confirms it — see
/// `counsellor_corner.dart`'s own doc comment for the full trace.
/// [updateAll] is called on every keystroke/dropdown selection anywhere
/// on the screen, not batched — the on-screen "Save" button that ships
/// with the screen is genuinely cosmetic here, same reassurance-only
/// pattern already used for Portfolio/Target Universities' Save buttons.
final counsellorCornerControllerProvider =
    NotifierProvider<CounsellorCornerController, CounsellorCorner>(
  CounsellorCornerController.new,
);

class CounsellorCornerController extends Notifier<CounsellorCorner> {
  @override
  CounsellorCorner build() =>
      ref.read(studentCounsellorCornerRepositoryProvider).load();

  StudentCounsellorCornerRepository get _repository =>
      ref.read(studentCounsellorCornerRepositoryProvider);

  /// Persists the entire current record in one write. [updated] is built
  /// fresh from `state.copyWith(...)` by the caller each time (the
  /// screen names only the one field it's changing) — this only
  /// overwrites field VALUES, matching every other `updateAll`-style
  /// method in this app.
  Future<void> updateAll(CounsellorCorner updated) async {
    await _repository.save(updated);
    state = updated;
  }
}
