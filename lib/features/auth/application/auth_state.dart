import '../domain/student_session.dart';

class AuthState {
  const AuthState({
    this.session,
    this.isSubmitting = false,
    this.errorMessage,
  });

  const AuthState.initial() : this();

  final StudentSession? session;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isSignedIn => session != null;

  AuthState copyWith({
    StudentSession? session,
    bool clearSession = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      session: clearSession ? null : (session ?? this.session),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
