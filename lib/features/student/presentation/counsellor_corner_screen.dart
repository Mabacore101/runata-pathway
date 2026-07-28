import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../application/counsellor_corner_controller.dart';
import '../domain/counsellor_corner.dart';

/// Counsellor's Corner — family + education background. Mirrors the JS's
/// `renderCounsel()`: a header, a description line, then two sections
/// ("Student's family background", "Student's education background")
/// of plain fields, every one of them full-width (`class="pfld pfull"`
/// on every field in the JS — the underlying `.pgrid` 2-column layout
/// never actually applies here, so this screen doesn't attempt one).
///
/// **Genuinely autosaves on every keystroke/selection** — see
/// `CounsellorCornerController`'s own doc comment. `build()` watches the
/// controller directly (unlike `EssayDocScreen`, which deliberately
/// avoided watching its controller from build() to keep the feedback
/// panel stale-until-refreshed) — there's no expensive recompute here to
/// protect against, so a full rebuild on every change is simply the
/// simplest correct approach, not a performance concern worth designing
/// around.
///
/// **The "who" dropdown-with-conditional-"Other"-field pattern
/// (`addressedBy`/`talksWith`/`eduAdult`) is built fresh here** — no
/// prior screen in this codebase has one; Student's Profile has zero
/// dropdown fields at all (confirmed by reading `profile_screen.dart` in
/// full). Switching a "who" dropdown away from `'Other'` hides its own
/// free-text field but does NOT clear the stored value, matching the
/// JS's `cwho()` exactly — it only conditionally renders the input based
/// on the CURRENT selection, never resets the underlying data.
/// **A real, top-level go_router route** (reached from Nav Grid, once
/// that's built) — NOT an internally-swapped sub-screen the way
/// `EssayDocScreen`/`ActivitiesReportScreen`/`PortfolioScreen` are inside
/// `ApplicationMaterialsScreen`'s `_openDocKey` state. So its own back
/// button calls `context.go(AppRoutes.studentHome)` directly, matching
/// `ApplicationMaterialsScreen`'s own back button — no `onBack` callback
/// parameter needed or used.
class CounsellorCornerScreen extends ConsumerStatefulWidget {
  const CounsellorCornerScreen({super.key});

  @override
  ConsumerState<CounsellorCornerScreen> createState() => _CounsellorCornerScreenState();
}

/// Every free-text field on this screen, keyed by the same name as its
/// `CounsellorCorner` field — one `TextEditingController` per key, kept
/// in a map rather than 20 individual named fields purely to keep
/// `initState`/`dispose` from being 20 lines of near-identical
/// boilerplate each. The widget tree in `build()` still references each
/// one explicitly by key, in the JS's exact field order — this map only
/// exists to avoid repeating controller lifecycle code, not to make the
/// layout itself data-driven (the dropdowns are interleaved between text
/// fields in a way that doesn't suit a single generated list anyway).
const _textFieldKeys = [
  'qualityTime', 'enjoyMost', 'enjoyLeast', 'routines', 'rules', 'consequence',
  'addressedOther', 'flexible', 'disagreement', 'expressUpset', 'talksOther',
  'calmHow', 'eduAdultOther', 'famOther',
  'prevSchools', 'achievements', 'neededSupport', 'currentTherapy',
  'recentHighlight', 'runataNotes',
];

