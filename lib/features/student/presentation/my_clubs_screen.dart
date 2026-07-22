import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/clubs_controller.dart';
import '../application/majors_controller.dart';
import '../domain/club_catalog.dart';
import '../domain/club_schedule_preview.dart';

/// My Clubs — Pathway form 3.
///
/// TODAY'S SCOPE (Day 4 item 3 of 5, building on items 1–2): required-club
/// display and Rank Other Clubs are unchanged from before. New today:
/// "Generate my week →" now actually switches to a real Preview/Confirm
/// sub-view (`clubsViewProvider` — `ClubsView.ranking` vs
/// `ClubsView.preview`, both sub-states of this ONE screen, not separate
/// routes, per the flow spec) showing `previewClubWeek`'s output —
/// real, per-student clash-detection in full (a student can't be in two
/// clubs on the same day), with cross-student capacity stubbed via
/// `alwaysHasRoomStub` until a backend exists to check real cohort seat
/// counts against (club_schedule_preview.dart's file doc comment).
///
/// "Confirm & submit ✓" on the preview is still a temporary SnackBar —
/// actually persisting the submission and the re-entry/"Make Changes"
/// loop are item 4's scope, not today's. The "no anchor yet" state is
/// still the flow spec's `[Anchor Major Set?]` diamond — an IN-SCREEN
/// prompt with a button, re-evaluated fresh every time My Clubs is
/// entered, NOT a router-level redirect like the auth guard in
/// app_router.dart.
class MyClubsScreen extends ConsumerWidget {
  const MyClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(majorsControllerProvider).anchor;
    final requiredClub = ref.watch(requiredClubProvider);
    final grade = ref.watch(authControllerProvider).session?.grade ?? '10';
    final band = sessionBandForGrade(grade);
    final view = ref.watch(clubsViewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Clubs')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (anchor == null || requiredClub == null)
              _NoAnchorPrompt(
                onGoToUniversities: () =>
                    context.push(AppRoutes.studentTargetUniversities),
                onBackToHome: () => context.go(AppRoutes.studentHome),
              )
            else if (view == ClubsView.preview) ...[
              _WeekPreviewSection(requiredClub: requiredClub, band: band),
            ] else ...[
              _RequiredClubSection(
                club: requiredClub,
                anchorMajor: anchor.major,
                daysLabel: daysLabel(requiredClub, sessionDaysFor(band)),
              ),
              const SizedBox(height: 24),
              _RankOtherClubsSection(requiredClub: requiredClub, band: band),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoAnchorPrompt extends StatelessWidget {
  const _NoAnchorPrompt({
    required this.onGoToUniversities,
    required this.onBackToHome,
  });

  final VoidCallback onGoToUniversities;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎯', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Choose your anchor major first',
                style: AppFonts.display(fontSize: 18, color: AppColors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Your required club comes from your anchor major. Head to '
          'Target Universities, add your majors, mark your Top 3, and '
          'pick 1 anchor — then come back here.',
          style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onGoToUniversities,
          child: const Text('Go to Target universities →'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: onBackToHome,
          child: const Text('← Back to home'),
        ),
      ],
    );
  }
}

class _RequiredClubSection extends StatelessWidget {
  const _RequiredClubSection({
    required this.club,
    required this.anchorMajor,
    required this.daysLabel,
  });

