import 'package:hive_ce/hive_ce.dart';

part 'student_club_selection.g.dart';

/// A submitted club selection — Day 4 item 4.
///
/// Mirrors the JS's `submissions[stu.n]` shape, but only the fields My
/// Clubs actually owns: `anchorMajor` and `ranked` (renamed here to
/// [rankedOthers] to match [ClubRankingController]'s own naming) plus
/// `submittedAt`. The JS's `submissions` record ALSO carries `majors`/
/// `top3` snapshots — those belong to Explore Majors' own submission
/// concept, not My Clubs', and aren't modeled here.
///
/// Deliberately has NO "empty default" factory the way
/// [StudentGradesSettings]/[StudentMajorsSettings] do — unlike those,
/// where an empty-but-present record is a meaningful state (partial
/// save), "never submitted" and "submitted with nothing" aren't the same
/// thing for My Clubs. [StudentClubsRepository.loadSelection] returns
/// `null` for "never submitted" instead.
///
/// `anchorMajor` stores the MAJOR name (e.g. "Computer Science"), not
/// the club — matches [requiredClubProvider]'s "always re-derive, never
/// cache" philosophy: [rankedOthers] gets re-checked against whatever
/// `requiredClubFor(anchorMajor)` resolves to TODAY every time this
/// record is read, the same way the JS's `reEdit` handler re-filters
/// against a freshly-computed `MAJOR_CLUB[am]` rather than trusting a
/// stored club name that could go stale if the majors catalog changes.
@HiveType(typeId: 12)
class StudentClubSelection {
  StudentClubSelection({
    required this.anchorMajor,
    required this.rankedOthers,
    required this.submittedAt,
  });

  @HiveField(0)
  String anchorMajor;

  @HiveField(1)
  List<String> rankedOthers;

  @HiveField(2)
  DateTime submittedAt;
}
