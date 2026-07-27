/// Box name constants for every Hive box the app opens. Centralized here
/// so a typo in a raw string literal can't silently open a second,
/// different box by accident — every call site should reference these
/// constants, never a literal string.
class HiveBoxes {
  HiveBoxes._();

  static const studentProfile = 'student_profile_box';
  static const studentTests = 'student_tests_box';
  static const studentGrades = 'student_grades_box';
  static const studentGradesSettings = 'student_grades_settings_box';

  /// Explore Majors (Target Universities tab 1) — single-record box, same
  /// pattern as [studentGradesSettings]. The whole majors list (max 6,
  /// with top/anchor flags) lives in one [StudentMajorsSettings] record
  /// under [HiveKeys.studentMajorsSettings], not one entry per box key.
  static const studentMajors = 'student_majors_box';

  /// Find Universities' shortlist — flat, id-keyed collection (one
  /// [UniversityTarget] row per major+country+university combo), same
  /// pattern as [studentTests]. No matching [HiveKeys] entry needed —
  /// unlike the single-record boxes above, each row keys itself by its
  /// own `id`, not a shared fixed key.
  static const studentUniversityTargets = 'student_university_targets_box';

  /// My Clubs' submitted selection (Day 4 item 4) — single-record box,
  /// same pattern as [studentMajors]. One [StudentClubSelection] record
  /// per student under [HiveKeys.studentClubSelection]; `null`/absent
  /// means "never submitted" (see [StudentClubSelection]'s own doc
  /// comment for why that's not defaulted to an empty instance the way
  /// [studentGradesSettings]/[studentMajors] are).
  static const studentClubs = 'student_clubs_box';

  /// Student Activities Report (Day 5) — single-record box, same pattern
  /// as [studentMajors]/[studentClubs]. One [StudentActivitiesReport]
  /// record per student under [HiveKeys.studentActivitiesReport].
  static const studentActivitiesReport = 'student_activities_report_box';

  /// Portfolio (Day 5) — single-record box, same pattern as
  /// [studentActivitiesReport]. One [StudentPortfolio] record per student
  /// under [HiveKeys.studentPortfolio].
  static const studentPortfolio = 'student_portfolio_box';

  /// Application Materials' 5 shared-template essays + Recommendation
  /// Letters (Day 6) — flat, id-keyed collection, same pattern as
  /// [studentUniversityTargets]/[studentTests], NOT the single-record
  /// pattern the boxes above use. Each row keys itself by its own
  /// `docKey` (`personal`/`commonapp`/`studyplan`/`sop`/`cv`/`recletter`
  /// — see `application_materials_catalog.dart`'s `MaterialDoc.key`), so
  /// no matching [HiveKeys] entry is needed, same reasoning as
  /// [studentUniversityTargets]'s own doc comment.
  static const applicationDocuments = 'application_documents_box';

  /// Counsellor's Corner (Day 6) — single-record box, same pattern as
  /// [studentPortfolio]/[studentActivitiesReport]. One [CounsellorCorner]
  /// record per student under [HiveKeys.counsellorCorner].
  static const counsellorCorner = 'counsellor_corner_box';
}

/// Fixed keys used inside boxes that hold a single record rather than a
/// natural collection.
class HiveKeys {
  HiveKeys._();

  /// [HiveBoxes.studentProfile] only ever holds one [StudentProfile] per
  /// signed-in student on this device — there's no multi-account
  /// switching in this app — so it's stored under one constant key
  /// instead of being keyed by student ID.
  static const studentProfile = 'profile';

  /// Same single-record pattern as [studentProfile] — one
  /// [StudentGradesSettings] record per student (track choice + custom
  /// subject names), not one per semester.
  static const studentGradesSettings = 'grades_settings';

  /// Same single-record pattern as [studentGradesSettings] — one
  /// [StudentMajorsSettings] record per student, stored under a fixed key
  /// in [HiveBoxes.studentMajors].
  static const studentMajorsSettings = 'majors_settings';

  /// Same single-record pattern as [studentMajorsSettings] — one
  /// [StudentClubSelection] record per student, stored under a fixed key
  /// in [HiveBoxes.studentClubs].
  static const studentClubSelection = 'club_selection';

  /// Same single-record pattern as [studentClubSelection] — one
  /// [StudentActivitiesReport] record per student, stored under a fixed
  /// key in [HiveBoxes.studentActivitiesReport]. Deliberately holds no
  /// Section B data — see that model's own doc comment.
  static const studentActivitiesReport = 'activities_report';

  /// Same single-record pattern as [studentActivitiesReport] — one
  /// [StudentPortfolio] record per student, stored under a fixed key in
  /// [HiveBoxes.studentPortfolio].
  static const studentPortfolio = 'portfolio';

  /// Same single-record pattern as [studentPortfolio] — one
  /// [CounsellorCorner] record per student, stored under a fixed key in
  /// [HiveBoxes.counsellorCorner].
  static const counsellorCorner = 'counsellor_corner';
}