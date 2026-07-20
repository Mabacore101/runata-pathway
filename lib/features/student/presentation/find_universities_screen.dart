import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/majors_controller.dart';
import '../application/tests_controller.dart';
import '../application/uni_selection_controller.dart';
import '../application/university_targets_controller.dart';
import '../domain/fit_status.dart';
import '../domain/majors_catalog.dart';
import '../domain/major_entry.dart';
import '../domain/test_entry.dart';
import '../domain/university_catalog.dart';
import '../domain/university_target.dart';

/// Find Universities — Target Universities tab 2. Bare content, embedded
/// inside TargetUniversitiesScreen's shared Scaffold/AppBar, same as
/// ExploreMajorsScreen.
///
/// Gated on at least 1 Top-marked major existing (matches the behavioral
/// spec's "At Least 1 Marked as Top?" diamond) — NOT on the stricter
/// exactly-3-Top+anchor gate Explore Majors' own Continue button uses.
class FindUniversitiesScreen extends ConsumerStatefulWidget {
  const FindUniversitiesScreen({super.key, this.onGoToExploreMajors});

  /// Wired by TargetUniversitiesScreen to switch back to tab 0.
  final VoidCallback? onGoToExploreMajors;

  @override
  ConsumerState<FindUniversitiesScreen> createState() =>
      _FindUniversitiesScreenState();
}

class _FindUniversitiesScreenState
    extends ConsumerState<FindUniversitiesScreen> {
  /// Captured from Autocomplete's fieldViewBuilder so the separate "+ Add"
  /// button (outside the Autocomplete widget itself) can read whatever
  /// the student has currently typed, not just a selected suggestion.
  TextEditingController? _customUniController;

  @override
  Widget build(BuildContext context) {
    final majorsSettings = ref.watch(majorsControllerProvider);
    final myMajors = majorsSettings.topMarked.map((m) => m.major).toList();

    if (myMajors.isEmpty) {
      return _GateMessage(onGoToExploreMajors: widget.onGoToExploreMajors);
    }

    final selection = ref.watch(uniSelectionProvider);
    final selectionController = ref.read(uniSelectionProvider.notifier);
    final anchor = majorsSettings.anchor;

    final effectiveMajor =
        _effectiveMajor(myMajors, anchor?.major, selection.major);
    final effectiveCountry = _effectiveCountry(anchor, selection.country);

    final targets = ref.watch(universityTargetsControllerProvider);
    final targetsController =
        ref.read(universityTargetsControllerProvider.notifier);

    final testEntries = ref.watch(testsControllerProvider);
    final studentIelts = _studentIeltsScore(testEntries);

    final majorField = catalogEntryFor(effectiveMajor)?.field ?? '';
    final matches = (universitiesByCountry[effectiveCountry] ?? const [])
        .where((u) => u.matchesField(majorField))
        .toList();

    final curCount = targets.countForMajor(effectiveMajor);
    final majorFull = curCount >= UniversityTargetsController.maxPerMajor;
    final chosenForMajor = targets.forMajor(effectiveMajor);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Universities per major',
          style: AppFonts.display(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft),
            children: [
              const TextSpan(text: 'Pick up to '),
              TextSpan(
                text: '${UniversityTargetsController.maxPerMajor}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: ' universities for each major. Tap a major to work on it.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in myMajors)
              _MajorStatusChip(
                major: m,
                count: targets.countForMajor(m),
                selected: m == effectiveMajor,
                onTap: () => selectionController.selectMajor(m),
              ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _LabeledDropdown(
                label: 'Choose a major',
                value: effectiveMajor,
                options: myMajors,
                onChanged: selectionController.selectMajor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabeledDropdown(
                label: 'Choose a country',
                value: effectiveCountry,
                options: uniCountries,
                onChanged: selectionController.selectCountry,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: AppFonts.body(weight: FontWeight.w700, fontSize: 14, color: AppColors.ink),
                  children: [
                    const TextSpan(text: 'Universities for '),
                    TextSpan(text: effectiveMajor),
                    const TextSpan(text: ' in '),
                    TextSpan(text: effectiveCountry),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: majorFull ? AppColors.redSoft : AppColors.surface2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$curCount/${UniversityTargetsController.maxPerMajor} chosen',
                style: AppFonts.mono(
                  fontSize: 10.5,
                  weight: FontWeight.w700,
                  color: majorFull ? AppColors.red : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          majorFull
              ? "You've reached the maximum of ${UniversityTargetsController.maxPerMajor} universities for $effectiveMajor. Remove one below to swap."
              : 'A few suggestions — these are examples, not your only options.',
          style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 12),

        if (chosenForMajor.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in chosenForMajor)
                _ChosenChip(
                  target: t,
                  onRemove: () => targetsController.removeTarget(
                    university: t.university,
                    major: t.major,
                    country: t.country,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        if (matches.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No $effectiveMajor suggestions for $effectiveCountry yet — add your own below.',
              style: AppFonts.body(color: AppColors.muted),
            ),
          )
        else
          for (final u in matches)
            _UniversityCard(
              entry: u,
              added: chosenForMajor.any((t) => t.university == u.name && t.country == effectiveCountry),
              blockAdd: majorFull,
              studentIelts: studentIelts,
              onAdd: () => targetsController.addTarget(
                major: effectiveMajor,
                country: effectiveCountry,
                university: u.name,
              ),
              onRemove: () => targetsController.removeTarget(
                university: u.name,
                major: effectiveMajor,
                country: effectiveCountry,
              ),
            ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨ ', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Text(
                  'Aim across a range, not only top-tier. Browse the QS World '
                  'University Rankings and add whichever fit you.',
                  style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
        ),

        if (majorFull)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Max ${UniversityTargetsController.maxPerMajor} reached for '
              '$effectiveMajor — remove one first to add another.',
              style: AppFonts.body(color: AppColors.muted),
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    final query = textEditingValue.text.trim().toLowerCase();
                    if (query.isEmpty) return const Iterable<String>.empty();
                    return catalogFor(effectiveCountry)
                        .where((name) => name.toLowerCase().contains(query));
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    _customUniController = controller;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search & add any university — type its name…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final text = _customUniController?.text.trim() ?? '';
                  if (text.isEmpty) return;
                  final added = await targetsController.addTarget(
                    major: effectiveMajor,
                    country: effectiveCountry,
                    university: text,
                    custom: true,
                  );
                  if (added) _customUniController?.clear();
                },
                child: const Text('+ Add'),
              ),
            ],
          ),
      ],
    );
  }
}

