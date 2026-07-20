import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The student's last EXPLICIT major/country pick on Find Universities.
/// Either can be null (nothing picked yet this session).
///
/// This mirrors the JS's `uMajor`/`uCountry` — plain in-memory globals,
/// never written to `submissions`/`uni` storage. Deliberately NOT
/// Hive-backed for the same reason: it's "what am I currently browsing",
/// not student data. Unlike the JS, this doesn't get defensively
/// overwritten when it goes stale (e.g. the picked major gets un-Top'd) —
/// see find_universities_screen.dart's `_effectiveMajor`/
/// `_effectiveCountry` for how staleness is handled instead, by deriving
/// the actually-displayed value fresh on every read rather than mutating
/// this state to "correct" it.
class UniSelection {
  const UniSelection({this.major, this.country});
  final String? major;
  final String? country;
}

final uniSelectionProvider =
    NotifierProvider<UniSelectionController, UniSelection>(
  UniSelectionController.new,
);

class UniSelectionController extends Notifier<UniSelection> {
  @override
  UniSelection build() => const UniSelection();

  void selectMajor(String major) {
    state = UniSelection(major: major, country: state.country);
  }

  void selectCountry(String country) {
    state = UniSelection(major: state.major, country: country);
  }
}
