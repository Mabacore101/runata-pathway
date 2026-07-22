import 'package:hive_ce/hive_ce.dart';

part 'activity_entry.g.dart';

/// One repeatable row shared by Student Activities Report's sections A,
/// D, E, and F — identical shape (Activity/Role/Dates), confirmed by the
/// behavioral spec: "A, D, E, F — identical repeatable-entry template
/// (Activity/Role/Dates, all text, no field validation, no cap)." Only
/// the section header and "+ Add" button LABEL differ between them (A:
/// "+ Add Activity", D/E/F: "+ Add Entry") — that's presentation-layer
/// text, not a reason for 4 separate model classes.
///
/// Section B (Student Organizations) has NO entry of this type stored —
/// it's computed live from `previewClubWeek` against the student's
/// persisted `StudentClubSelection`, never written to Hive itself. See
/// `StudentActivitiesReport`'s doc comment for why.
@HiveType(typeId: 13)
class ActivityEntry {
  ActivityEntry({this.activity, this.role, this.dates});

  @HiveField(0)
  String? activity;

  @HiveField(1)
  String? role;

  @HiveField(2)
  String? dates;
}
