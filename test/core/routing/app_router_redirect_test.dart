// NOTE: replace `runata_pathway` below with whatever `name:` your
// pubspec.yaml actually declares, if it's different.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/core/routing/app_router.dart';
import 'package:runata_pathway/features/auth/application/auth_controller.dart';
import 'package:runata_pathway/features/auth/domain/student_session.dart';
import 'package:runata_pathway/features/auth/presentation/choose_role_screen.dart';
import 'package:runata_pathway/features/auth/presentation/student_login_screen.dart';
import 'package:runata_pathway/features/student/data/student_activities_report_repository.dart';
import 'package:runata_pathway/features/student/data/student_application_documents_repository.dart';
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/data/student_counsellor_corner_repository.dart';
import 'package:runata_pathway/features/student/data/student_hive_providers.dart';
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/data/student_profile_repository.dart';
import 'package:runata_pathway/features/student/data/student_tests_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/application_document_state.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/counsellor_corner.dart';
import 'package:runata_pathway/features/student/domain/grade_subject_entry.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';
import 'package:runata_pathway/features/student/domain/student_profile.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
import 'package:runata_pathway/features/student/presentation/student_home_screen.dart';

/// No-op fakes — this file tests REDIRECT behavior, not Home's own
/// content, so every fake here just needs to exist and never throw; none
/// of these tests care what values Home ends up reading.
class _NoOpProfileRepository extends StudentProfileRepository {
  _NoOpProfileRepository(super.box);
  @override
  StudentProfile load() => StudentProfile();
  @override
  Future<void> save(StudentProfile profile) async {}
}

class _NoOpUniversityTargetsRepository extends StudentUniversityTargetsRepository {
  _NoOpUniversityTargetsRepository(super.box);
  @override
  List<UniversityTarget> loadAll() => const [];
  @override
  Future<void> upsert(UniversityTarget target) async {}
  @override
  Future<void> delete(String id) async {}
}

class _NoOpClubsRepository extends StudentClubsRepository {
  _NoOpClubsRepository(super.box);
  @override
  StudentClubSelection? loadSelection() => null;
  @override
  Future<void> saveSelection(StudentClubSelection selection) async {}
}

class _NoOpTestsRepository extends StudentTestsRepository {
  _NoOpTestsRepository(super.box);
  @override
  List<TestEntry> loadAll() => const [];
  @override
  Future<void> upsert(TestEntry entry) async {}
  @override
  Future<void> delete(String id) async {}
}

class _NoOpActivitiesReportRepository extends StudentActivitiesReportRepository {
  _NoOpActivitiesReportRepository(super.box);
  @override
  StudentActivitiesReport load() => StudentActivitiesReport();
  @override
  Future<void> save(StudentActivitiesReport report) async {}
}

class _NoOpPortfolioRepository extends StudentPortfolioRepository {
  _NoOpPortfolioRepository(super.box);
  @override
  StudentPortfolio load() => StudentPortfolio();
  @override
  Future<void> save(StudentPortfolio portfolio) async {}
}

class _NoOpApplicationDocumentsRepository extends StudentApplicationDocumentsRepository {
  _NoOpApplicationDocumentsRepository(super.box);
  @override
  ApplicationDocumentState load(String docKey) => ApplicationDocumentState(docKey: docKey);
  @override
  Future<void> save(ApplicationDocumentState doc) async {}
}

