import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_activities_report_repository.dart';
import '../domain/activity_entry.dart';
import '../domain/community_service_entry.dart';
import '../domain/student_activities_report.dart';

/// Which of the 4 identical-shape sections (A, D, E, F) a mutation
/// targets. Section C gets its own methods below since
/// `CommunityServiceEntry` isn't interchangeable with `ActivityEntry`.
/// Section B has no entry here at all — see `StudentActivitiesReport`'s
/// doc comment for why.
enum ActivitiesReportSection { a, d, e, f }

/// Day 5 item 2: full read/write controller.
///
/// **Row add/delete are immediate, persisted actions — field edits are
/// batched into [saveAll].** This isn't the Profile/deferred-Save split
/// this file's Day 5 item 1 version assumed; tracing the actual JS
/// handlers shows every section here (`data-spf`'s 'input'/'change'
/// listeners) mutates its in-memory record directly on every keystroke,
/// with the on-screen "Save" button (`#saveNow`) wired to a completely
/// generic, screen-agnostic flush-everything action — not something that
/// reads this form's fields at all. Practically, that means: exactly the
/// same immediate-add/deferred-field-batch split `TestsController`
/// already uses (`addTest`/`deleteTest` persist right away; `saveAll` is
/// the only thing that writes target/latest/status/date) is the correct
/// shape here too — it just needed to be verified against the actual
/// source rather than assumed from the doc/spec's silence on it.
final activitiesReportControllerProvider =
    NotifierProvider<ActivitiesReportController, StudentActivitiesReport>(
  ActivitiesReportController.new,
);

class ActivitiesReportController extends Notifier<StudentActivitiesReport> {
  @override
  StudentActivitiesReport build() =>
      ref.read(studentActivitiesReportRepositoryProvider).load();

  StudentActivitiesReportRepository get _repository =>
      ref.read(studentActivitiesReportRepositoryProvider);

  /// Mirrors the JS's `data-sadd` handler for sections A/D/E/F: appends
  /// a blank row and persists immediately, no cap, no validation.
  Future<void> addActivityRow(ActivitiesReportSection section) async {
    await _persist(_updateSection(section, (rows) => [...rows, ActivityEntry()]));
  }

  /// Mirrors `data-sdel` for A/D/E/F: splice the row out by index and
  /// persist immediately. Out-of-range indices are a no-op rather than
  /// throwing — defense in depth, same reasoning as
  /// `TestsController.addTest`'s duplicate guard.
  Future<void> deleteActivityRow(ActivitiesReportSection section, int index) async {
    await _persist(_updateSection(section, (rows) {
      if (index < 0 || index >= rows.length) return rows;
      return [...rows]..removeAt(index);
    }));
  }

  /// Section C's own add — same immediate-persist shape as
  /// [addActivityRow], different entry type.
  Future<void> addCommunityServiceRow() async {
    await _persist(_copyWith(sectionC: [...state.sectionC, CommunityServiceEntry()]));
  }

  Future<void> deleteCommunityServiceRow(int index) async {
    if (index < 0 || index >= state.sectionC.length) return;
    final sectionC = [...state.sectionC]..removeAt(index);
    await _persist(_copyWith(sectionC: sectionC));
  }

  /// Persists every row's current field values across all 5 stored
  /// sections in one batch — the only place activity/role/dates/months/
  /// proof text actually reaches Hive, mirroring
  /// `TestsController.saveAll`. [updated] comes from the screen's local
  /// per-row `TextEditingController`s, already rebuilt into a full
  /// [StudentActivitiesReport] (row COUNT and ORDER must already match
  /// `state`'s — this only overwrites field values, it doesn't add/
  /// remove rows itself).
  Future<void> saveAll(StudentActivitiesReport updated) async {
    await _persist(updated);
  }

  StudentActivitiesReport _updateSection(
    ActivitiesReportSection section,
    List<ActivityEntry> Function(List<ActivityEntry> current) update,
  ) {
    switch (section) {
      case ActivitiesReportSection.a:
        return _copyWith(sectionA: update(state.sectionA));
      case ActivitiesReportSection.d:
        return _copyWith(sectionD: update(state.sectionD));
      case ActivitiesReportSection.e:
        return _copyWith(sectionE: update(state.sectionE));
      case ActivitiesReportSection.f:
        return _copyWith(sectionF: update(state.sectionF));
    }
  }

  StudentActivitiesReport _copyWith({
    List<ActivityEntry>? sectionA,
    List<CommunityServiceEntry>? sectionC,
    List<ActivityEntry>? sectionD,
    List<ActivityEntry>? sectionE,
    List<ActivityEntry>? sectionF,
  }) {
    return StudentActivitiesReport(
      sectionA: sectionA ?? state.sectionA,
      sectionC: sectionC ?? state.sectionC,
      sectionD: sectionD ?? state.sectionD,
      sectionE: sectionE ?? state.sectionE,
      sectionF: sectionF ?? state.sectionF,
    );
  }

  Future<void> _persist(StudentActivitiesReport updated) async {
    await _repository.save(updated);
    state = updated;
  }
}