import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../application/clubs_controller.dart';
import '../application/portfolio_controller.dart';
import '../domain/majors_catalog.dart';
import '../domain/portfolio_suggestions.dart';
import '../domain/portfolio_work_entry.dart';
import '../domain/student_portfolio.dart';

/// Portfolio — Pathway form 6b (Day 5 item 3).
///
/// Replaces the Hub's "coming next" placeholder for the `'portfolio'`
/// doc key — same `_openDocKey` hook, no routing changes.
///
/// **Autosave, not deferred-Save** — see `PortfolioController`'s doc
/// comment for why this screen is architected differently from
/// Activities Report despite looking superficially similar (both have
/// repeatable rows + a Save button). Every field's `onChanged` writes
/// through immediately; the Save button only shows a reassurance
/// snackbar, same pattern as Target Universities'.
class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _WorkRowControllers {
  _WorkRowControllers({PortfolioWorkEntry? from})
      : title = TextEditingController(text: from?.title ?? ''),
        type = TextEditingController(text: from?.type ?? ''),
        year = TextEditingController(text: from?.year ?? ''),
        role = TextEditingController(text: from?.role ?? ''),
        brief = TextEditingController(text: from?.brief ?? ''),
        link = TextEditingController(text: from?.link ?? '');

  final TextEditingController title;
  final TextEditingController type;
  final TextEditingController year;
  final TextEditingController role;
  final TextEditingController brief;
  final TextEditingController link;

  PortfolioWorkEntry toEntry() => PortfolioWorkEntry(
        title: title.text,
        type: type.text,
        year: year.text,
        role: role.text,
        brief: brief.text,
        link: link.text,
      );

  void dispose() {
    title.dispose();
    type.dispose();
    year.dispose();
    role.dispose();
    brief.dispose();
    link.dispose();
  }
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  late List<_WorkRowControllers> _works;
  late TextEditingController _statement;

  @override
  void initState() {
    super.initState();
    final portfolio = ref.read(portfolioControllerProvider);
    _works = portfolio.works.map((w) => _WorkRowControllers(from: w)).toList();
    _statement = TextEditingController(text: portfolio.statement ?? '');
  }

  @override
  void dispose() {
    for (final w in _works) {
      w.dispose();
    }
    _statement.dispose();
    super.dispose();
  }

  /// Builds the full portfolio from every current controller and writes
  /// it through immediately — called from every field's `onChanged`.
  void _persistNow() {
    ref.read(portfolioControllerProvider.notifier).updateAll(
          StudentPortfolio(
            works: _works.map((w) => w.toEntry()).toList(),
            statement: _statement.text,
          ),
        );
  }

  Future<void> _addWork() async {
    await ref.read(portfolioControllerProvider.notifier).addWork();
    setState(() => _works.add(_WorkRowControllers()));
  }

