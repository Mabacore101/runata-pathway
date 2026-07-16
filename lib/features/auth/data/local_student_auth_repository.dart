import '../domain/auth_failure.dart';
import '../domain/student_session.dart';

class _MockStudentRecord {
  const _MockStudentRecord({
    required this.studentId,
    required this.password,
    required this.name,
  });

  final String studentId;
  final String password;
  final String name;
}

/// Local-only stand-in for the real Supabase-backed student login.
///
/// PLANNING.md locks the backend as "local-only for now" — there's no
/// Supabase project to authenticate against yet. This repository keeps the
/// SAME login *behavior* documented in the QA'd flow spec (Student ID +
/// password, single generic error bucket, no field-level errors), so the
/// screen/controller layer above it won't need to change shape later when a
/// real backend is wired in — only this class's internals will.
///
/// The seed roster below mirrors the reference source's own convention
/// ("password defaults to your Student ID") purely so there's something to
/// sign in with during development. Swap this out for a real data source
/// (Hive-cached roster, then eventually Supabase) whenever that becomes
/// available — nothing above this class needs to know when that happens.
class LocalStudentAuthRepository {
  static const _roster = [
    _MockStudentRecord(
      studentId: '2627001',
      password: '2627001',
      name: 'Aditya Pratama',
    ),
    _MockStudentRecord(
      studentId: '2627002',
      password: '2627002',
      name: 'Bunga Lestari',
    ),
  ];

  Future<StudentSession> signIn({
    required String studentId,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // simulate I/O

    final trimmedId = studentId.trim();
    if (trimmedId.isEmpty || password.isEmpty) {
      throw const InvalidCredentialsException();
    }

    final matches = _roster.where(
      (r) => r.studentId == trimmedId && r.password == password,
    );
    if (matches.isEmpty) {
      throw const InvalidCredentialsException();
    }

    final record = matches.first;
    return StudentSession(studentId: record.studentId, name: record.name);
  }
}
