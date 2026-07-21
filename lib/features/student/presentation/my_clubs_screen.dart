import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/clubs_controller.dart';
import '../application/majors_controller.dart';
import '../domain/club_catalog.dart';

/// My Clubs — Pathway form 3.
///
/// TODAY'S SCOPE (Day 4 item 1 of 5): required-club display only —
/// reading and showing whatever Day 3's anchor major already computed
/// (`requiredClubProvider`), plus the "no anchor yet" prompt state. This
/// is the flow spec's `[Anchor Major Set?]` diamond — an IN-SCREEN prompt
/// with a button, re-evaluated fresh every time My Clubs is entered, NOT
/// a router-level redirect like the auth guard in app_router.dart.
///
/// Ranking, preview/capacity, and submit/re-entry land in later items
/// today — this screen grows more internal state then (see
/// clubs_controller.dart).
class MyClubsScreen extends ConsumerWidget {
  const MyClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anchor = ref.watch(majorsControllerProvider).anchor;
    final requiredClub = ref.watch(requiredClubProvider);
    final grade = ref.watch(authControllerProvider).session?.grade ?? '10';

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
            else
              _RequiredClubSection(
                club: requiredClub,
                anchorMajor: anchor.major,
                daysLabel: daysLabel(
                  requiredClub,
                  sessionDaysFor(sessionBandForGrade(grade)),
                ),
              ),
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