  final String club;
  final String anchorMajor;
  final String daysLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🗓️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Your required club',
                style: AppFonts.display(fontSize: 18, color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Set from your anchor major — mandatory, can't be removed.",
          style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tealSoft,
            border: Border.all(color: AppColors.teal),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club,
                        style:
                            AppFonts.display(fontSize: 16, color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(
                        style:
                            AppFonts.body(fontSize: 12, color: AppColors.inkSoft),
                        children: [
                          const TextSpan(text: 'From your anchor major '),
                          TextSpan(
                            text: anchorMajor,
                            style: AppFonts.body(
                                fontSize: 12,
                                weight: FontWeight.w700,
                                color: AppColors.tealDeep),
                          ),
                          const TextSpan(text: ' · runs '),
                          TextSpan(
                            text: daysLabel,
                            style: AppFonts.body(
                                fontSize: 12,
                                weight: FontWeight.w700,
                                color: AppColors.tealDeep),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const _LockPill(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LockPill extends StatelessWidget {
  const _LockPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.teal),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 11, color: AppColors.tealDeep),
          const SizedBox(width: 4),
          Text('LOCKED',
              style: AppFonts.mono(
                  fontSize: 9,
                  weight: FontWeight.w600,
                  color: AppColors.tealDeep,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }
}

/// Rank Other Clubs (Day 4 item 2) — grade-dependent pick count, live
/// ranked list with reorder/remove, addable pool, and the "Generate my
/// week →" gate.
///
/// Reorder today is arrow-buttons only (`_RankedClubTile`'s ▲▼), not an
/// actual drag gesture. The JS offers both as equivalent paths ("Ranked…
/// drag or use ▲▼"), but a real drag here would mean a `ReorderableListView`
/// nested inside this screen's outer scrolling `ListView` — a genuine
/// bounded-height footgun (shrinkWrap + physics juggling) for a second
/// path to behavior the arrow buttons already fully cover. Flagged as a
/// deliberate scope trim, not a silent omission — `ClubRankingController
/// .reorder()` already exists in clubs_controller.dart if drag gets added
/// later.
class _RankOtherClubsSection extends ConsumerWidget {
  const _RankOtherClubsSection({
    required this.requiredClub,
    required this.band,
  });

  final String requiredClub;
  final ClubSessionBand band;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(clubRankingProvider);
    final controller = ref.read(clubRankingProvider.notifier);
    final sessionDays = sessionDaysFor(band);
    final needed = neededPicksFor(band);
    final scheduledSlots = scheduledSlotsFor(band);
    final full = ranking.length >= needed;
    final pool = addableClubsFor(
      requiredClub: requiredClub,
      sessionDays: sessionDays,
      alreadyRanked: ranking,
    );

    // Matches the JS's own grade-branched copy verbatim in spirit:
    // `stu.key==="1112" ? "Pick 3 in order…" : "Pick 2 in order…"`.
    final description = band == ClubSessionBand.grade1112
        ? 'Pick 3 in order — choices 2 & 3 get scheduled, choice 4 is your backup.'
        : 'Pick 2 in order — choice 2 gets scheduled, choice 3 is your backup.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📋', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Rank your other clubs',
                style: AppFonts.display(fontSize: 18, color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 4),
        Text(description,
            style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 12),
        Text(
          'Ranked ${ranking.length > needed ? needed : ranking.length}/$needed',
          style: AppFonts.body(
              fontSize: 12.5, weight: FontWeight.w700, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        if (ranking.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Add clubs from below',
                style: AppFonts.body(color: AppColors.muted)),
          )
        else
          for (var i = 0; i < ranking.length; i++) ...[
            if (i == scheduledSlots)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'BACKUP — USED ONLY IF A CHOICE ABOVE IS FULL',
                        style: AppFonts.mono(
                            fontSize: 8.5,
                            color: AppColors.muted,
                            letterSpacing: 0.4),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
            _RankedClubTile(
              club: ranking[i],
              positionLabel: i >= scheduledSlots ? 'BACKUP' : 'CHOICE ${i + 2}',
              isBackup: i >= scheduledSlots,
              daysLabel: daysLabel(ranking[i], sessionDays),
              canMoveUp: i > 0,
              canMoveDown: i < ranking.length - 1,
              onMoveUp: () => controller.moveUp(i),
              onMoveDown: () => controller.moveDown(i),
              onRemove: () => controller.removeClub(i),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 12),
        Text(
          full ? 'Ranking full — remove one to swap' : 'Add more clubs',
          style: AppFonts.body(
              fontSize: 12, weight: FontWeight.w700, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        if (pool.isEmpty)
          Text('All clubs added.', style: AppFonts.body(color: AppColors.muted))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final club in pool)
                OutlinedButton(
                  onPressed:
                      full ? null : () => controller.addClub(club, needed),
                  child: Text('+ $club'),
                ),
            ],
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: full ? () => ref.read(clubsViewProvider.notifier).showPreview() : null,
          child: const Text('Generate my week →'),
        ),
        if (!full)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Rank $needed clubs to continue.',
                style: AppFonts.body(fontSize: 11.5, color: AppColors.muted)),
          ),
      ],
    );
  }
}

class _RankedClubTile extends StatelessWidget {
  const _RankedClubTile({
    required this.club,
    required this.positionLabel,
    required this.isBackup,
    required this.daysLabel,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final String club;
  final String positionLabel;
  final bool isBackup;
  final String daysLabel;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isBackup ? AppColors.muted : AppColors.teal,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              positionLabel,
              style: AppFonts.mono(
                fontSize: 9,
                weight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club,
                    style:
                        AppFonts.body(weight: FontWeight.w600, fontSize: 13.5)),
                Text('runs $daysLabel',
                    style: AppFonts.mono(fontSize: 9.5, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 22,
                child: IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: canMoveUp ? onMoveUp : null,
                ),
              ),
              SizedBox(
                width: 28,
                height: 22,
                child: IconButton(
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: canMoveDown ? onMoveDown : null,
                ),
              ),
            ],
          ),
          IconButton(
            iconSize: 16,
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Preview/Confirm (item 3) — shows `previewClubWeek`'s output: real,
/// per-student clash-detection in full, cross-student capacity stubbed
/// (see club_schedule_preview.dart's file doc comment for the exact
/// seam). Recomputed inline on every build from the current ranking —
/// same "always re-derive, never cache" precedent as
/// `requiredClubProvider` and the rest of this feature, not wrapped in
/// its own provider since it's cheap, pure, and this is the only place
/// that reads it today.
class _WeekPreviewSection extends ConsumerWidget {
  const _WeekPreviewSection({
    required this.requiredClub,
    required this.band,
  });

  final String requiredClub;
  final ClubSessionBand band;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranking = ref.watch(clubRankingProvider);
    final preview = previewClubWeek(
      requiredClub: requiredClub,
      rankedOthers: ranking,
      sessionDays: sessionDaysFor(band),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Text('Your week',
                style: AppFonts.display(fontSize: 18, color: AppColors.ink)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Review and confirm.',
            style: AppFonts.body(fontSize: 13, color: AppColors.inkSoft)),
        const SizedBox(height: 12),
        _PreviewNote(preview: preview),
        const SizedBox(height: 12),
        for (final entry in preview.plan) ...[
          _DayPlanTile(entry: entry),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    ref.read(clubsViewProvider.notifier).editRanking(),
                child: const Text('← Edit ranking'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // TEMPORARY — item 4 (submit + re-entry) hasn't been
                  // built yet. This proves the preview itself renders
                  // correctly; actually persisting the submission and
                  // enabling re-entry/"Make Changes" replaces this
                  // SnackBar once that item lands.
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Submit is coming in the next item'),
                    ),
                  );
                },
                child: const Text('Confirm & submit ✓'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewNote extends StatelessWidget {
  const _PreviewNote({required this.preview});
  final ClubWeekPreview preview;

  @override
  Widget build(BuildContext context) {
    if (preview.isPerfect) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.greenSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Perfect — you got all your picks.',
                style: AppFonts.body(
                    weight: FontWeight.w700, fontSize: 13, color: AppColors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We adjusted one of your picks:',
                  style: AppFonts.body(
                      weight: FontWeight.w700, fontSize: 13, color: AppColors.amber),
                ),
                const SizedBox(height: 4),
                for (final s in preview.substitutions)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _substitutionMessage(s),
                      style: AppFonts.body(fontSize: 12.5, color: AppColors.amber),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _substitutionMessage(ClubSubstitution s) {
    switch (s.type) {
      case ClubSubstitutionType.swap:
        final why = s.reason == 'full'
            ? 'was full on your available day'
            : 'was only on a day already taken';
        return '${s.from} $why, so we scheduled your backup ${s.to} instead.';
      case ClubSubstitutionType.open:
        return "${s.from} couldn't be placed — you'll be waitlisted.";
      case ClubSubstitutionType.requiredOverCapacity:
        return '${s.club} (required) is over capacity — a second class will be opened.';
    }
  }
}

class _DayPlanTile extends StatelessWidget {
  const _DayPlanTile({required this.entry});
  final ClubPlanEntry entry;

  @override
  Widget build(BuildContext context) {
    late final String badgeLabel;
    late final Color badgeColor;
    switch (entry.kind) {
      case ClubPlanKind.required:
        badgeLabel = 'Required';
        badgeColor = AppColors.teal;
        break;
      case ClubPlanKind.backup:
        badgeLabel = 'Backup';
        badgeColor = AppColors.amber;
        break;
      case ClubPlanKind.open:
        badgeLabel = 'Waitlist';
        badgeColor = AppColors.red;
        break;
      case ClubPlanKind.choice:
        badgeLabel = 'Your choice';
        badgeColor = AppColors.tealDeep;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(entry.day,
                style: AppFonts.body(weight: FontWeight.w700, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              entry.club ?? '${entry.fromClub ?? ''} — waitlisted',
              style: AppFonts.body(fontSize: 13.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeLabel,
              style: AppFonts.mono(
                  fontSize: 9.5, weight: FontWeight.w700, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }
}