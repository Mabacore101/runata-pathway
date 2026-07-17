import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_tests_repository.dart';
import '../domain/test_entry.dart';

final testsControllerProvider =
    NotifierProvider<TestsController, List<TestEntry>>(TestsController.new);

/// State is just the current list of rows — unlike Profile there's no
/// extra transient-feedback field to track, since there's no equivalent
/// to the birth-date warning here.
///
/// Per the flow spec's diagram for My Tests:
/// `[Click "+ Test Type"] → [New Test Row Created] → [Edit Fields] or
/// [Delete Row] → [Save]` — adding and deleting a ROW are immediate,
/// persisted actions (mirrored by [addTest]/[deleteTest] below), but
/// editing a row's FIELDS (target/latest/status/date) is NOT persisted
/// per keystroke — those stay in the screen's own local
/// `TextEditingController`s until [saveAll] runs, same deferred-edit
/// pattern as `ProfileController.save()`.
class TestsController extends Notifier<List<TestEntry>> {
  @override
  List<TestEntry> build() => ref.read(studentTestsRepositoryProvider).loadAll();

  StudentTestsRepository get _repository =>
      ref.read(studentTestsRepositoryProvider);

  /// Creates and immediately persists a new blank row for [type].
  ///
  /// Guards the duplicate-block rule itself rather than trusting the UI
  /// to have already hidden the "+ [Type]" button for a non-AP/Other type
  /// that's already present — defense in depth, since the whole point of
  /// centralizing `duplicateAllowedTestTypes` (see test_entry.dart) was to
  /// have exactly one place this rule lives. If this somehow gets called
  /// for an already-added, non-duplicate-allowed type anyway, it's a
  /// no-op that returns the existing row instead of creating a second one.
  Future<TestEntry> addTest(TestType type) async {
    final alreadyAdded = state.any((t) => t.type == type);
    if (alreadyAdded && !duplicateAllowedTestTypes.contains(type)) {
      return state.firstWhere((t) => t.type == type);
    }

    final entry = TestEntry(id: _generateId(type), type: type);
    await _repository.upsert(entry);
    state = [...state, entry];
    return entry;
  }

  Future<void> deleteTest(String id) async {
    await _repository.delete(id);
    state = state.where((t) => t.id != id).toList();
  }

  /// Persists every row's current field values in one batch. [updatedRows]
  /// comes from the screen's local row controllers — this is the only
  /// place target/latest/status/date actually reach Hive.
  Future<void> saveAll(List<TestEntry> updatedRows) async {
    for (final row in updatedRows) {
      await _repository.upsert(row);
    }
    state = updatedRows;
  }

  static String _generateId(TestType type) =>
      '${type.name}_${DateTime.now().microsecondsSinceEpoch}';
}
