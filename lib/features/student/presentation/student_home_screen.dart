import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
 
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';

/// Day 1 scope note: the reference source's real homepage packs a
/// "My dashboard" CTA, a 6-step Pathway roadmap card, AND an 8-tile nav
/// grid all onto one screen — but almost every one of those tiles points
/// at a Pathway form that doesn't exist yet (those land Day 2–6). Building
/// that full layout today would mean most of it dead-ends. So this collapses
/// to the spec's 3 peer entry points (Dashboard / Pathway / Navigation Grid)
/// as clearly separated cards, each wired to a real, reachable stub screen.
/// The fuller homepage layout is worth revisiting once the 6 forms exist.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final firstName = (session?.name ?? 'Student').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runata Pathway'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hi $firstName 👋',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Your Runata clubs & university pathway — jump to any section.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _EntryPointCard(
              icon: '✨',
              title: 'My dashboard',
              subtitle: 'Your whole profile & fit in one place',
              onTap: () => context.go(AppRoutes.studentDashboard),
            ),
            const SizedBox(height: 12),
            _EntryPointCard(
              icon: '🪜',
              title: 'Pathway',
              subtitle:
                  '6 forms — profile, universities, clubs, tests, grades, materials',
              onTap: () => context.go(AppRoutes.studentPathway),
            ),
            const SizedBox(height: 12),
            _EntryPointCard(
              icon: '🗂️',
              title: 'Navigation grid',
              subtitle: "All sections, plus Counsellor's Corner & Pathways",
              onTap: () => context.go(AppRoutes.studentNavGrid),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _signOut(context, ref),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  void _signOut(BuildContext context, WidgetRef ref) {
    ref.read(authControllerProvider.notifier).signOut();
    context.go(AppRoutes.chooseRole);
  }
}

class _EntryPointCard extends StatelessWidget {
  const _EntryPointCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
