import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_student_auth_repository.dart';
import '../domain/auth_failure.dart';
import 'auth_state.dart';

final studentAuthRepositoryProvider = Provider<LocalStudentAuthRepository>((ref) {
  return LocalStudentAuthRepository();
});

/// Modern (non-legacy) Riverpod 3.x Notifier — StateNotifierProvider was
/// moved to `package:flutter_riverpod/legacy.dart` in Riverpod 3.0, so this
/// uses the current recommended API instead of adding that legacy import.
final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  LocalStudentAuthRepository get _repository =>
      ref.read(studentAuthRepositoryProvider);

  Future<void> signIn({
    required String studentId,
    required String password,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final session = await _repository.signIn(
        studentId: studentId,
        password: password,
      );
      state = state.copyWith(
        session: session,
        isSubmitting: false,
        clearError: true,
      );
    } on InvalidCredentialsException catch (e) {
      // Single generic bucket — never say which part was wrong.
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Incorrect Student ID or password.',
      );
    }
  }

  void signOut() {
    state = state.copyWith(clearSession: true, clearError: true);
  }
}