/// The signed-in student's identity, held in [AuthState] for as long as
/// they're signed in.
class StudentSession {
  const StudentSession({
    required this.studentId,
    required this.name,
  });

  final String studentId;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudentSession &&
          other.studentId == studentId &&
          other.name == name);

  @override
  int get hashCode => Object.hash(studentId, name);
}
