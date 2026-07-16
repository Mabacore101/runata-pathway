/// Box name constants for every Hive box the app opens. Centralized here
/// so a typo in a raw string literal can't silently open a second,
/// different box by accident — every call site should reference these
/// constants, never a literal string.
class HiveBoxes {
  HiveBoxes._();

  static const studentProfile = 'student_profile_box';
  static const studentTests = 'student_tests_box';
  static const studentGrades = 'student_grades_box';
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
}
