import 'package:flutter_test/flutter_test.dart';
import 'package:runata_pathway/features/student/domain/club_catalog.dart';
import 'package:runata_pathway/features/student/domain/club_schedule_preview.dart';

/// Coverage note, read before adding more branches here: two of
/// `previewClubWeek`'s branches — [ClubSubstitutionType.requiredOverCapacity]
/// and a fully-waitlisted [ClubPlanKind.open] with NO backup able to take
/// it — are ported faithfully from the JS for correctness/fidelity, but
/// appear to be unreachable with the school's actual current club/teacher
/// data (working through it: forcing either requires at least 2 clubs
/// tightly-constrained enough to starve out a 3rd, and the only two
/// genuinely single-day-constrained clubs in the real table — Art &
/// Design Studio and Architecture & Built Env Club — share the exact
/// same teacher and day, so at most one collision, never a full
/// starve-out, is constructible from real data). Not tested here for
/// that reason, same as `club_schedule_preview.dart`'s own inline
/// comments flag — worth a synthetic/decoupled test if the real
/// club/teacher table ever changes to make them reachable.
void main() {
  group('previewClubWeek — perfect weeks (no clash at all)', () {
    test('Grade 10: required + 1 scheduled choice, backup left unused', () {
      final preview = previewClubWeek(
        requiredClub: 'Coding & ICT Club',
        rankedOthers: const ['Sports Club', 'Music Club'],
        sessionDays: sessionDaysFor(ClubSessionBand.grade10),
      );

      expect(preview.isPerfect, isTrue);
      expect(preview.plan, hasLength(2));
      expect(preview.plan[0].day, 'Monday');
      expect(preview.plan[0].club, 'Coding & ICT Club');
      expect(preview.plan[0].kind, ClubPlanKind.required);
      expect(preview.plan[1].day, 'Tuesday');
      expect(preview.plan[1].club, 'Sports Club');
      expect(preview.plan[1].kind, ClubPlanKind.choice);
      // Music Club was ranked as the backup but never needed — it
      // shouldn't appear in the plan at all.
      expect(preview.plan.any((e) => e.club == 'Music Club'), isFalse);
    });

    test('Grade 11/12: required + 2 scheduled choices, backup left unused',
        () {
      final preview = previewClubWeek(
        requiredClub: 'Coding & ICT Club',
        rankedOthers: const ['Sports Club', 'Music Club', 'Debate & MUN Club'],
        sessionDays: sessionDaysFor(ClubSessionBand.grade1112),
      );

      expect(preview.isPerfect, isTrue);
      expect(preview.plan, hasLength(3));
      expect(preview.plan.map((e) => e.day), ['Tuesday', 'Wednesday', 'Friday']);
      expect(preview.plan[0].club, 'Coding & ICT Club');
      expect(preview.plan[0].kind, ClubPlanKind.required);
      expect(preview.plan[1].club, 'Sports Club');
      expect(preview.plan[2].club, 'Music Club');
      expect(
          preview.plan.any((e) => e.club == 'Debate & MUN Club'), isFalse);
    });
  });

  group('previewClubWeek — real own-schedule clash, resolved via backup', () {
    test(
        'Grade 11/12: required and a ranked choice sharing the only day '
        "their shared teacher covers — the choice gets bumped to backup, "
        "reported as a 'clash' (not 'full', since capacity is stubbed)",
        () {
      // Architecture & Built Env Club AND Art & Design Studio are both
      // 'art' track, both taught only by Ms Audrey — for Grade 11/12's
      // session days (Tue/Wed/Fri), that intersects to Friday only, for
      // BOTH clubs. Ranking the second alongside the first as required
      // forces a genuine same-teacher, same-day collision using real
      // school data, not a synthetic one.
      final preview = previewClubWeek(
        requiredClub: 'Architecture & Built Env Club',
        rankedOthers: const [
          'Art & Design Studio',
          'Sports Club',
          'Music Club',
        ],
        sessionDays: sessionDaysFor(ClubSessionBand.grade1112),
      );

      expect(preview.isPerfect, isFalse);
      expect(preview.substitutions, hasLength(1));
      final sub = preview.substitutions.single;
      expect(sub.type, ClubSubstitutionType.swap);
      expect(sub.from, 'Art & Design Studio');
      expect(sub.to, 'Music Club');
      expect(sub.reason, 'clash');

      // The required club still gets its only possible day (Friday);
      // the bumped choice's backup (Music Club) picks up an early day
      // instead, and Sports Club (the 2nd choice) fills the remaining
      // slot — nothing is dropped, everyone still has 3 days scheduled.
      expect(preview.plan, hasLength(3));
      expect(
        preview.plan.firstWhere((e) => e.club == 'Architecture & Built Env Club').day,
        'Friday',
      );
      expect(
        preview.plan.firstWhere((e) => e.club == 'Music Club').kind,
        ClubPlanKind.backup,
      );
      expect(
        preview.plan.firstWhere((e) => e.club == 'Music Club').fromClub,
        'Art & Design Studio',
      );
    });
  });

  group('previewClubWeek — the injectable hasRoom seam actually works', () {
    test(
        "a simulated capacity-full club gets swapped for its backup even "
        "with ZERO schedule clash, and is reported as 'full' — proving "
        "clash-detection and capacity are cleanly separated concerns",
        () {
      final preview = previewClubWeek(
        requiredClub: 'Coding & ICT Club',
        rankedOthers: const ['Sports Club', 'Music Club'],
        sessionDays: sessionDaysFor(ClubSessionBand.grade10),
        // Simulate "Sports Club is always full" — nothing here has any
        // day-availability clash; every club could actually run every
        // day. This isn't reachable through alwaysHasRoomStub (which
        // production code always uses) — it exists to prove the seam
        // itself is wired correctly and ready for a real cohort-aware
        // implementation to be dropped in later.
        hasRoom: (club, day) => club != 'Sports Club',
      );

      expect(preview.isPerfect, isFalse);
      final sub = preview.substitutions.single;
      expect(sub.type, ClubSubstitutionType.swap);
      expect(sub.from, 'Sports Club');
      expect(sub.to, 'Music Club');
      expect(sub.reason, 'full');
    });

    test('alwaysHasRoomStub always returns true', () {
      expect(alwaysHasRoomStub('Any Club', 'Monday'), isTrue);
      expect(alwaysHasRoomStub('Another Club', 'Friday'), isTrue);
    });
  });

  group('previewClubWeek — defensive behavior', () {
    test('a shorter-than-needed ranking does not crash (never produced by '
        'the UI — item 2\'s gate always hands in a full ranking — but '
        'this function should degrade gracefully rather than throw)', () {
      final preview = previewClubWeek(
        requiredClub: 'Coding & ICT Club',
        rankedOthers: const [],
        sessionDays: sessionDaysFor(ClubSessionBand.grade10),
      );

      expect(preview.plan, hasLength(1));
      expect(preview.plan.single.club, 'Coding & ICT Club');
      expect(preview.plan.single.kind, ClubPlanKind.required);
      expect(preview.isPerfect, isTrue);
    });

    test('an empty sessionDays list does not crash', () {
      final preview = previewClubWeek(
        requiredClub: 'Coding & ICT Club',
        rankedOthers: const ['Sports Club'],
        sessionDays: const [],
      );

      // Degenerate input, not a realistic band (every real band has 2 or
      // 3 days) — `wanted = [...].slice(0, sessionDays.length)` drops
      // even the required club when sessionDays.length is 0, exactly
      // matching the JS's own `.slice(0,0)` behavior. The only thing
      // this test actually checks is that nothing throws.
      expect(preview.plan, isEmpty);
      expect(preview.isPerfect, isTrue);
    });
  });
}