/// Falls back to the anchor major (if it's still Top-marked), then the
/// first Top-marked major — derived fresh every build rather than stored,
/// so it never needs explicit correction when the majors list changes
/// underneath it (same reasoning as MajorsDerived.anchor).
String _effectiveMajor(List<String> myMajors, String? anchorMajor, String? selectedMajor) {
  if (selectedMajor != null && myMajors.contains(selectedMajor)) return selectedMajor;
  if (anchorMajor != null && myMajors.contains(anchorMajor)) return anchorMajor;
  return myMajors.first;
}

/// Auto-fills from the anchor major's country the first time this tab is
/// viewed (day3-trimmed-source.md's "Read this first" note), same derived
/// approach as [_effectiveMajor].
String _effectiveCountry(MajorEntry? anchor, String? selectedCountry) {
  if (selectedCountry != null && uniCountries.contains(selectedCountry)) {
    return selectedCountry;
  }
  if (anchor != null && uniCountries.contains(anchor.country)) {
    return anchor.country;
  }
  return uniCountries.first;
}

/// Mirrors the JS's `sc.ielts` — pulled from the student's actual My
/// Tests IELTS row rather than a separate stored score. Returns null if
/// no IELTS row exists, or its `latest` text doesn't parse as a number
/// (matches JS's `isNaN(parseFloat(sc.ielts))` guard).
double? _studentIeltsScore(List<TestEntry> entries) {
  for (final t in entries) {
    if (t.type == TestType.ielts) {
      return t.latest != null ? double.tryParse(t.latest!) : null;
    }
  }
  return null;
}

