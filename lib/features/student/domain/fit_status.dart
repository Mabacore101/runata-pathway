import 'test_entry.dart';
import 'university_catalog.dart';

/// Which of the 4 visual tiers a fit result falls into — maps 1:1 to the
/// JS's `fit-met` / `fit-track` / `fit-work` / `fit-none` CSS classes
/// (day1-trimmed-reference.md).
enum FitTier { met, track, work, none }

class FitStatus {
  const FitStatus({required this.label, required this.tier});
  final String label;
  final FitTier tier;
}

/// Mirrors the JS `fitStatus(u, sc, country)`. [studentIelts] should come
/// from the student's actual My Tests IELTS row (`TestEntry.latest`,
/// parsed as a double) — NOT a separate stored score, since the JS's
/// `sc.ielts` is that same underlying value read from a different angle.
///
/// The `gap > 0.5` branch (`FitTier.work`, "Needs work") is INFERRED —
/// day3-trimmed-source.md's source cuts off mid-function exactly at the
/// `gap<=0.5` check, before showing the final `else`. The label/tier are
/// filled in from day1-trimmed-reference.md's CSS, which already defines
/// `.fit-work{background:var(--amber-soft);color:var(--amber)}` — a 4th
/// tier clearly exists, this is the most natural reading of what it says,
/// but it wasn't confirmed verbatim from source the way the other 3 were.
FitStatus fitStatusFor(UniversityEntry uni, double? studentIelts) {
  if (uni.ielts == null) {
    return const FitStatus(label: 'See requirements', tier: FitTier.none);
  }
  if (studentIelts == null) {
    return const FitStatus(label: 'Add IELTS', tier: FitTier.none);
  }

  final gap = double.parse((uni.ielts! - studentIelts).toStringAsFixed(1));
  if (gap <= 0) return const FitStatus(label: 'Met', tier: FitTier.met);
  if (gap <= 0.5) return const FitStatus(label: 'On track', tier: FitTier.track);
  return const FitStatus(label: 'Needs work', tier: FitTier.work);
}

/// Mirrors the JS's `sc.ielts` — pulled from the student's actual My
/// Tests IELTS row rather than a separate stored score. Returns null if
/// no IELTS row exists, or its `latest` text doesn't parse as a number
/// (matches JS's `isNaN(parseFloat(sc.ielts))` guard). Shared by Find
/// Universities and My Shortlist, since both show the same fit chip for
/// the same underlying reason.
double? studentIeltsScore(List<TestEntry> entries) {
  for (final t in entries) {
    if (t.type == TestType.ielts) {
      return t.latest != null ? double.tryParse(t.latest!) : null;
    }
  }
  return null;
}