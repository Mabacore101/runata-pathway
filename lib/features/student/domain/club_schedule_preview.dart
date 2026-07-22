/// Per-student week preview — Day 4 item 3.
library;

import 'club_catalog.dart';

/// Ports the JS's `previewPlan()`, MINUS cross-student capacity: the JS
/// tracks a live roster count per club/day (`cnt`) against a seat cap
/// (`cap` — 24 or 48 seats depending on how many qualified teachers are
/// on duty that day) to decide whether a club is already full. That
/// comparison only means something against a cohort of OTHER students'
/// committed schedules, and no backend exists yet to supply that
/// (day4-trimmed-source.md's "Read this first" #2 — the resolved
/// decision: implement real clash-detection in full, stub only the
/// capacity check). [hasRoom] is that one isolated seam — it always
/// returns true today, and is the ONLY thing a later day needs to swap
/// out; nothing else in this file changes when real cohort data exists.
///
/// What IS real today: a student can only be in one place at a time. If
/// two of their own ranked picks can only run on the same day, that's a
/// genuine clash this algorithm resolves via backup or waitlist — no
/// cross-student data needed for that, just this student's own ranked
/// list checked against [clubDays].

enum ClubPlanKind { required, choice, backup, open }

class ClubPlanEntry {
  const ClubPlanEntry({
    required this.day,
    required this.club,
    required this.kind,
    this.fromClub,
  });

  /// The session day this entry lands on.
  final String day;

  /// Null only when [kind] is [ClubPlanKind.open] — waitlisted, no day
  /// could be found at all (JS: `club:null`).
  final String? club;

  final ClubPlanKind kind;

  /// Which originally-ranked club this entry replaced — set when [kind]
  /// is [ClubPlanKind.backup] or [ClubPlanKind.open].
  final String? fromClub;
}

enum ClubSubstitutionType { swap, open, requiredOverCapacity }

class ClubSubstitution {
  const ClubSubstitution({
    required this.type,
    this.from,
    this.to,
    this.club,
    this.reason,
  });

  final ClubSubstitutionType type;
  final String? from;
  final String? to;
  final String? club;

  /// 'full' | 'clash' — mirrors the JS's own wording split ("full on your
  /// available day" vs "only on a day already taken"). Only 'clash' is
  /// actually reachable while [hasRoom] is stubbed to always allow —
  /// 'full' becomes reachable the moment real cohort capacity replaces
  /// the stub, with no other change needed here.
  final String? reason;
}

class ClubWeekPreview {
  const ClubWeekPreview({required this.plan, required this.substitutions});

  /// Sorted into calendar order via [dayIndex].
  final List<ClubPlanEntry> plan;
  final List<ClubSubstitution> substitutions;

  bool get isPerfect => substitutions.isEmpty;
}

/// Whether [club] has room on [day] for one more student — STUBBED, see
/// file doc comment. Always true today; this is the seam a later day
/// swaps for a real cohort-aware check.
bool alwaysHasRoomStub(String club, String day) => true;

class _ScheduleItem {
  _ScheduleItem({
    required this.club,
    required this.kind,
    required this.rank,
    required this.allowed,
  });
  final String club;
  final ClubPlanKind kind;
  final int rank;
  final List<String> allowed;
}

