import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/core/routing/app_router.dart';
import 'package:runata_pathway/features/auth/application/auth_controller.dart';
import 'package:runata_pathway/features/auth/application/auth_state.dart';
import 'package:runata_pathway/features/auth/domain/student_session.dart';
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

class _FakeProfileRepository extends StudentProfileRepository {
  _FakeProfileRepository(super.box, [StudentProfile? initial])
      : _profile = initial ?? StudentProfile();
  StudentProfile _profile;
  @override
  StudentProfile load() => _profile;
  @override
  Future<void> save(StudentProfile profile) async => _profile = profile;
}

class _FakeUniversityTargetsRepository extends StudentUniversityTargetsRepository {
  _FakeUniversityTargetsRepository(super.box, [List<UniversityTarget>? initial])
      : _targets = [...?initial];
  final List<UniversityTarget> _targets;
  @override
  List<UniversityTarget> loadAll() => _targets;
  @override
  Future<void> upsert(UniversityTarget target) async {
    _targets.removeWhere((t) => t.id == target.id);
    _targets.add(target);
  }

  @override
  Future<void> delete(String id) async => _targets.removeWhere((t) => t.id == id);
}

class _FakeClubsRepository extends StudentClubsRepository {
  _FakeClubsRepository(super.box, [StudentClubSelection? initial]) : _selection = initial;
  StudentClubSelection? _selection;
  @override
  StudentClubSelection? loadSelection() => _selection;
  @override
  Future<void> saveSelection(StudentClubSelection selection) async => _selection = selection;
}

class _FakeTestsRepository extends StudentTestsRepository {
  _FakeTestsRepository(super.box, [List<TestEntry>? initial]) : _tests = [...?initial];
  final List<TestEntry> _tests;
  @override
  List<TestEntry> loadAll() => _tests;
  @override
  Future<void> upsert(TestEntry entry) async {
    _tests.removeWhere((t) => t.id == entry.id);
    _tests.add(entry);
  }

  @override
  Future<void> delete(String id) async => _tests.removeWhere((t) => t.id == id);
}

class _FakeActivitiesReportRepository extends StudentActivitiesReportRepository {
  _FakeActivitiesReportRepository(super.box, [StudentActivitiesReport? initial])
      : _report = initial ?? StudentActivitiesReport();
  StudentActivitiesReport _report;
  @override
  StudentActivitiesReport load() => _report;
  @override
  Future<void> save(StudentActivitiesReport report) async => _report = report;
}

class _FakePortfolioRepository extends StudentPortfolioRepository {
  _FakePortfolioRepository(super.box, [StudentPortfolio? initial])
      : _portfolio = initial ?? StudentPortfolio();
  StudentPortfolio _portfolio;
  @override
  StudentPortfolio load() => _portfolio;
  @override
  Future<void> save(StudentPortfolio portfolio) async => _portfolio = portfolio;
}

class _FakeApplicationDocumentsRepository extends StudentApplicationDocumentsRepository {
  _FakeApplicationDocumentsRepository(
    super.box, [
    Map<String, ApplicationDocumentState>? initial,
  ]) : _docs = {...?initial};
  final Map<String, ApplicationDocumentState> _docs;
  @override
  ApplicationDocumentState load(String docKey) =>
      _docs[docKey] ?? ApplicationDocumentState(docKey: docKey);
  @override
  Future<void> save(ApplicationDocumentState doc) async => _docs[doc.docKey] = doc;
}

class _FakeCounsellorCornerRepository extends StudentCounsellorCornerRepository {
  _FakeCounsellorCornerRepository(super.box, [CounsellorCorner? initial])
      : _record = initial ?? CounsellorCorner();
  CounsellorCorner _record;
  @override
  CounsellorCorner load() => _record;
  @override
  Future<void> save(CounsellorCorner record) async => _record = record;
}

