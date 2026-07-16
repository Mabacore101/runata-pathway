// NOTE: replace `runata_pathway` below with whatever `name:` your
// pubspec.yaml actually declares, if it's different.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runata_pathway/core/routing/app_router.dart';
import 'package:runata_pathway/features/auth/application/auth_controller.dart';
import 'package:runata_pathway/features/auth/domain/student_session.dart';
import 'package:runata_pathway/features/auth/presentation/choose_role_screen.dart';
import 'package:runata_pathway/features/auth/presentation/student_login_screen.dart';
import 'package:runata_pathway/features/student/presentation/student_home_screen.dart';

void main() {
  testWidgets(
      'unsigned-in user deep-linking to /student/home is redirected to login',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(AppRoutes.studentHome);
    await tester.pumpAndSettle();

    expect(find.byType(StudentLoginScreen), findsOneWidget);
    expect(find.byType(StudentHomeScreen), findsNothing);
  });

  testWidgets(
      'unsigned-in user deep-linking to /student/dashboard is redirected to login',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(AppRoutes.studentDashboard);
    await tester.pumpAndSettle();

    expect(find.byType(StudentLoginScreen), findsOneWidget);
  });

  testWidgets(
      'a session becoming active while already on Choose Role redirects to home',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Sanity check: signed-out, so we should genuinely be on Choose Role
    // before the interesting part of this test even starts.
    expect(find.byType(ChooseRoleScreen), findsOneWidget);

    // A session becomes active with NO explicit navigation call attached —
    // e.g. a session restored from storage after the screen is already
    // showing. This is exactly the scenario `refreshListenable` in
    // app_router.dart exists for: `redirect` only re-runs on a navigation
    // event by default, so without that listenable, nothing would prompt
    // the guard to re-check here, and the app would be stuck showing
    // Choose Role despite already being signed in.
    final notifier = container.read(authControllerProvider.notifier);
    notifier.state = container.read(authControllerProvider).copyWith(
          session: const StudentSession(
            studentId: '2627001',
            name: 'Test Student',
          ),
        );
    await tester.pumpAndSettle();

    expect(find.byType(StudentHomeScreen), findsOneWidget);
    expect(find.byType(ChooseRoleScreen), findsNothing);
  });

  testWidgets(
      'signed-in user hitting the login route directly is bounced to home',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(authControllerProvider.notifier);
    notifier.state = container.read(authControllerProvider).copyWith(
          session: const StudentSession(
            studentId: '2627001',
            name: 'Test Student',
          ),
        );

    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    router.go(AppRoutes.studentLogin);
    await tester.pumpAndSettle();

    expect(find.byType(StudentHomeScreen), findsOneWidget);
  });

  testWidgets(
      'a session ending while on a protected route redirects to login',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(authControllerProvider.notifier);
    notifier.state = container.read(authControllerProvider).copyWith(
          session: const StudentSession(
            studentId: '2627001',
            name: 'Test Student',
          ),
        );

    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go(AppRoutes.studentHome);
    await tester.pumpAndSettle();
    expect(find.byType(StudentHomeScreen), findsOneWidget);

    // End the session directly — no accompanying navigation call, same as
    // the Choose Role test above but in the opposite direction.
    notifier.signOut();
    await tester.pumpAndSettle();

    expect(find.byType(StudentLoginScreen), findsOneWidget);
  });
}