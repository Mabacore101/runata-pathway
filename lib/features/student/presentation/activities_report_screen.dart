import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../application/activities_report_controller.dart';
import '../application/clubs_controller.dart';
import '../domain/activity_entry.dart';
import '../domain/club_catalog.dart';
import '../domain/club_schedule_preview.dart';
import '../domain/community_service_entry.dart';
import '../domain/student_activities_report.dart';

/// Student Activities Report — Pathway form 6a (Day 5 item 2).
///
/// Replaces the Hub's generic "coming next" placeholder for the
/// `'activities'` doc key — same `_openDocKey` hook from item 1, no
/// routing changes needed.
///
/// **Save button note:** in the original JS, every field here writes
/// straight into the in-memory record on every keystroke/change (see
/// `ActivitiesReportController`'s doc comment) — the on-screen "Save"
/// button is a generic, screen-agnostic flush that doesn't read this
/// form at all, making it genuinely cosmetic there. In THIS rebuild,
/// row field edits are deliberately deferred to that same button
/// (`saveAll`) — Hive-backed persistence and in-memory widget state
/// aren't the same thing the way a single JS object graph is, so Save
/// here is load-bearing, not cosmetic. Row add/delete stay immediate
/// either way.
class ActivitiesReportScreen extends ConsumerStatefulWidget {
  const ActivitiesReportScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<ActivitiesReportScreen> createState() =>
      _ActivitiesReportScreenState();
}

class _ActivityRowControllers {
  _ActivityRowControllers({ActivityEntry? from})
      : activity = TextEditingController(text: from?.activity ?? ''),
        role = TextEditingController(text: from?.role ?? ''),
        dates = TextEditingController(text: from?.dates ?? '');

  final TextEditingController activity;
  final TextEditingController role;
  final TextEditingController dates;

  ActivityEntry toEntry() => ActivityEntry(
        activity: activity.text,
        role: role.text,
        dates: dates.text,
      );

  void dispose() {
    activity.dispose();
    role.dispose();
    dates.dispose();
  }
}

class _CommunityServiceRowControllers {
  _CommunityServiceRowControllers({CommunityServiceEntry? from})
      : activity = TextEditingController(text: from?.activity ?? ''),
        role = TextEditingController(text: from?.role ?? ''),
        months = from?.months ?? 0,
        proof = from?.proof ?? false;

  final TextEditingController activity;
  final TextEditingController role;
  int months;
  bool proof;

  CommunityServiceEntry toEntry() => CommunityServiceEntry(
        activity: activity.text,
        role: role.text,
        months: months,
        proof: proof,
      );

  void dispose() {
    activity.dispose();
    role.dispose();
  }
}