class _StubDestination extends StatelessWidget {
  const _StubDestination(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(label)));
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

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.studentHome,
      routes: [
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (context, state) => const StudentHomeScreen(),
        ),
        for (final path in [
          AppRoutes.chooseRole,
          AppRoutes.studentDashboard,
          AppRoutes.studentProfile,
          AppRoutes.studentTests,
          AppRoutes.studentGrades,
          AppRoutes.studentTargetUniversities,
          AppRoutes.studentClubs,
          AppRoutes.studentMaterials,
          AppRoutes.studentCounsellorCorner,
          AppRoutes.studentCountryPathways,
        ])
          GoRoute(path: path, builder: (context, state) => _StubDestination(path)),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    String boxPrefix, {
    StudentProfile? profile,
    List<UniversityTarget>? targets,
    StudentClubSelection? clubSelection,
    List<TestEntry>? tests,
    List<GradeSubjectEntry>? gradeEntries,
    StudentActivitiesReport? activitiesReport,
    StudentPortfolio? portfolio,
    Map<String, ApplicationDocumentState>? applicationDocs,
    CounsellorCorner? counsellorCorner,
    String grade = '11',
  }) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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

    if (gradeEntries != null) {
      await tester.runAsync(() async {
        for (final e in gradeEntries) {
          await gradesBox!.put(e.id, e);
        }
      });
    }

    final container = ProviderContainer(
      overrides: [
        studentProfileRepositoryProvider
            .overrideWithValue(_FakeProfileRepository(profileBox!, profile)),
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          _FakeUniversityTargetsRepository(targetsBox!, targets),
        ),
        studentClubsRepositoryProvider
            .overrideWithValue(_FakeClubsRepository(clubsBox!, clubSelection)),
        studentTestsRepositoryProvider
            .overrideWithValue(_FakeTestsRepository(testsBox!, tests)),
        studentGradesBoxProvider.overrideWithValue(gradesBox!),
        studentActivitiesReportRepositoryProvider.overrideWithValue(
          _FakeActivitiesReportRepository(activitiesBox!, activitiesReport),
        ),
        studentPortfolioRepositoryProvider
            .overrideWithValue(_FakePortfolioRepository(portfolioBox!, portfolio)),
        studentApplicationDocumentsRepositoryProvider.overrideWithValue(
          _FakeApplicationDocumentsRepository(docsBox!, applicationDocs),
        ),
        studentCounsellorCornerRepositoryProvider.overrideWithValue(
          _FakeCounsellorCornerRepository(counsellorBox!, counsellorCorner),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider.notifier).state = AuthState(
      session: StudentSession(studentId: '2627001', name: 'Test Student', grade: grade),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildTestRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('static content', () {
    testWidgets('shows the greeting, dashboard CTA, roadmap header, and '
        'all 8 nav tile titles', (tester) async {
      await pumpScreen(tester, 'home_static');

      expect(find.text('Hi Test 👋'), findsOneWidget);
      expect(find.byKey(const Key('home_dashboard_cta')), findsOneWidget);
      expect(find.text('🪜 Your pathway — start here'), findsOneWidget);

      // These 6 titles are shared with the roadmap card above (the same
      // 6 steps appear as both a roadmap row AND a nav tile — matches
      // the JS, which renders the same title text in both places) —
      // each shows up TWICE on screen, not once.
      for (final title in [
        'My clubs',
        'Target universities',
        'Application materials',
        'My tests',
        'My grades',
        "Student's Profile",
      ]) {
        expect(find.text(title), findsNWidgets(2), reason: title);
      }

      // These 2 are nav-grid-only — Counsellor's Corner and Pathways
      // have no roadmap step, so each appears exactly once.
      for (final title in ["Counsellor's Corner", 'Pathways']) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });
  });

  group('roadmap done/next/later logic', () {
    testWidgets('with nothing filled in anywhere, step 1 (profile) is '
        '"next" and every other step is "later"', (tester) async {
      await pumpScreen(tester, 'roadmap_all_empty');

      expect(find.text('Start →'), findsOneWidget);
      expect(find.text('Done'), findsNothing);

      final step0 = find.byKey(const Key('roadmap_step_0'));
      expect(
        find.descendant(of: step0, matching: find.text('Start →')),
        findsOneWidget,
      );
    });

    testWidgets(
        'entering a grade AFTER the screen is already showing updates the '
        'roadmap without needing to navigate away and back — regression '
        'test for a real bug found in manual testing (the grades count '
        'used to cache forever, since a Hive Box mutating in place never '
        'changes the watched Box object reference Riverpod was comparing '
        'against)', (tester) async {
      await pumpScreen(tester, 'roadmap_grade_added_live');

      final step4 = find.byKey(const Key('roadmap_step_4')); // My grades
      expect(find.descendant(of: step4, matching: find.text('Done')), findsNothing);

      // Write directly to the SAME box this screen instance is already
      // watching — simulating "went to Grades, entered a score, came
      // back" without actually navigating away from this screen at all.
      await tester.runAsync(() async {
        final gradesBox =
            Hive.box<GradeSubjectEntry>('roadmap_grade_added_live-grades');
        await gradesBox.put(
          'g1',
          GradeSubjectEntry(
            id: 'g1',
            semesterCode: SemesterCode.gr11s1,
            name: 'Math',
            score: 88,
            group: GradeSubjectGroup.coreSubjects,
          ),
        );
      });
      await tester.pumpAndSettle();

      expect(find.descendant(of: step4, matching: find.text('Done')), findsOneWidget);
    });

    testWidgets('marking the first step done advances "next" to the '
        'second step', (tester) async {
      await pumpScreen(
        tester,
        'roadmap_first_done',
        profile: StudentProfile(phoneNumber: '08123456789'),
      );

      final step0 = find.byKey(const Key('roadmap_step_0'));
      final step1 = find.byKey(const Key('roadmap_step_1'));

      expect(find.descendant(of: step0, matching: find.text('Done')), findsOneWidget);
      expect(find.descendant(of: step1, matching: find.text('Start →')), findsOneWidget);
      expect(find.text('Start →'), findsOneWidget);
    });

    testWidgets('a step done OUT OF ORDER still shows "Done", even though '
        'an earlier step remains "next" — a step\'s own done flag always '
        'wins over its position', (tester) async {
      // Materials (step index 5, last) is done; nothing before it is.
      await pumpScreen(
        tester,
        'roadmap_out_of_order',
        activitiesReport: StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: 'Debate Club')],
        ),
      );

      final step0 = find.byKey(const Key('roadmap_step_0')); // profile — next
      final step5 = find.byKey(const Key('roadmap_step_5')); // materials — done

      expect(find.descendant(of: step0, matching: find.text('Start →')), findsOneWidget);
      expect(find.descendant(of: step5, matching: find.text('Done')), findsOneWidget);
      expect(find.text('Start →'), findsOneWidget);
    });

    testWidgets('with every step done, every row shows "Done" and no '
        '"next" label exists anywhere', (tester) async {
      await pumpScreen(
        tester,
        'roadmap_all_done',
        profile: StudentProfile(phoneNumber: '08123456789'),
        targets: [
          UniversityTarget(id: 't1', major: 'CS', country: 'Germany', university: 'TU Munich'),
        ],
        clubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const [],
          submittedAt: DateTime(2026, 1, 1),
        ),
        tests: [TestEntry(id: 'e1', type: TestType.ielts)],
        gradeEntries: [
          GradeSubjectEntry(
            id: 'g1',
            semesterCode: SemesterCode.gr11s1,
            name: 'Math',
            score: 85,
            group: GradeSubjectGroup.coreSubjects,
          ),
        ],
        activitiesReport: StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: 'Debate Club')],
        ),
      );

      expect(find.text('Start →'), findsNothing);
      expect(find.text('Done'), findsNWidgets(6));
    });
  });

  group('nav tile subtitles reflect real data', () {
    testWidgets('Target universities tile shows the real count', (tester) async {
      await pumpScreen(
        tester,
        'tile_targets_count',
        targets: [
          UniversityTarget(id: 't1', major: 'CS', country: 'Germany', university: 'TU Munich'),
          UniversityTarget(id: 't2', major: 'CS', country: 'China', university: 'Tsinghua'),
        ],
      );

      expect(find.textContaining('2 on your list'), findsOneWidget);
    });

    testWidgets('My clubs tile reflects the unsubmitted state', (tester) async {
      await pumpScreen(tester, 'tile_clubs_unsubmitted');
      expect(find.textContaining('Not started · choose your clubs'), findsOneWidget);
    });

    testWidgets("Counsellor's Corner tile reflects filled state", (tester) async {
      await pumpScreen(
        tester,
        'tile_counsellor_filled',
        counsellorCorner: CounsellorCorner(qualityTime: 'Dinner nightly'),
      );

      expect(find.textContaining('Filled · view or edit your answers'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping the dashboard CTA navigates to Dashboard', (tester) async {
      await pumpScreen(tester, 'nav_dashboard');

      await tester.tap(find.byKey(const Key('home_dashboard_cta')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentDashboard), findsOneWidget);
    });

    testWidgets('tapping a roadmap step navigates to its route', (tester) async {
      await pumpScreen(tester, 'nav_roadmap_step');

      await tester.tap(find.byKey(const Key('roadmap_step_0'))); // profile
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentProfile), findsOneWidget);
    });

    testWidgets('tapping a nav tile navigates to its route', (tester) async {
      await pumpScreen(tester, 'nav_tile_tap');

      await tester.tap(find.byKey(const Key('nav_tile_pathways')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentCountryPathways), findsOneWidget);
    });

    testWidgets('Sign out navigates to Choose Role', (tester) async {
      await pumpScreen(tester, 'nav_sign_out');

      await tester.tap(find.byKey(const Key('home_sign_out')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.chooseRole), findsOneWidget);
    });
  });
}