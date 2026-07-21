/// The signed-in student's identity, held in [AuthState] for as long as
/// they're signed in.
class StudentSession {
  const StudentSession({
    required this.studentId,
    required this.name,
    required this.grade,
  });

  final String studentId;
  final String name;

  /// '10' / '11' / '12' — added for My Clubs (Day 4): pick count, which
  /// days a student has sessions on at all, and the required club's
  /// displayed schedule all branch on grade (day4-trimmed-source.md's
  /// "Read this first" #1). A session-level fact, not something that
  /// belongs on StudentProfile or a My Clubs–specific Hive model.
  final String grade;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentSession &&
          other.studentId == studentId &&
          other.name == name &&
          other.grade == grade);

  @override
  int get hashCode => Object.hash(studentId, name, grade);
}