class _ActivitiesReportScreenState
    extends ConsumerState<ActivitiesReportScreen> {
  late List<_ActivityRowControllers> _sectionA;
  late List<_CommunityServiceRowControllers> _sectionC;
  late List<_ActivityRowControllers> _sectionD;
  late List<_ActivityRowControllers> _sectionE;
  late List<_ActivityRowControllers> _sectionF;

  @override
  void initState() {
    super.initState();
    final report = ref.read(activitiesReportControllerProvider);
    _sectionA = report.sectionA.map((e) => _ActivityRowControllers(from: e)).toList();
    _sectionC =
        report.sectionC.map((e) => _CommunityServiceRowControllers(from: e)).toList();
    _sectionD = report.sectionD.map((e) => _ActivityRowControllers(from: e)).toList();
    _sectionE = report.sectionE.map((e) => _ActivityRowControllers(from: e)).toList();
    _sectionF = report.sectionF.map((e) => _ActivityRowControllers(from: e)).toList();
  }

  @override
  void dispose() {
    for (final r in _sectionA) {
      r.dispose();
    }
    for (final r in _sectionC) {
      r.dispose();
    }
    for (final r in _sectionD) {
      r.dispose();
    }
    for (final r in _sectionE) {
      r.dispose();
    }
    for (final r in _sectionF) {
      r.dispose();
    }
    super.dispose();
  }

  List<_ActivityRowControllers> _listFor(ActivitiesReportSection section) {
    switch (section) {
      case ActivitiesReportSection.a:
        return _sectionA;
      case ActivitiesReportSection.d:
        return _sectionD;
      case ActivitiesReportSection.e:
        return _sectionE;
      case ActivitiesReportSection.f:
        return _sectionF;
    }
  }

  Future<void> _addActivityRow(ActivitiesReportSection section) async {
    await ref.read(activitiesReportControllerProvider.notifier).addActivityRow(section);
    setState(() => _listFor(section).add(_ActivityRowControllers()));
  }

  Future<void> _deleteActivityRow(ActivitiesReportSection section, int index) async {
    await ref
        .read(activitiesReportControllerProvider.notifier)
        .deleteActivityRow(section, index);
    setState(() {
      final list = _listFor(section);
      list[index].dispose();
      list.removeAt(index);
    });
  }

  Future<void> _addCommunityServiceRow() async {
    await ref.read(activitiesReportControllerProvider.notifier).addCommunityServiceRow();
    setState(() => _sectionC.add(_CommunityServiceRowControllers()));
  }

  Future<void> _deleteCommunityServiceRow(int index) async {
    await ref
        .read(activitiesReportControllerProvider.notifier)
        .deleteCommunityServiceRow(index);
    setState(() {
      _sectionC[index].dispose();
      _sectionC.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    final updated = StudentActivitiesReport(
      sectionA: _sectionA.map((r) => r.toEntry()).toList(),
      sectionC: _sectionC.map((r) => r.toEntry()).toList(),
      sectionD: _sectionD.map((r) => r.toEntry()).toList(),
      sectionE: _sectionE.map((r) => r.toEntry()).toList(),
      sectionF: _sectionF.map((r) => r.toEntry()).toList(),
    );
    await ref.read(activitiesReportControllerProvider.notifier).saveAll(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activities report saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).session;
    final submission = ref.watch(clubSubmissionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Student Activities Report')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'This is your official record of involvement, in the Runata '
                'report format. Fill it in — the school issues the final '
                "stamped copy. Section B fills automatically from your "
                'clubs. Put your actual work (designs, code, projects) in '
                'the separate Portfolio.',
                style: AppFonts.body(fontSize: 12.5, color: AppColors.tealDeep),
              ),
            ),
            const SizedBox(height: 14),
            _RidBar(
              name: session?.name ?? '—',
              grade: session?.grade,
              major: submission?.anchorMajor,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'A. Mandatory Grade Level Program',
              addButtonLabel: '+ Add activity',
              addButtonKey: const Key('add_row_a'),
              onAdd: () => _addActivityRow(ActivitiesReportSection.a),
              child: _ActivityRowList(
                rows: _sectionA,
                onDelete: (i) => _deleteActivityRow(ActivitiesReportSection.a, i),
                sectionKey: 'a',
              ),
            ),
            const _StudentOrganizationsSection(),
            _SectionCard(
              title: 'C. Community Services',
              caption: 'min 4 months + proof letter',
              addButtonLabel: '+ Add community service',
              addButtonKey: const Key('add_row_c'),
              onAdd: _addCommunityServiceRow,
              child: _CommunityServiceRowList(
                rows: _sectionC,
                onDelete: _deleteCommunityServiceRow,
              ),
            ),
            _SectionCard(
              title: 'D. Competitions & School Representative',
              addButtonLabel: '+ Add entry',
              addButtonKey: const Key('add_row_d'),
              onAdd: () => _addActivityRow(ActivitiesReportSection.d),
              child: _ActivityRowList(
                rows: _sectionD,
                onDelete: (i) => _deleteActivityRow(ActivitiesReportSection.d, i),
                sectionKey: 'd',
              ),
            ),
            _SectionCard(
              title: 'E. Event Committees',
              addButtonLabel: '+ Add entry',
              addButtonKey: const Key('add_row_e'),
              onAdd: () => _addActivityRow(ActivitiesReportSection.e),
              child: _ActivityRowList(
                rows: _sectionE,
                onDelete: (i) => _deleteActivityRow(ActivitiesReportSection.e, i),
                sectionKey: 'e',
              ),
            ),
            _SectionCard(
              title: 'F. School Teams',
              addButtonLabel: '+ Add entry',
              addButtonKey: const Key('add_row_f'),
              onAdd: () => _addActivityRow(ActivitiesReportSection.f),
              child: _ActivityRowList(
                rows: _sectionF,
                onDelete: (i) => _deleteActivityRow(ActivitiesReportSection.f, i),
                sectionKey: 'f',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    key: const Key('activities_save'),
                    onPressed: _handleSave,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('activities_back_to_hub'),
                    onPressed: widget.onBack,
                    child: const Text('← All documents'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Name / Grade / Major header strip — matches the JS's `rid` bar.
/// `major` reads the SUBMITTED club selection's anchor (not the live
/// Explore Majors anchor), matching the JS's own `submissions[stu.n].
/// anchorMajor` read exactly.
class _RidBar extends StatelessWidget {
  const _RidBar({required this.name, required this.grade, required this.major});

  final String name;
  final String? grade;
  final String? major;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          _RidField(label: 'Name', value: name),
          _RidField(label: 'Grade', value: grade != null ? 'Grade $grade' : '—'),
          _RidField(
            label: 'Major',
            value: major ?? '— (clubs not submitted)',
          ),
        ],
      ),
    );
  }
}

class _RidField extends StatelessWidget {
  const _RidField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: AppFonts.mono(fontSize: 9, weight: FontWeight.w600, color: AppColors.muted),
        ),
        Text(
          value,
          style: AppFonts.body(fontSize: 13, weight: FontWeight.w600, color: AppColors.ink),
        ),
      ],
    );
  }
}