class _CounsellorCornerScreenState extends ConsumerState<CounsellorCornerScreen> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final current = ref.read(counsellorCornerControllerProvider);
    _controllers = {
      for (final key in _textFieldKeys)
        key: TextEditingController(text: _valueFor(current, key)),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _valueFor(CounsellorCorner c, String key) {
    switch (key) {
      case 'qualityTime':
        return c.qualityTime;
      case 'enjoyMost':
        return c.enjoyMost;
      case 'enjoyLeast':
        return c.enjoyLeast;
      case 'routines':
        return c.routines;
      case 'rules':
        return c.rules;
      case 'consequence':
        return c.consequence;
      case 'addressedOther':
        return c.addressedOther;
      case 'flexible':
        return c.flexible;
      case 'disagreement':
        return c.disagreement;
      case 'expressUpset':
        return c.expressUpset;
      case 'talksOther':
        return c.talksOther;
      case 'calmHow':
        return c.calmHow;
      case 'eduAdultOther':
        return c.eduAdultOther;
      case 'famOther':
        return c.famOther;
      case 'prevSchools':
        return c.prevSchools;
      case 'achievements':
        return c.achievements;
      case 'neededSupport':
        return c.neededSupport;
      case 'currentTherapy':
        return c.currentTherapy;
      case 'recentHighlight':
        return c.recentHighlight;
      case 'runataNotes':
        return c.runataNotes;
    }
    throw ArgumentError('Unknown Counsellor\'s Corner field key: $key');
  }

  CounsellorCorner _withValue(CounsellorCorner c, String key, String value) {
    switch (key) {
      case 'qualityTime':
        return c.copyWith(qualityTime: value);
      case 'enjoyMost':
        return c.copyWith(enjoyMost: value);
      case 'enjoyLeast':
        return c.copyWith(enjoyLeast: value);
      case 'routines':
        return c.copyWith(routines: value);
      case 'rules':
        return c.copyWith(rules: value);
      case 'consequence':
        return c.copyWith(consequence: value);
      case 'addressedOther':
        return c.copyWith(addressedOther: value);
      case 'flexible':
        return c.copyWith(flexible: value);
      case 'disagreement':
        return c.copyWith(disagreement: value);
      case 'expressUpset':
        return c.copyWith(expressUpset: value);
      case 'talksOther':
        return c.copyWith(talksOther: value);
      case 'calmHow':
        return c.copyWith(calmHow: value);
      case 'eduAdultOther':
        return c.copyWith(eduAdultOther: value);
      case 'famOther':
        return c.copyWith(famOther: value);
      case 'prevSchools':
        return c.copyWith(prevSchools: value);
      case 'achievements':
        return c.copyWith(achievements: value);
      case 'neededSupport':
        return c.copyWith(neededSupport: value);
      case 'currentTherapy':
        return c.copyWith(currentTherapy: value);
      case 'recentHighlight':
        return c.copyWith(recentHighlight: value);
      case 'runataNotes':
        return c.copyWith(runataNotes: value);
    }
    throw ArgumentError('Unknown Counsellor\'s Corner field key: $key');
  }

  void _onTextChanged(String key, String value) {
    final current = ref.read(counsellorCornerControllerProvider);
    ref
        .read(counsellorCornerControllerProvider.notifier)
        .updateAll(_withValue(current, key, value));
  }

  void _onDropdownChanged(CounsellorCorner Function(CounsellorCorner, String) setValue, String value) {
    final current = ref.read(counsellorCornerControllerProvider);
    ref.read(counsellorCornerControllerProvider.notifier).updateAll(setValue(current, value));
  }

  Future<void> _onSave() async {
    final current = ref.read(counsellorCornerControllerProvider);
    await ref.read(counsellorCornerControllerProvider.notifier).updateAll(current);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counsellor\'s Corner saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(counsellorCornerControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Counsellor\'s Corner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('🧭', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Counsellor\'s Corner',
                    style: AppFonts.display(fontSize: 20, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "This helps our counsellor understand and support you better. "
              "Answer as fully as you're comfortable with — it's shared "
              'with your Academic Advisor & Coordinator. It saves '
              'automatically.',
              style: AppFonts.body(fontSize: 13, color: AppColors.muted),
            ),
            _SectionHeader('Student\'s family background'),
            _textArea(
              key: 'qualityTime',
              label: 'Do you have daily/weekly family quality time? Please describe',
              hint: 'e.g. dinner together every night, weekend outings',
            ),
            _textArea(key: 'enjoyMost', label: 'Activities the student enjoys the most'),
            _textArea(key: 'enjoyLeast', label: 'Activities the student enjoys the least'),
            _textArea(
              key: 'routines',
              label: 'Daily routines within the family',
              hint: 'e.g. dinner together, morning exercise',
            ),
            _textArea(
              key: 'rules',
              label: 'Rules at home',
              hint: 'e.g. wash own dishes after use, curfew at 8pm',
            ),
            _textArea(
              key: 'consequence',
              label: "Is there a consequence when rules aren't followed? Please describe",
            ),
            _whoDropdown(
              label: 'Who usually addresses the matters above?',
              value: current.addressedBy,
              otherKey: 'addressedOther',
              onChanged: (v) => _onDropdownChanged((c, newValue) => c.copyWith(addressedBy: newValue), v),
            ),
            _textArea(
              key: 'flexible',
              label: 'Flexible regulations at home',
              hint: 'e.g. sleep time, gadget usage',
            ),
            _textArea(key: 'disagreement', label: "When there's a disagreement, it's usually about…"),
            _textArea(
              key: 'expressUpset',
              label: 'How does the student express him/herself when strongly upset?',
            ),
            _whoDropdown(
              label: 'When upset, the student usually talks with…',
              value: current.talksWith,
              otherKey: 'talksOther',
              onChanged: (v) => _onDropdownChanged((c, newValue) => c.copyWith(talksWith: newValue), v),
            ),
            _textArea(key: 'calmHow', label: 'How to calm him/her during strong emotion?'),
            _whoDropdown(
              label: 'Adult involved in the daily education routine',
              value: current.eduAdult,
              otherKey: 'eduAdultOther',
              onChanged: (v) => _onDropdownChanged((c, newValue) => c.copyWith(eduAdult: newValue), v),
            ),
            _textArea(key: 'famOther', label: 'Other information'),
            _SectionHeader('Student\'s education background'),
            _textArea(
              key: 'prevSchools',
              label: 'Previous school(s) details',
              hint: 'e.g. Primary 1–3 at Watermelon School 2020–2022',
            ),
            _textArea(key: 'achievements', label: 'School achievements (academic & non-academic)'),
            _textArea(key: 'neededSupport', label: 'Needed support in…'),
            _therapyDropdown(current: current),
            _textArea(
              key: 'currentTherapy',
              label: 'Currently following physio / occupational / behaviour / play therapy?',
              hint: "Describe, or 'none'",
            ),
            _textArea(
              key: 'recentHighlight',
              label: 'Highlights of the most recent school',
              hint: 'e.g. more independent in learning, enjoys socialising with peers',
            ),
            _textArea(
              key: 'runataNotes',
              label: 'Notes Runata Global School needs to know',
              hint: 'e.g. needs encouragement in Math, takes time to adapt',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('counsellor_save'),
                    onPressed: _onSave,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('counsellor_back_to_home'),
                    onPressed: () => context.go(AppRoutes.studentHome),
                    child: const Text('← Back to home'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textArea({required String key, required String label, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.body(fontSize: 12, weight: FontWeight.w600, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 5),
          TextField(
            key: Key('counsellor_field_$key'),
            controller: _controllers[key],
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(hintText: hint),
            onChanged: (v) => _onTextChanged(key, v),
          ),
        ],
      ),
    );
  }

  /// One of the 3 "who" dropdowns (`addressedBy`/`talksWith`/`eduAdult`)
  /// — a Father/Mother/Both/None/Other select with a conditional
  /// free-text field that only appears when `'Other'` is selected.
  Widget _whoDropdown({
    required String label,
    required String value,
    required String otherKey,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppFonts.body(fontSize: 12, weight: FontWeight.w600, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            key: Key('counsellor_dropdown_$otherKey'),
            initialValue: value,
            items: [
              for (final option in familyAddresserOptions)
                DropdownMenuItem(value: option, child: Text(option.isEmpty ? '— select —' : option)),
            ],
            onChanged: (v) => onChanged(v ?? ''),
          ),
          if (value == 'Other') ...[
            const SizedBox(height: 6),
            TextField(
              key: Key('counsellor_field_$otherKey'),
              controller: _controllers[otherKey],
              decoration: const InputDecoration(hintText: 'Please specify'),
              onChanged: (v) => _onTextChanged(otherKey, v),
            ),
          ],
        ],
      ),
    );
  }

  /// `hadTherapy`'s Yes/No dropdown — the one dropdown with no
  /// conditional "Other" field and no re-render side effect in the JS
  /// (it's not in the `/addressedBy|talksWith|eduAdult/` regex that
  /// forces one), matching that here by simply having nothing
  /// conditional to show.
  Widget _therapyDropdown({required CounsellorCorner current}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Had support in the form of physio / occupational / speech / '
            'behaviour / play / sensory-integration therapy?',
            style: AppFonts.body(fontSize: 12, weight: FontWeight.w600, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            key: const Key('counsellor_dropdown_hadTherapy'),
            initialValue: current.hadTherapy,
            items: [
              for (final option in therapyOptions)
                DropdownMenuItem(value: option, child: Text(option.isEmpty ? '— select —' : option)),
            ],
            onChanged: (v) => _onDropdownChanged((c, newValue) => c.copyWith(hadTherapy: newValue), v ?? ''),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Text(
        title.toUpperCase(),
        style: AppFonts.display(
          fontSize: 13,
          weight: FontWeight.w700,
          color: AppColors.tealDeep,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}