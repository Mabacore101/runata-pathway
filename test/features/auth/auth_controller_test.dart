// NOTE: replace `runata_pathway` below with whatever `name:` your
// pubspec.yaml actually declares, if it's different.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runata_pathway/features/auth/application/auth_controller.dart';

void main() {
  // AuthController is a Notifier, so it needs a ProviderContainer to
  // resolve its dependency (LocalStudentAuthRepository) via `ref` — it
  // can no longer be constructed bare like a plain StateNotifier could.
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test(
      'signIn with valid credentials updates state to signed-in with no error',
      () async {
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.signIn(studentId: '2627001', password: '2627001');

    final state = container.read(authControllerProvider);
    expect(state.isSignedIn, isTrue);
    expect(state.session?.studentId, '2627001');
    expect(state.errorMessage, isNull);
    expect(state.isSubmitting, isFalse);
  });

  test(
      'signIn with invalid credentials sets a generic errorMessage and '
      'stays signed-out', () async {
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.signIn(studentId: '2627001', password: 'wrong');

    final state = container.read(authControllerProvider);
    expect(state.isSignedIn, isFalse);
    expect(state.errorMessage, isNotNull);
    expect(state.isSubmitting, isFalse);
  });

  test('a fresh sign-in attempt clears a previous error message', () async {
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.signIn(studentId: '2627001', password: 'wrong');
    expect(container.read(authControllerProvider).errorMessage, isNotNull);

    await notifier.signIn(studentId: '2627001', password: '2627001');
    final state = container.read(authControllerProvider);
    expect(state.errorMessage, isNull);
    expect(state.isSignedIn, isTrue);
  });

  test('signOut clears an active session', () async {
    final notifier = container.read(authControllerProvider.notifier);

    await notifier.signIn(studentId: '2627001', password: '2627001');
    expect(container.read(authControllerProvider).isSignedIn, isTrue);

    notifier.signOut();

    final state = container.read(authControllerProvider);
    expect(state.isSignedIn, isFalse);
    expect(state.session, isNull);
  });
}