/// Shared card chrome for every section (A–F) — title, optional caption
/// ("autoflag" in the original CSS), content, and an optional add button.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.caption,
    this.addButtonLabel,
    this.addButtonKey,
    this.onAdd,
  });

  final String title;
  final String? caption;
  final Widget child;
  final String? addButtonLabel;
  final Key? addButtonKey;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                title,
                style: AppFonts.body(
                  weight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppColors.ink,
                ),
              ),
              if (caption != null)
                Text(
                  '· $caption',
                  style: AppFonts.mono(fontSize: 9.5, color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
          if (onAdd != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: addButtonKey,
                onPressed: onAdd,
                child: Text(addButtonLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sections A/D/E/F — identical repeatable-row shape.
class _ActivityRowList extends StatelessWidget {
  const _ActivityRowList({
    required this.rows,
    required this.onDelete,
    required this.sectionKey,
  });

  final List<_ActivityRowControllers> rows;
  final ValueChanged<int> onDelete;
  final String sectionKey;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No entries yet.',
        style: AppFonts.body(color: AppColors.muted, fontSize: 12.5),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _ActivityRow(
            key: Key('activity_row_${sectionKey}_$i'),
            controllers: rows[i],
            onDelete: () => onDelete(i),
            deleteKey: Key('activity_delete_${sectionKey}_$i'),
          ),
          if (i != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    super.key,
    required this.controllers,
    required this.onDelete,
    required this.deleteKey,
  });

  final _ActivityRowControllers controllers;
  final VoidCallback onDelete;
  final Key deleteKey;

  @override
  Widget build(BuildContext context) {
    final c = controllers;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.activity,
                  decoration: const InputDecoration(labelText: 'Activity'),
                ),
              ),
              IconButton(
                key: deleteKey,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.role,
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: c.dates,
                  decoration: const InputDecoration(labelText: 'Dates'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Section C — extends the A/D/E/F template with months/proof
/// eligibility.
class _CommunityServiceRowList extends StatelessWidget {
  const _CommunityServiceRowList({required this.rows, required this.onDelete});

  final List<_CommunityServiceRowControllers> rows;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No entries yet.',
        style: AppFonts.body(color: AppColors.muted, fontSize: 12.5),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          _CommunityServiceRow(
            key: Key('cs_row_$i'),
            controllers: rows[i],
            onDelete: () => onDelete(i),
            deleteKey: Key('cs_delete_$i'),
          ),
          if (i != rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CommunityServiceRow extends StatefulWidget {
  const _CommunityServiceRow({
    super.key,
    required this.controllers,
    required this.onDelete,
    required this.deleteKey,
  });

  final _CommunityServiceRowControllers controllers;
  final VoidCallback onDelete;
  final Key deleteKey;

  @override
  State<_CommunityServiceRow> createState() => _CommunityServiceRowState();
}

class _CommunityServiceRowState extends State<_CommunityServiceRow> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;
    final eligible = c.isEligibleNow;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.activity,
                  decoration: const InputDecoration(labelText: 'Community service'),
                ),
              ),
              IconButton(
                key: widget.deleteKey,
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Delete',
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c.role,
            decoration: const InputDecoration(labelText: 'Role'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Months:', style: AppFonts.body(fontSize: 12, color: AppColors.muted)),
              IconButton(
                key: const Key('cs_months_minus'),
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: c.months > 0
                    ? () => setState(() => c.months--)
                    : null,
              ),
              Text('${c.months}', style: AppFonts.body(weight: FontWeight.w700)),
              IconButton(
                key: const Key('cs_months_plus'),
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => setState(() => c.months++),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: c.proof,
                    onChanged: (v) => setState(() => c.proof = v ?? false),
                  ),
                  Text('Proof letter', style: AppFonts.body(fontSize: 12)),
                ],
              ),
              _EligibilityBadge(eligible: eligible),
            ],
          ),
        ],
      ),
    );
  }
}

