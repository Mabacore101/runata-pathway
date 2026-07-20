import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/majors_controller.dart';
import '../domain/major_entry.dart';
import '../domain/majors_catalog.dart';
import '../domain/university_catalog.dart' show uniCountries;

/// Explore Majors — Target Universities tab 1. Every action here saves
/// immediately (see majors_controller.dart) — no separate Save button.
///
/// Bare content, no own Scaffold/AppBar — this is now embedded as one tab
/// inside TargetUniversitiesScreen, which supplies the shared Scaffold/
/// AppBar/TabBar for all of Explore Majors / Find Universities / My
/// Shortlist. (An earlier version gave this screen its own Scaffold when
/// it was still a standalone route — see target_universities_screen.dart
/// for why that changed.)
class ExploreMajorsScreen extends ConsumerWidget {
  const ExploreMajorsScreen({super.key, this.onContinue});

  /// Called when "Continue to universities →" is tapped with the gate
  /// satisfied. TargetUniversitiesScreen wires this to switch to the
  /// Find Universities tab (`TabController.animateTo(1)`) rather than a
  /// route push, since both tabs now live on the same screen.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(majorsControllerProvider);
    final controller = ref.read(majorsControllerProvider.notifier);
    final majors = settings.majors;
    final addable = majorCatalog
        .where((c) => !majors.any((m) => m.major == c.major))
        .toList();

    return ListView(
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
              description: catalogEntryFor(majors[i].major)?.description ?? '',
              onToggleTop: () async {
                final ok = await controller.toggleTop(i);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You can mark only 3 as Top 3')),
                  );
                }
              },
              onSetAnchor: () => controller.setAnchor(i),
              onSetCountry: (country) => controller.setCountry(i, country),
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
      ],
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
    required this.onSetCountry,
    required this.onRemove,
  });

  final MajorEntry entry;
  final String description;
  final VoidCallback onToggleTop;
  final VoidCallback onSetAnchor;
  final ValueChanged<String> onSetCountry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Anchor gets its own orange styling, distinct from plain Top-3 teal
    // — matches the original site's `.pwrow.anchor` orange highlight
    // (layered on top of `.pwrow.top`'s teal, since a major must already
    // be Top-marked before it can be the anchor).
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
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Target country: ',
                style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: entry.country,
                    isDense: true,
                    style: AppFonts.body(fontSize: 11.5, color: AppColors.ink),
                    items: [
                      for (final c in uniCountries) DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (c) {
                      if (c != null) onSetCountry(c);
                    },
                  ),
                ),
              ),
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