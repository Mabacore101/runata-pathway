import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/majors_controller.dart';
import '../application/tests_controller.dart';
import '../application/university_targets_controller.dart';
import '../domain/fit_status.dart';
import '../domain/university_catalog.dart';
import '../domain/university_target.dart';
import 'find_universities_screen.dart' show FitChip;

/// My Shortlist — Target Universities tab 3. Bare content, embedded
/// inside TargetUniversitiesScreen's shared Scaffold/AppBar, same as the
/// other two tabs.
///
/// Read-only in the sense that nothing here ADDS a university (that's
/// Find Universities' job) — this tab only reviews, annotates (Notes),
/// and removes what's already been chosen. Sort order mirrors the JS's
/// `tgtTable` exactly: the anchor major's targets first, then every
/// other major's targets grouped alphabetically by major name.
///
/// Parent/Staff view-mode branching (`beParentMode()`, read-only notes,
/// no delete button) is deliberately NOT built — no Parent role exists
/// in this app yet, same reasoning day3-trimmed-source.md gives for
/// skipping Coordinator-lock logic. This always renders the student view.
class MyShortlistScreen extends ConsumerWidget {
  const MyShortlistScreen({super.key, this.onGoToFindUniversities});

  /// Wired by TargetUniversitiesScreen to switch back to tab 1.
  final VoidCallback? onGoToFindUniversities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targets = ref.watch(universityTargetsControllerProvider);
    final targetsController = ref.read(universityTargetsControllerProvider.notifier);
    final anchorMajor = ref.watch(majorsControllerProvider).anchor?.major;
    final studentIelts = studentIeltsScore(ref.watch(testsControllerProvider));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Universities I'm aiming for",
          style: AppFonts.display(fontSize: 18, color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          'Compare your shortlist side by side, with the entry '
          'requirements for each one.',
          style: AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),

        if (targets.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No universities yet — go to Find Universities to add some.',
                  style: AppFonts.body(color: AppColors.muted),
                ),
                if (onGoToFindUniversities != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: onGoToFindUniversities,
                    child: const Text('Go to Find Universities →'),
                  ),
                ],
              ],
            ),
          )
        else
          for (final t in _sortedTargets(targets, anchorMajor))
            _ShortlistCard(
              key: ValueKey(t.id),
              target: t,
              isAnchorMajor: anchorMajor != null && t.major == anchorMajor,
              studentIelts: studentIelts,
              onDelete: () => targetsController.removeTarget(
                university: t.university,
                major: t.major,
                country: t.country,
              ),
              onNoteChanged: (note) => targetsController.updateNote(t.id, note),
            ),

        if (onGoToFindUniversities != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onGoToFindUniversities,
            child: const Text('← Previous'),
          ),
        ],
      ],
    );
  }
}

/// Anchor major's targets first, then every other major's targets grouped
/// alphabetically — mirrors the JS's sort exactly (`aA&&!bA` / `bA&&!aA`
/// / `localeCompare`).
List<UniversityTarget> _sortedTargets(List<UniversityTarget> targets, String? anchorMajor) {
  final sorted = [...targets];
  sorted.sort((a, b) {
    final aIsAnchor = anchorMajor != null && a.major == anchorMajor;
    final bIsAnchor = anchorMajor != null && b.major == anchorMajor;
    if (aIsAnchor && !bIsAnchor) return -1;
    if (bIsAnchor && !aIsAnchor) return 1;
    return a.major.compareTo(b.major);
  });
  return sorted;
}

class _ShortlistCard extends StatefulWidget {
  const _ShortlistCard({
    super.key,
    required this.target,
    required this.isAnchorMajor,
    required this.studentIelts,
    required this.onDelete,
    required this.onNoteChanged,
  });

  final UniversityTarget target;
  final bool isAnchorMajor;
  final double? studentIelts;
  final VoidCallback onDelete;
  final ValueChanged<String> onNoteChanged;

  @override
  State<_ShortlistCard> createState() => _ShortlistCardState();
}

class _ShortlistCardState extends State<_ShortlistCard> {
  late final TextEditingController _noteController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.target.note ?? '');
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  /// Mirrors the JS's `data-tnote` handler in spirit (a free-text note
  /// per row) but not in timing — the JS mutates the note on every
  /// keystroke since it's a live in-memory object reference, with no
  /// explicit save step. Here [onNoteChanged] triggers a REAL Hive
  /// write, so it's called on focus-loss rather than per keystroke, to
  /// avoid a disk write on every character typed.
  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      widget.onNoteChanged(_noteController.text);
    }
  }

  @override
  void didUpdateWidget(covariant _ShortlistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync if this row's underlying note ever changes
    // from elsewhere — only while NOT focused, so an in-progress edit is
    // never clobbered out from under the student.
    if (!_focusNode.hasFocus && oldWidget.target.note != widget.target.note) {
      _noteController.text = widget.target.note ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final catalogEntry = findUniversityEntry(target.country, target.university);
    final showFitChip = catalogEntry?.ielts != null && widget.studentIelts != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.isAnchorMajor ? AppColors.orangeSoft : AppColors.surface2,
        border: Border.all(color: widget.isAnchorMajor ? AppColors.orange : AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(target.major, style: AppFonts.body(weight: FontWeight.w700, fontSize: 13)),
                    if (widget.isAnchorMajor)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '★ Anchor',
                          style: AppFonts.mono(fontSize: 9, weight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                tooltip: 'Remove',
                onPressed: widget.onDelete,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(target.university, style: AppFonts.display(fontSize: 14.5, color: AppColors.ink)),
              ),
              if (target.custom) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.tealSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'yours',
                    style: AppFonts.mono(fontSize: 9, weight: FontWeight.w700, color: AppColors.tealDeep),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('📍 ${target.country}', style: AppFonts.body(fontSize: 11.5, color: AppColors.inkSoft)),
              if (showFitChip) ...[
                const SizedBox(width: 8),
                FitChip(fit: fitStatusFor(catalogEntry!, widget.studentIelts)),
              ],
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Entry requirements',
            style: AppFonts.mono(fontSize: 10.5, weight: FontWeight.w700, color: AppColors.tealDeep),
          ),
          const SizedBox(height: 4),
          if (catalogEntry != null && catalogEntry.requirements.isNotEmpty)
            for (final r in catalogEntry.requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('•  $r', style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft)),
              )
          else
            Text(
              target.custom ? 'Add requirements in Notes →' : 'No listed requirements',
              style: AppFonts.body(fontSize: 12, color: AppColors.muted),
            ),
          const SizedBox(height: 10),

          Text('Notes', style: AppFonts.body(fontSize: 11, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          TextField(
            controller: _noteController,
            focusNode: _focusNode,
            maxLines: 3,
            minLines: 2,
            style: AppFonts.body(fontSize: 12.5, color: AppColors.ink),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'IELTS 6.5, portfolio, deadline…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }
}
