import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_clubs_repository.dart';
import '../domain/club_catalog.dart';
import '../domain/student_club_selection.dart';
import 'majors_controller.dart';

/// My Clubs — Pathway form 3.
///
/// Today (item 1) this file holds only the required-club derivation.
/// Ranking, the preview/capacity engine, and submit/re-entry land in later
/// items this same day and will grow this into a proper `ClubsController`
/// — not a reason to invent that shape prematurely today.
///
/// Deliberately a plain derived `Provider`, never cached — same
/// "always re-derive, never cache" philosophy as `MajorsDerived.anchor`
/// itself. This also directly resolves the open question
/// day4-codebase-reference.md raised (mirroring
/// `university_targets_controller.dart`'s cascade note): whether the
/// required club should be a live read of the anchor each time, or needs
/// its own reactive wiring if the anchor changes while My Clubs is open.
/// `ref.watch` answers that for free — Riverpod rebuilds every listener
/// the moment `majorsControllerProvider`'s anchor changes, so item 5's
/// cascade case needs no extra wiring on top of this.
final requiredClubProvider = Provider<String?>((ref) {
  final anchor = ref.watch(majorsControllerProvider).anchor;
  if (anchor == null) return null;
  return requiredClubFor(anchor.major);
});

/// Rank Other Clubs — Day 4 item 2.
///
/// Ephemeral, in-memory ranking state: the ordered list of "other clubs"
/// a student is currently arranging, NOT including the required club
/// (which is fixed/locked separately — see requiredClubProvider). This is
/// NOT persisted to Hive today — mirrors the JS's `let ranking=[]`
/// module-level variable, which only becomes durable once "Confirm &
/// submit" writes it into `submissions[stu.n]` (item 4's scope, not
/// today's). A plain `Notifier<List<String>>`, not autoDispose, same
/// precedent as majorsControllerProvider: surviving navigation away/back
/// (e.g. once item 3's Preview screen exists, "← Edit ranking" shouldn't
/// wipe what was already ranked) is the desired behavior.
///
/// Not yet handled (deliberately out of scope until item 5): if the
/// anchor major changes elsewhere while a ranking already exists, nothing
/// here proactively strips out an entry that happens to match the NEW
/// required club. `addableClubsFor` (club_catalog.dart) already prevents
/// adding the CURRENT required club going forward, which is all item 2
/// needs — reconciling an already-ranked entry against a changed anchor
/// is exactly the cascade item 5 is scoped to verify.
class ClubRankingController extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  /// Mirrors the JS's `data-add` handler (`ranking.length<need &&
  /// !ranking.includes(...)`). Returns `false` on either guard failing —
  /// the JS surfaces that as a toast ("You've ranked enough — remove one
  /// first"); this is a plain return value instead, since the UI already
  /// prevents both cases from being reachable via the pool (full clubs
  /// button disabled; the pool never lists an already-ranked club), so
  /// this is defense-in-depth rather than something the screen needs to
  /// react to today.
  bool addClub(String club, int neededPicks) {
    if (state.length >= neededPicks) return false;
    if (state.contains(club)) return false;
    state = [...state, club];
    return true;
  }

  /// Mirrors `data-rm`: splice the entry out.
  void removeClub(int index) {
    if (index < 0 || index >= state.length) return;
    final next = [...state]..removeAt(index);
    state = next;
  }

  /// Mirrors `data-up`: swap with the previous entry. No-op at index 0.
  void moveUp(int index) {
    if (index <= 0 || index >= state.length) return;
    final next = [...state];
    final tmp = next[index - 1];
    next[index - 1] = next[index];
    next[index] = tmp;
    state = next;
  }

  /// Mirrors `data-down`: swap with the next entry. No-op at the last
  /// index.
  void moveDown(int index) {
    if (index < 0 || index >= state.length - 1) return;
    final next = [...state];
    final tmp = next[index + 1];
    next[index + 1] = next[index];
    next[index] = tmp;
    state = next;
  }

  /// Splice-and-reinsert equivalent of the JS's `bindRank()` drop handler
  /// for a rank-to-rank drag (`dragSrc==="rank"` branch) — kept here for
  /// parity/future use even though today's UI drives reordering through
  /// [moveUp]/[moveDown] only (see my_clubs_screen.dart's doc comment for
  /// why drag itself isn't wired up yet).
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final next = [...state];
    final item = next.removeAt(oldIndex);
    final target = oldIndex < newIndex ? newIndex - 1 : newIndex;
    next.insert(target, item);
    state = next;
  }

  /// Resets ranking — item 4 will call this with a previous submission's
  /// ranked list (minus the required club) on re-entry instead of empty;
  /// today it's always empty on first entry, so this exists but is
  /// unused until then.
  void reset([List<String> initial = const []]) {
    state = [...initial];
  }
}

final clubRankingProvider =
    NotifierProvider<ClubRankingController, List<String>>(
  ClubRankingController.new,
);

/// The persisted submission — Day 4 item 4. `null` means "never
/// submitted". Deliberately reads via `ref.read` in [build] (a one-time
/// initial value), not `ref.watch` — see [ClubsViewController]'s doc
/// comment for why: this provider's OWN state changes (via [submit])
/// need to be something callers explicitly react to at a specific point
/// in a transition, not something that silently reaches into and
/// overwrites [ClubsViewController]'s state via an automatic rebuild.
class ClubSubmissionController extends Notifier<StudentClubSelection?> {
  @override
  StudentClubSelection? build() {
    return ref.read(studentClubsRepositoryProvider).loadSelection();
  }