/// Builds a single student's week preview from their [requiredClub] and a
/// fully-ranked [rankedOthers] list. Assumes `rankedOthers.length` already
/// equals [neededPicksFor]'s count for [sessionDays]'s band — the
/// "Generate my week" gate (item 2) already enforces this before this is
/// ever called, but this function itself degrades gracefully (never
/// throws) if handed a shorter list, since that's useful for testing
/// individual branches in isolation.
ClubWeekPreview previewClubWeek({
  required String requiredClub,
  required List<String> rankedOthers,
  required List<String> sessionDays,
  bool Function(String club, String day) hasRoom = alwaysHasRoomStub,
}) {
  final choices = rankedOthers.where((c) => c != requiredClub).toList();
  final wantedAll = [requiredClub, ...choices];
  final wanted = wantedAll.length > sessionDays.length
      ? wantedAll.sublist(0, sessionDays.length)
      : wantedAll;
  final backupStart = sessionDays.length - 1;
  final backups = (backupStart >= 0 && backupStart < choices.length
          ? choices.sublist(backupStart)
          : const <String>[])
      .where((c) => !wanted.contains(c))
      .toList();

  final items = <_ScheduleItem>[
    for (var i = 0; i < wanted.length; i++)
      _ScheduleItem(
        club: wanted[i],
        kind: i == 0 ? ClubPlanKind.required : ClubPlanKind.choice,
        rank: i,
        allowed: clubDays(wanted[i], sessionDays),
      ),
  ]..sort((a, b) {
      // Greedy scheduling: the most-constrained club (fewest allowed
      // days) gets first pick of a day, so it doesn't get starved out by
      // a more flexible club claiming its only option. Ties favor the
      // required club, then original rank order — mirrors the JS's own
      // 3-key sort exactly.
      final byAllowed = a.allowed.length.compareTo(b.allowed.length);
      if (byAllowed != 0) return byAllowed;
      final aReq = a.kind == ClubPlanKind.required ? 0 : 1;
      final bReq = b.kind == ClubPlanKind.required ? 0 : 1;
      if (aReq != bReq) return aReq.compareTo(bReq);
      return a.rank.compareTo(b.rank);
    });

  final used = <String>{};
  final plan = <ClubPlanEntry>[];
  final subs = <ClubSubstitution>[];

  for (final item in items) {
    final free = item.allowed.where((d) => !used.contains(d)).toList();
    // With the capacity stub always allowing, `ok` is identical to
    // `free` today — kept as a separate step (rather than skipping
    // straight to `free`) so the seam is structural, not just a comment.
    final ok = free.where((d) => hasRoom(item.club, d)).toList();

    if (ok.isNotEmpty) {
      used.add(ok.first);
      plan.add(ClubPlanEntry(day: ok.first, club: item.club, kind: item.kind));
      continue;
    }

    if (item.kind == ClubPlanKind.required) {
      // Every one of the required club's allowed days got claimed by
      // higher-priority items first — double-book it onto whatever day
      // is least-bad rather than drop it; it's mandatory, it can't be
      // waitlisted. Unreachable with the current real club/teacher
      // table (see the test file's coverage note) but faithfully ported
      // from the JS regardless, since the underlying data could change.
      final day = free.isNotEmpty
          ? free.first
          : sessionDays.firstWhere(
              (d) => !used.contains(d),
              orElse: () => sessionDays.isNotEmpty ? sessionDays.first : '',
            );
      if (day.isNotEmpty) used.add(day);
      plan.add(ClubPlanEntry(day: day, club: item.club, kind: ClubPlanKind.required));
      subs.add(ClubSubstitution(
        type: ClubSubstitutionType.requiredOverCapacity,
        club: item.club,
      ));
      continue;
    }

    var placed = false;
    for (final backup in backups) {
      final availableDays = clubDays(backup, sessionDays)
          .where((d) => !used.contains(d) && hasRoom(backup, d))
          .toList();
      if (availableDays.isNotEmpty) {
        used.add(availableDays.first);
        plan.add(ClubPlanEntry(
          day: availableDays.first,
          club: backup,
          kind: ClubPlanKind.backup,
          fromClub: item.club,
        ));
        subs.add(ClubSubstitution(
          type: ClubSubstitutionType.swap,
          from: item.club,
          to: backup,
          reason: free.isEmpty ? 'clash' : 'full',
        ));
        placed = true;
        break;
      }
    }

    if (!placed) {
      // No backup could take it either — genuinely waitlisted. Same
      // unreachable-with-current-data caveat as the required-over-
      // capacity branch above.
      final day = sessionDays.firstWhere(
        (d) => !used.contains(d),
        orElse: () => '',
      );
      if (day.isNotEmpty) used.add(day);
      plan.add(ClubPlanEntry(
        day: day.isEmpty && sessionDays.isNotEmpty ? sessionDays.first : day,
        club: null,
        kind: ClubPlanKind.open,
        fromClub: item.club,
      ));
      subs.add(ClubSubstitution(
        type: ClubSubstitutionType.open,
        from: item.club,
        reason: free.isEmpty ? 'clash' : 'full',
      ));
    }
  }

  plan.sort((a, b) => dayIndex(a.day).compareTo(dayIndex(b.day)));

  return ClubWeekPreview(plan: plan, substitutions: subs);
}