// NOTE: replace `runata_pathway` below with whatever `name:` your
// pubspec.yaml actually declares, if it's different.
import 'package:flutter_test/flutter_test.dart';
import 'package:runata_pathway/features/auth/data/local_student_auth_repository.dart';
import 'package:runata_pathway/features/auth/domain/auth_failure.dart';

void main() {
  late LocalStudentAuthRepository repository;

  setUp(() {
    repository = LocalStudentAuthRepository();
  });

  group('LocalStudentAuthRepository.signIn', () {
    test('returns a session for a matching Student ID + password', () async {
      final session = await repository.signIn(
        studentId: '2627001',
        password: '2627001',
      );
      expect(session.studentId, '2627001');
      expect(session.name, isNotEmpty);
    });

    test('throws InvalidCredentialsException for a wrong password', () async {
      expect(
        () => repository.signIn(studentId: '2627001', password: 'wrong'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('throws InvalidCredentialsException for an unknown Student ID',
        () async {
      expect(
        () => repository.signIn(
          studentId: 'does-not-exist',
          password: 'anything',
        ),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test(
        'wrong-password and unknown-ID failures carry the SAME generic '
        'message — per spec, the login form never distinguishes the two',
        () async {
      String? messageForWrongPassword;
      String? messageForUnknownId;

      try {
        await repository.signIn(studentId: '2627001', password: 'wrong');
      } on InvalidCredentialsException catch (e) {
        messageForWrongPassword = e.message;
      }

      try {
        await repository.signIn(
          studentId: 'does-not-exist',
          password: 'anything',
        );
      } on InvalidCredentialsException catch (e) {
        messageForUnknownId = e.message;
      }

      expect(messageForWrongPassword, isNotNull);
      expect(messageForWrongPassword, equals(messageForUnknownId));
    });

    test('rejects an empty password', () async {
      expect(
        () => repository.signIn(studentId: '2627001', password: ''),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('trims whitespace around the Student ID before matching', () async {
      final session = await repository.signIn(
        studentId: '  2627001  ',
        password: '2627001',
      );
      expect(session.studentId, '2627001');
    });
  });
}