class _GateMessage extends StatelessWidget {
  const _GateMessage({this.onGoToExploreMajors});
  final VoidCallback? onGoToExploreMajors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: AppFonts.body(color: AppColors.muted),
                children: const [
                  TextSpan(text: 'Mark your '),
                  TextSpan(text: 'Top 3', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ' majors first in '),
                  TextSpan(text: 'Explore Majors', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ', then come back here to find universities for each one.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onGoToExploreMajors,
              child: const Text('Go to Explore Majors →'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.body(fontSize: 12, weight: FontWeight.w700, color: AppColors.muted)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          // Plain DropdownButton, not DropdownButtonFormField — the
          // FormField variant is known not to reliably reflect an
          // externally-changed `value` on rebuild (e.g. when a status
          // chip changes the selection instead of this dropdown itself).
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: [
                for (final o in options) DropdownMenuItem(value: o, child: Text(o)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MajorStatusChip extends StatelessWidget {
  const _MajorStatusChip({
    required this.major,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String major;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = count >= UniversityTargetsController.maxPerMajor;
    final Color background = done ? AppColors.tealSoft : AppColors.surface;
    final Color border = done ? AppColors.teal : (selected ? AppColors.teal : AppColors.line);
    final Color countColor = done ? AppColors.tealDeep : (count > 0 ? AppColors.orangeDeep : AppColors.muted);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(major, style: AppFonts.body(weight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink)),
            Text(
              count > 0 ? '$count/${UniversityTargetsController.maxPerMajor}' : 'none yet',
              style: AppFonts.mono(fontSize: 10.5, weight: FontWeight.w700, color: countColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChosenChip extends StatelessWidget {
  const _ChosenChip({required this.target, required this.onRemove});
  final UniversityTarget target;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(target.university, style: AppFonts.body(fontSize: 12.5, weight: FontWeight.w600, color: AppColors.tealDeep)),
          IconButton(
            icon: const Icon(Icons.close, size: 14),
            color: AppColors.tealDeep,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  const _UniversityCard({
    required this.entry,
    required this.added,
    required this.blockAdd,
    required this.studentIelts,
    required this.onAdd,
    required this.onRemove,
  });

  final UniversityEntry entry;
  final bool added;
  final bool blockAdd;
  final double? studentIelts;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    // Fit chip only shows when the university HAS an IELTS requirement
    // AND the student HAS a parseable IELTS score — matches the JS's
    // gate exactly (`u.ielts&&sc&&sc.ielts&&!isNaN(...)`), not
    // fitStatusFor's own "Add IELTS"/"See requirements" fallback labels,
    // which this call site never actually reaches.
    final showFitChip = entry.ielts != null && studentIelts != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: added ? AppColors.tealSoft : AppColors.surface2,
        border: Border.all(color: added ? AppColors.teal : AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(entry.name, style: AppFonts.body(weight: FontWeight.w700, fontSize: 13.5)),
              ),
              if (entry.type != null) ...[
                const SizedBox(width: 6),
                _TypeBadge(type: entry.type!),
              ],
              if (showFitChip) ...[
                const SizedBox(width: 6),
                _FitChip(fit: fitStatusFor(entry, studentIelts)),
              ],
            ],
          ),
          Material(
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: Text(
                  'Academic requirements',
                  style: AppFonts.mono(fontSize: 10.5, weight: FontWeight.w700, color: AppColors.tealDeep),
                ),
                children: [
                  for (final r in entry.requirements)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('•  $r', style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (added)
                Text(
                  '✓ On your list',
                  style: AppFonts.body(fontSize: 11, weight: FontWeight.w700, color: AppColors.tealDeep),
                ),
              const Spacer(),
              if (added)
                OutlinedButton(
                  onPressed: onRemove,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.redSoft,
                    foregroundColor: AppColors.red,
                    side: BorderSide(color: AppColors.redSoft),
                  ),
                  child: const Text('✕ Remove'),
                )
              else
                OutlinedButton(
                  onPressed: blockAdd ? null : onAdd,
                  child: Text(blockAdd ? 'Max 3 reached' : '+ Add to my list'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isNegeri = type.toLowerCase() == 'negeri';
    final bg = isNegeri ? AppColors.tealSoft : AppColors.orangeSoft;
    final fg = isNegeri ? AppColors.tealDeep : AppColors.orangeDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(type.toUpperCase(), style: AppFonts.mono(fontSize: 8, weight: FontWeight.w700, color: fg)),
    );
  }
}

class _FitChip extends StatelessWidget {
  const _FitChip({required this.fit});
  final FitStatus fit;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    switch (fit.tier) {
      case FitTier.met:
        bg = AppColors.greenSoft;
        fg = AppColors.green;
      case FitTier.track:
        bg = AppColors.tealSoft;
        fg = AppColors.tealDeep;
      case FitTier.work:
        bg = AppColors.amberSoft;
        fg = AppColors.amber;
      case FitTier.none:
        bg = AppColors.surface2;
        fg = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: fit.tier == FitTier.none ? Border.all(color: AppColors.line) : null,
      ),
      child: Text(
        fit.label.toUpperCase(),
        style: AppFonts.mono(fontSize: 9, weight: FontWeight.w600, color: fg, letterSpacing: 0.4),
      ),
    );
  }
}