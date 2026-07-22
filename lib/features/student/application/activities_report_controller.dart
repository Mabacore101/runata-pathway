import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_activities_report_repository.dart';
import '../domain/student_activities_report.dart';

/// Day 5 item 1 scope: read-only exposure of the persisted report, just
/// enough for the Hub's "Started"/"Not started" status chip
/// (`StudentActivitiesReport.hasAnyData`).
///
/// Section A/C/D/E/F's actual add/edit/delete-row logic (mirroring
/// `ProfileController`'s save-on-explicit-button pattern, since neither
/// the field/datatype doc nor the behavioral spec describes autosave
/// here the way Portfolio has it) and Section B's live wiring to
/// `previewClubWeek` land in item 2, as methods added to this same
/// controller — this shape doesn't change, it only grows.
final activitiesReportControllerProvider =
    NotifierProvider<ActivitiesReportController, StudentActivitiesReport>(
  ActivitiesReportController.new,
);

class ActivitiesReportController extends Notifier<StudentActivitiesReport> {
  @override
  StudentActivitiesReport build() =>
      ref.read(studentActivitiesReportRepositoryProvider).load();
}
