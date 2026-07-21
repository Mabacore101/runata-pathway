import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/club_catalog.dart';
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