class _NoOpCounsellorCornerRepository extends StudentCounsellorCornerRepository {
  _NoOpCounsellorCornerRepository(super.box);
  @override
  CounsellorCorner load() => CounsellorCorner();
  @override
  Future<void> save(CounsellorCorner record) async {}
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(StudentProfileAdapter());
    registerAdapterIfNeeded(UniversityTargetAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
    registerAdapterIfNeeded(TestTypeAdapter());
    registerAdapterIfNeeded(TestStatusAdapter());
    registerAdapterIfNeeded(TestEntryAdapter());
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
    registerAdapterIfNeeded(DocumentStatusAdapter());
    registerAdapterIfNeeded(ApplicationDocumentStateAdapter());
    registerAdapterIfNeeded(CounsellorCornerAdapter());
    registerAdapterIfNeeded(GradeSubjectGroupAdapter());
    registerAdapterIfNeeded(GradeSubjectEntryAdapter());
  });

  tearDown(() async => tearDownTestHive());

  /// Opens every box `StudentHomeScreen`'s data dependencies need and
  /// returns a ready-to-use container with matching no-op repository
  /// overrides — this file cares about WHERE navigation lands, not what
  /// Home displays once there, so every fake here is intentionally
  /// inert. [boxPrefix] keeps each test's boxes independent, same
  /// reasoning every other test file in this project already uses per-
  /// test box names. Builds the whole container here (rather than
  /// returning just the overrides list) specifically so nothing in this
  /// file needs to name Riverpod's override type explicitly.
  Future<ProviderContainer> buildHomeScreenTestContainer(
    WidgetTester tester,
    String boxPrefix,
  ) async {
    final profileBox =
        await tester.runAsync(() => Hive.openBox<StudentProfile>('$boxPrefix-profile'));
    final targetsBox =
        await tester.runAsync(() => Hive.openBox<UniversityTarget>('$boxPrefix-targets'));
    final clubsBox =
        await tester.runAsync(() => Hive.openBox<StudentClubSelection>('$boxPrefix-clubs'));
    final testsBox = await tester.runAsync(() => Hive.openBox<TestEntry>('$boxPrefix-tests'));
    final gradesBox =
        await tester.runAsync(() => Hive.openBox<GradeSubjectEntry>('$boxPrefix-grades'));
    final activitiesBox = await tester.runAsync(
      () => Hive.openBox<StudentActivitiesReport>('$boxPrefix-activities'),
    );
    final portfolioBox =
        await tester.runAsync(() => Hive.openBox<StudentPortfolio>('$boxPrefix-portfolio'));
    final docsBox = await tester.runAsync(
      () => Hive.openBox<ApplicationDocumentState>('$boxPrefix-docs'),
    );
    final counsellorBox =
        await tester.runAsync(() => Hive.openBox<CounsellorCorner>('$boxPrefix-counsellor'));

    return ProviderContainer(
      overrides: [
        studentProfileRepositoryProvider.overrideWithValue(_NoOpProfileRepository(profileBox!)),
        studentUniversityTargetsRepositoryProvider
            .overrideWithValue(_NoOpUniversityTargetsRepository(targetsBox!)),
        studentClubsRepositoryProvider.overrideWithValue(_NoOpClubsRepository(clubsBox!)),
        studentTestsRepositoryProvider.overrideWithValue(_NoOpTestsRepository(testsBox!)),
        studentGradesBoxProvider.overrideWithValue(gradesBox!),
        studentActivitiesReportRepositoryProvider
            .overrideWithValue(_NoOpActivitiesReportRepository(activitiesBox!)),
        studentPortfolioRepositoryProvider
            .overrideWithValue(_NoOpPortfolioRepository(portfolioBox!)),
        studentApplicationDocumentsRepositoryProvider
            .overrideWithValue(_NoOpApplicationDocumentsRepository(docsBox!)),
        studentCounsellorCornerRepositoryProvider
            .overrideWithValue(_NoOpCounsellorCornerRepository(counsellorBox!)),
      ],
    );
  }

  testWidgets(
      'unsigned-in user deep-linking to /student/home is redirected to login',
      (tester) async {
    final container = await buildHomeScreenTestContainer(tester, 'redirect_unsigned_home');
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
    final container = await buildHomeScreenTestContainer(tester, 'redirect_unsigned_dash');
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
    final container = await buildHomeScreenTestContainer(tester, 'redirect_session_start');
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
            grade: '10', // Day 4: now required — value itself is irrelevant
            // to this test, which only checks the redirect, not clubs.
          ),
        );
    await tester.pumpAndSettle();

    expect(find.byType(StudentHomeScreen), findsOneWidget);
    expect(find.byType(ChooseRoleScreen), findsNothing);
  });

  testWidgets(
      'signed-in user hitting the login route directly is bounced to home',
      (tester) async {
    final container = await buildHomeScreenTestContainer(tester, 'redirect_login_bounce');
    addTearDown(container.dispose);

    final notifier = container.read(authControllerProvider.notifier);
    notifier.state = container.read(authControllerProvider).copyWith(
          session: const StudentSession(
            studentId: '2627001',
            name: 'Test Student',
            grade: '10',
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
    final container = await buildHomeScreenTestContainer(tester, 'redirect_session_end');
    addTearDown(container.dispose);

    final notifier = container.read(authControllerProvider.notifier);
    notifier.state = container.read(authControllerProvider).copyWith(
          session: const StudentSession(
            studentId: '2627001',
            name: 'Test Student',
            grade: '10',
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