extension on _CommunityServiceRowControllers {
  /// Live eligibility, computed the same way as `CommunityServiceEntry.
  /// isEligible` — kept here rather than round-tripping through a
  /// throwaway entry object on every keystroke, since [months]/[proof]
  /// already live directly on this controller.
  bool get isEligibleNow => months >= 4 && proof;
}

class _EligibilityBadge extends StatelessWidget {
  const _EligibilityBadge({required this.eligible});
  final bool eligible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: eligible ? AppColors.greenSoft : AppColors.surface,
        border: eligible ? null : Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        eligible ? 'eligible' : 'not yet',
        style: AppFonts.mono(
          fontSize: 9,
          weight: FontWeight.w600,
          color: eligible ? AppColors.green : AppColors.muted,
        ),
      ),
    );
  }
}

/// Section B — Student Organizations. Read-only, genuinely wired to
/// `previewClubWeek` (Day 5's fix — see `activities_report_controller.
/// dart` and `student_activities_report.dart`'s doc comments for why
/// this is a fix rather than a bug replicated). Recomputed live via
/// `ref.watch` on `clubSubmissionProvider`, same "always re-derive,
/// never cache" philosophy as `requiredClubProvider`.
class _StudentOrganizationsSection extends ConsumerWidget {
  const _StudentOrganizationsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submission = ref.watch(clubSubmissionProvider);
    final grade = ref.watch(authControllerProvider).session?.grade;

    final rows = <({String club, String role, String dates})>[];
    if (submission != null && grade != null) {
      final requiredClub = requiredClubFor(submission.anchorMajor);
      if (requiredClub != null) {
        final sessionDays = sessionDaysFor(sessionBandForGrade(grade));
        final preview = previewClubWeek(
          requiredClub: requiredClub,
          rankedOthers: submission.rankedOthers,
          sessionDays: sessionDays,
        );
        // Dedup, preserving first-occurrence order — mirrors the JS's
        // `[...new Set(...)]` exactly.
        final seen = <String>{};
        for (final entry in preview.plan) {
          final club = entry.club;
          if (club != null && seen.add(club)) {
            rows.add((club: club, role: 'Member', dates: 'Jul 2025 – Jun 2026'));
          }
        }
      }
    }

    return _SectionCard(
      title: 'B. Student Organizations',
      caption: 'auto from your clubs',
      child: rows.isEmpty
          ? Text(
              'Submit your clubs to auto-fill this section',
              style: AppFonts.body(color: AppColors.muted, fontSize: 12.5),
            )
          : Column(
              children: [
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(row.club, style: AppFonts.body(fontSize: 13)),
                        ),
                        Expanded(
                          child: Text(
                            row.role,
                            style: AppFonts.body(fontSize: 13, color: AppColors.muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            row.dates,
                            style: AppFonts.body(fontSize: 13, color: AppColors.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
