import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../application/tests_controller.dart';
import '../domain/test_entry.dart';

/// My Tests — Pathway form 3. Add/delete a row happens immediately;
/// editing a row's fields is deferred to the Save button (see
/// tests_controller.dart's doc comment — mirrors the flow spec's
/// diagram exactly).
class TestsScreen extends ConsumerStatefulWidget {
  const TestsScreen({super.key});

  @override
  ConsumerState<TestsScreen> createState() => _TestsScreenState();
}

/// One row's live-edited field values, paired with the controllers that
/// hold them. `id` and `type` are fixed for the row's lifetime (a row's
/// test TYPE is "fixed by type" per the field/datatype doc — there's no
/// UI to change an existing row's type, only to add a new row or delete
/// this one).
class _TestRowControllers {
  _TestRowControllers({required this.id, required this.type, TestEntry? from})
      : target = TextEditingController(text: from?.target ?? ''),
        latest = TextEditingController(text: from?.latest ?? ''),
        date = TextEditingController(text: from?.date ?? ''),
        status = from?.status ?? TestStatus.planned;

  final String id;
  final TestType type;
  final TextEditingController target;
  final TextEditingController latest;
  final TextEditingController date;
  TestStatus status;

  TestEntry toEntry() => TestEntry(
        id: id,
        type: type,
        target: target.text,
        latest: latest.text,
        status: status,
        date: date.text,
      );

  void dispose() {
    target.dispose();
    latest.dispose();
    date.dispose();
  }
}

class _TestsScreenState extends ConsumerState<TestsScreen> {
  late List<_TestRowControllers> _rows;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(testsControllerProvider);
    _rows = initial
        .map((e) => _TestRowControllers(id: e.id, type: e.type, from: e))
        .toList();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Set<TestType> get _typesInUse => _rows.map((r) => r.type).toSet();

  List<TestType> get _availableTypeButtons => TestType.values
      .where((t) =>
          duplicateAllowedTestTypes.contains(t) || !_typesInUse.contains(t))
      .toList();

  Future<void> _addTest(TestType type) async {
    final entry = await ref.read(testsControllerProvider.notifier).addTest(type);
    setState(() {
      _rows.add(_TestRowControllers(id: entry.id, type: entry.type, from: entry));
    });
  }

  Future<void> _deleteTest(int index) async {
    final row = _rows[index];
    await ref.read(testsControllerProvider.notifier).deleteTest(row.id);
    setState(() {
      row.dispose();
      _rows.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    final updated = _rows.map((r) => r.toEntry()).toList();
    await ref.read(testsControllerProvider.notifier).saveAll(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tests saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Tests')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('📝', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Text(
                  'My tests',
                  style: AppFonts.display(fontSize: 20, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Add only the tests you actually take — IELTS, CSCA, HSK, '
              'SAT, or others. Your IELTS / CSCA / SAT automatically feed '
              'the fit check on Target universities.',
              style: AppFonts.body(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            if (_rows.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No tests yet — add the ones you plan to take below.',
                  style: AppFonts.body(color: AppColors.muted),
                ),
              )
            else
              for (var i = 0; i < _rows.length; i++) ...[
                _TestRowCard(
                  controllers: _rows[i],
                  onDelete: () => _deleteTest(i),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 12),

            Text(
              'Add a test',
              style: AppFonts.body(weight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in _availableTypeButtons)
                  OutlinedButton(
                    key: Key('add_test_${type.name}'),
                    onPressed: () => _addTest(type),
                    child: Text('+ ${_testTypeLabel(type)}'),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
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
}

class _TestRowCard extends StatefulWidget {
  const _TestRowCard({required this.controllers, required this.onDelete});

  final _TestRowControllers controllers;
  final VoidCallback onDelete;

  @override
  State<_TestRowCard> createState() => _TestRowCardState();
}

class _TestRowCardState extends State<_TestRowCard> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _testTypeLabel(c.type),
                  style: AppFonts.body(
                    weight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                key: Key('delete_test_${c.id}'),
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Delete',
                onPressed: widget.onDelete,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.target,
                  decoration: const InputDecoration(labelText: 'Target'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: c.latest,
                  decoration: const InputDecoration(labelText: 'Latest'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<TestStatus>(
                  initialValue: c.status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final status in TestStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(_testStatusLabel(status)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => c.status = value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: c.date,
                  decoration: const InputDecoration(labelText: 'Date'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Display labels matching the site's own button/row text exactly — not
/// derived from the enum name (e.g. `TestType.csca.name` is `"csca"`,
/// not `"CSCA"`), since casing here isn't a simple capitalize-first-letter
/// rule (IELTS/CSCA/HSK/SAT are all-caps acronyms, Duolingo/Other/AP are
/// not consistently so).
String _testTypeLabel(TestType type) {
  switch (type) {
    case TestType.ielts:
      return 'IELTS';
    case TestType.toefl:
      return 'TOEFL';
    case TestType.duolingo:
      return 'Duolingo';
    case TestType.sat:
      return 'SAT';
    case TestType.csca:
      return 'CSCA';
    case TestType.hsk:
      return 'HSK';
    case TestType.ap:
      return 'AP';
    case TestType.other:
      return 'Other';
  }
}

String _testStatusLabel(TestStatus status) {
  switch (status) {
    case TestStatus.planned:
      return 'Planned';
    case TestStatus.registered:
      return 'Registered';
    case TestStatus.taken:
      return 'Taken';
  }
}