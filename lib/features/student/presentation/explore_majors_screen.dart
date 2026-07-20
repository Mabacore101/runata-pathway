import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../application/majors_controller.dart';
import '../domain/major_entry.dart';
import '../domain/majors_catalog.dart';

/// Explore Majors — Target Universities tab 1. Every action here saves
/// immediately (see majors_controller.dart) — no separate Save button.
///
/// Supplies its own Scaffold/AppBar rather than relying on the router to
/// wrap it — same convention TestsScreen/GradesScreen/ProfileScreen use.
/// (Earlier version left this bare, which rendered with no Material
/// surface at all once routed directly — the widget tests didn't catch
/// it because their harness manually wrapped it in a Scaffold.)
class ExploreMajorsScreen extends ConsumerWidget {
  const ExploreMajorsScreen({super.key, this.onContinue});

  /// Left as a callback rather than a hardcoded go_router call so this
  /// screen doesn't need the Find Universities route to exist yet.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(majorsControllerProvider);
    final controller = ref.read(majorsControllerProvider.notifier);
    final majors = settings.majors;
    final addable = majorCatalog
        .where((c) => !majors.any((m) => m.major == c.major))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Majors')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('🎓', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'Explore majors',
                  style: AppFonts.display(fontSize: 20, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Add up to 6 majors with a target country, mark your Top 3, '
              'then choose 1 anchor. Your anchor sets your required club.',
              style: AppFonts.body(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            Text(
              'Majors offered — explore what each is about',
              style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in majorCatalog) _MajorCatalogCard(entry: c),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Selected ${majors.length}/6 · Top 3 marked ${settings.topMarked.length}/3 · '
              'Anchor ${settings.anchor?.major ?? "not set"}',
              style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),

            if (majors.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No majors yet — add some below.',
                  style: AppFonts.body(color: AppColors.muted),
                ),
              )
            else
              for (var i = 0; i < majors.length; i++) ...[
                _MajorRow(
                  entry: majors[i],
                  description:
                      catalogEntryFor(majors[i].major)?.description ?? '',
                  onToggleTop: () async {
                    final ok = await controller.toggleTop(i);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('You can mark only 3 as Top 3')),
                      );
                    }
                  },
                  onSetAnchor: () => controller.setAnchor(i),
                  onRemove: () => controller.removeMajor(i),
                ),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: settings.readyToContinue ? onContinue : null,
              child: const Text('Continue to universities →'),
            ),
            if (!settings.readyToContinue)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mark exactly 3 majors as Top 3 and choose 1 anchor to continue.',
                  style: AppFonts.body(fontSize: 11.5, color: AppColors.muted),
                ),
              ),
            const SizedBox(height: 24),

            Text(
              'Add a major',
              style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            if (majors.length >= 6)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You have added 6 majors (the maximum).',
                  style: AppFonts.body(color: AppColors.muted),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in addable)
                    OutlinedButton(
                      onPressed: () => controller.addMajor(c.major),
                      child: Text('+ ${c.major}'),
                    ),
                ],
              ),
            const SizedBox(height: 24),

            OutlinedButton(
              onPressed: () => context.go(AppRoutes.studentHome),
              child: const Text('← Back to home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MajorCatalogCard extends StatelessWidget {
  const _MajorCatalogCard({required this.entry});
  final MajorCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.major,
              style: AppFonts.display(fontSize: 14.5, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(
            entry.field,
            style: AppFonts.mono(
              fontSize: 10.5,
              weight: FontWeight.w700,
              color: AppColors.tealDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(entry.description,
              style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft)),
          if (entry.jobs.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Careers: ',
                    style: AppFonts.body(
                      fontSize: 11,
                      weight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  TextSpan(
                    text: entry.jobs,
                    style: AppFonts.body(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MajorRow extends StatelessWidget {
  const _MajorRow({
    required this.entry,
    required this.description,
    required this.onToggleTop,
    required this.onSetAnchor,
    required this.onRemove,
  });

  final MajorEntry entry;
  final String description;
  final VoidCallback onToggleTop;
  final VoidCallback onSetAnchor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Anchor gets its own orange styling, distinct from plain Top-3 teal
    // — matches the original site's `.pwrow.anchor` orange highlight
    // (layered on top of `.pwrow.top`'s teal, since a major must already
    // be Top-marked before it can be the anchor). Previously this row
    // only branched on `entry.top`, so the anchor looked identical to
    // any other Top 3 major — the Anchor button's own label
    // ('● Anchor' vs 'Anchor') was the only visual cue.
    final Color background;
    final Color border;
    if (entry.anchor) {
      background = AppColors.orangeSoft;
      border = AppColors.orange;
    } else if (entry.top) {
      background = AppColors.tealSoft;
      border = AppColors.teal;
    } else {
      background = const Color(0xFFE7F3F0);
      border = const Color(0xFFC3E1DB);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: entry.anchor ? 1.5 : 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.major,
                    style: AppFonts.body(weight: FontWeight.w700, fontSize: 13.5)),
              ),
              TextButton(
                  onPressed: onToggleTop,
                  child: Text(entry.top ? '★ Top 3' : '☆ Top 3')),
              TextButton(
                onPressed: entry.top ? onSetAnchor : null,
                child: Text(entry.anchor ? '● Anchor' : 'Anchor'),
              ),
              IconButton(icon: const Icon(Icons.close, size: 16), onPressed: onRemove),
            ],
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(description,
                  style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft)),
            ),
        ],
      ),
    );
  }
}