  Future<void> _deleteWork(int index) async {
    await ref.read(portfolioControllerProvider.notifier).deleteWork(index);
    setState(() {
      _works[index].dispose();
      _works.removeAt(index);
    });
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All changes saved ✓'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final anchorMajor = ref.watch(clubSubmissionProvider)?.anchorMajor;
    final suggestion = _suggestionFor(anchorMajor);

    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
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
                'A portfolio is a curated set of your actual work — each '
                'piece with a short description, plus one maker statement. '
                'Competitions and organisations go in the Student '
                'Activities Report; the work you made goes here. Start '
                'collecting from Grade 10.',
                style: AppFonts.body(fontSize: 12.5, color: AppColors.tealDeep),
              ),
            ),
            const SizedBox(height: 10),
            const _PortfolioVsActivitiesExplainer(),
            if (suggestion != null) ...[
              const SizedBox(height: 10),
              _SuggestionBanner(major: anchorMajor!, suggestion: suggestion),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'My works',
                  style: AppFonts.body(weight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_works.length} work${_works.length == 1 ? '' : 's'}',
                  style: AppFonts.mono(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_works.isEmpty)
              Text(
                'No works yet — add your first piece below.',
                style: AppFonts.body(color: AppColors.muted, fontSize: 12.5),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < _works.length; i++) ...[
                    _WorkCard(
                      key: Key('work_row_$i'),
                      controllers: _works[i],
                      onChanged: _persistNow,
                      onRemove: () => _deleteWork(i),
                      removeKey: Key('work_remove_$i'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('add_work'),
                onPressed: _addWork,
                child: const Text('+ Add a work'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Maker / artist statement',
              style: AppFonts.body(weight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('maker_statement'),
              controller: _statement,
              maxLines: 4,
              onChanged: (_) => _persistNow(),
              decoration: const InputDecoration(
                hintText: 'One short paragraph: what you make, your interests, '
                    'and what ties your work together.',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('portfolio_save'),
                    onPressed: _handleSave,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('portfolio_back_to_hub'),
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

  String? _suggestionFor(String? anchorMajor) {
    if (anchorMajor == null) return null;
    final field = catalogEntryFor(anchorMajor)?.field;
    if (field == null) return null;
    return portfolioFieldSuggestions[field];
  }
}

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({required this.major, required this.suggestion});
  final String major;
  final String suggestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppFonts.body(fontSize: 12.5, color: AppColors.orangeDeep),
                children: [
                  TextSpan(text: 'For ', style: AppFonts.body(fontSize: 12.5, color: AppColors.orangeDeep)),
                  TextSpan(
                    text: major,
                    style: AppFonts.body(fontSize: 12.5, weight: FontWeight.w700, color: AppColors.orangeDeep),
                  ),
                  TextSpan(text: ': $suggestion'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({
    super.key,
    required this.controllers,
    required this.onChanged,
    required this.onRemove,
    required this.removeKey,
  });

  final _WorkRowControllers controllers;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final Key removeKey;

  @override
  Widget build(BuildContext context) {
    final c = controllers;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: c.title,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Title of the work'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.type,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: c.year,
                  onChanged: (_) => onChanged(),
                  decoration: const InputDecoration(labelText: 'Year'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c.role,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(labelText: 'Your role'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c.brief,
            onChanged: (_) => onChanged(),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Brief: what it is, what you did, and the outcome',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c.link,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'Link to the work (Drive / Behance / GitHub / YouTube)',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: removeKey,
              onPressed: onRemove,
              child: const Text('Remove'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Surfaces `portfolioInfoHTML()`'s content — dead code in the original
/// site (defined, never called from anywhere reachable) but flagged by
/// day5-trimmed-source.md as genuinely load-bearing UX worth porting
/// properly. Collapsed by default so it doesn't compete with the works
/// list for attention, but reachable — fixing the "good copy nobody
/// could actually see" gap, same spirit as Section B's auto-fill fix.
class _PortfolioVsActivitiesExplainer extends StatelessWidget {
  const _PortfolioVsActivitiesExplainer();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          "📁 What's the difference — Portfolio vs Activities Report?",
          style: AppFonts.body(weight: FontWeight.w600, fontSize: 12.5, color: AppColors.ink),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          _ExplainerCard(
            heading: 'Student Activities Report',
            body: 'A list of your involvement — clubs, competitions, '
                'community service, committees, school teams — with your '
                'role and dates. It follows the Runata report-card format; '
                'you input it and the school verifies it.',
          ),
          const SizedBox(height: 8),
          _ExplainerCard(
            heading: 'Portfolio',
            body: 'A curated set of your actual work — projects and '
                'creative pieces — each with a short description, plus a '
                'one-paragraph maker statement. It shows evidence, not a '
                'list.',
          ),
          const SizedBox(height: 8),
          Text(
            'Where things go: a competition or organisation → Activities '
            'Report; the work you made for it (the design, the code, the '
            'plan) → Portfolio.',
            style: AppFonts.body(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          Text(
            'Do I need a portfolio? — start collecting from Grade 10',
            style: AppFonts.mono(fontSize: 10.5, weight: FontWeight.w600, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          for (final row in portfolioSuitabilityTable) _SuitabilityRow(row: row),
          const SizedBox(height: 10),
          Text(
            'Even where it\'s only "supporting", collect your work from '
            'Grade 10 — it becomes evidence for your personal statement, '
            'CV and interviews. Add and link your pieces right here.',
            style: AppFonts.body(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ExplainerCard extends StatelessWidget {
  const _ExplainerCard({required this.heading, required this.body});
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: AppFonts.body(weight: FontWeight.w700, fontSize: 12.5, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(body, style: AppFonts.body(fontSize: 12, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _SuitabilityRow extends StatelessWidget {
  const _SuitabilityRow({required this.row});
  final PortfolioSuitabilityRow row;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final Color badgeText;
    switch (row.tone) {
      case PortfolioSuitabilityTone.required_:
        badgeColor = AppColors.greenSoft;
        badgeText = AppColors.green;
      case PortfolioSuitabilityTone.recommended:
        badgeColor = AppColors.amberSoft;
        badgeText = AppColors.amber;
      case PortfolioSuitabilityTone.supporting:
        badgeColor = AppColors.surface2;
        badgeText = AppColors.muted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.fields,
                  style: AppFonts.body(fontSize: 12, weight: FontWeight.w600, color: AppColors.ink),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  row.status,
                  style: AppFonts.mono(fontSize: 8.5, weight: FontWeight.w600, color: badgeText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(row.examples, style: AppFonts.body(fontSize: 11.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}