  /// "Confirm & submit ✓" — persists [anchorMajor] (the MAJOR name, not
  /// the club — see [StudentClubSelection]'s doc comment) and
  /// [rankedOthers] exactly as ranked, with a fresh timestamp. Trusts the
  /// caller to only invoke this once item 2's "Generate my week" gate has
  /// already confirmed the ranking is full — no redundant re-validation
  /// here, same as the rest of this feature trusting its own UI gates.
  Future<void> submit({
    required String anchorMajor,
    required List<String> rankedOthers,
  }) async {
    final selection = StudentClubSelection(
      anchorMajor: anchorMajor,
      rankedOthers: [...rankedOthers],
      submittedAt: DateTime.now(),
    );
    await ref.read(studentClubsRepositoryProvider).saveSelection(selection);
    state = selection;
  }
}

final clubSubmissionProvider =
    NotifierProvider<ClubSubmissionController, StudentClubSelection?>(
  ClubSubmissionController.new,
);

/// Which sub-view My Clubs is currently showing — Day 4 items 3–4.
///
/// Mirrors the JS's `sstate` variable as it applies within My Clubs
/// specifically (`"clubs"`/`"confirm"`/`"myschedule"`), kept as Riverpod
/// state rather than local widget state for the same reason
/// [clubRankingProvider] is: a plain `Notifier`, not autoDispose, so
/// [startMakingChanges] can drive this same state from outside the
/// widget tree without needing to convert `MyClubsScreen` into a
/// `StatefulWidget` just to hold it.
///
/// [currentSchedule] is the flow spec's "Your Current Schedule" node —
/// the ACTUAL reachable re-entry behavior (`renderMySchedule()` in the
/// JS), not the dead `renderReturning()` function nothing ever calls
/// (verified by grepping every `sstate=` assignment in the full source —
/// nothing ever sets it to `"returning"`). [submitted] is the one-time
/// "Submitted!" success card shown immediately after a fresh submit —
/// distinct from [currentSchedule], which is what re-entry shows on
/// every visit AFTER that first moment has passed.
enum ClubsView { currentSchedule, ranking, preview, submitted }

class ClubsViewController extends Notifier<ClubsView> {
  /// Deliberately `ref.read`, not `ref.watch` — this decides the
  /// STARTING view once, when the provider is first created. If this
  /// watched `clubSubmissionProvider` instead, then every time [submit]
  /// writes a new selection, Riverpod would rebuild THIS controller from
  /// scratch too (since it's a declared dependency) — which would
  /// silently reset `state` back to whatever `build()` computes
  /// ([ClubsView.currentSchedule], now that a submission exists),
  /// clobbering the explicit `showSubmitted()` call [submit]'s caller
  /// makes right after, in a way that depends on exact rebuild-ordering
  /// timing rather than being deterministic. Reading once and driving
  /// every later transition through explicit method calls avoids that
  /// race entirely — exactly the kind of state-transition bug this
  /// project's Day 3 note warned unit tests alone can miss.
  @override
  ClubsView build() {
    final hasSubmission = ref.read(clubSubmissionProvider) != null;
    return hasSubmission ? ClubsView.currentSchedule : ClubsView.ranking;
  }

  /// "Generate my week →" — only ever called once the ranking is full
  /// (item 2's gate already enforces that before this is reachable).
  void showPreview() => state = ClubsView.preview;

  /// "← Edit ranking" — deliberately does NOT touch clubRankingProvider's
  /// state at all; going back to edit should show exactly what was
  /// ranked before, not reset it.
  void editRanking() => state = ClubsView.ranking;

  /// Re-entry landing state once a submission exists — see [build]'s doc
  /// comment for the currentSchedule-vs-submitted distinction. Also
  /// called explicitly when LEAVING the one-time [submitted] card (see
  /// `_SubmittedSection`'s "Back to home" handler), so that returning to
  /// My Clubs later lands here instead of showing "Submitted!" again.
  void showCurrentSchedule() => state = ClubsView.currentSchedule;

  /// The one-time post-submit success card — called by
  /// [ClubSubmissionController.submit]'s caller immediately after a
  /// successful submit.
  void showSubmitted() => state = ClubsView.submitted;
}

final clubsViewProvider = NotifierProvider<ClubsViewController, ClubsView>(
  ClubsViewController.new,
);

/// "Make Changes" (item 4) — pre-fills the ranking from the prior
/// submission, stripped of whatever the CURRENT required club is (in
/// case the anchor changed since submitting — same defensive filter as
/// the JS's `reEdit`/`mEdit` handlers: `ranking=(s.ranked||[])
/// .filter(c=>c!==MAJOR_CLUB[am])`), then switches to the ranking view.
///
/// A plain top-level function rather than a method on any single
/// controller, since it coordinates three: reads the persisted
/// submission, resets [clubRankingProvider], switches [clubsViewProvider].
/// Deliberately does NOT need to special-case "anchor is now null" the
/// way the JS's handler does (`sstate=am?"clubs":"unipath"`) —
/// `MyClubsScreen`'s existing top-level anchor-null gate already shows
/// the "choose anchor first" prompt regardless of `clubsViewProvider`'s
/// value, so switching to [ClubsView.ranking] here is sufficient; the
/// gate above it in the widget tree handles the rest.
void startMakingChanges(WidgetRef ref) {
  final selection = ref.read(clubSubmissionProvider);
  final requiredClub = ref.read(requiredClubProvider);
  final priorRanked = selection?.rankedOthers ?? const <String>[];
  final filtered = priorRanked.where((c) => c != requiredClub).toList();
  ref.read(clubRankingProvider.notifier).reset(filtered);
  ref.read(clubsViewProvider.notifier).editRanking();
}