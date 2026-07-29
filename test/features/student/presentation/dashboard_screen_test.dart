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
import 'package:runata_pathway/features/student/data/student_hive_providers.dart';
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/data/student_tests_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/application_document_state.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/grade_subject_entry.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/student_grades_settings.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
import 'package:runata_pathway/features/student/presentation/dashboard_screen.dart';

class _FakeTargetsRepository extends StudentUniversityTargetsRepository {
  _FakeTargetsRepository(super.box, [List<UniversityTarget>? initial]) : _targets = [...?initial];
  final List<UniversityTarget> _targets;
  @override
  List<UniversityTarget> loadAll() => _targets;
  @override
  Future<void> upsert(UniversityTarget target) async => _targets.add(target);
  @override
  Future<void> delete(String id) async => _targets.removeWhere((t) => t.id == id);
}

class _FakeTestsRepository extends StudentTestsRepository {
  _FakeTestsRepository(super.box, [List<TestEntry>? initial]) : _tests = [...?initial];
  final List<TestEntry> _tests;
  @override
  List<TestEntry> loadAll() => _tests;
  @override
  Future<void> upsert(TestEntry entry) async => _tests.add(entry);
  @override
  Future<void> delete(String id) async => _tests.removeWhere((t) => t.id == id);
}

class _FakeClubsRepository extends StudentClubsRepository {
  _FakeClubsRepository(super.box, [StudentClubSelection? initial]) : _selection = initial;
  StudentClubSelection? _selection;
  @override
  StudentClubSelection? loadSelection() => _selection;
  @override
  Future<void> saveSelection(StudentClubSelection selection) async => _selection = selection;
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

class _StubDestination extends StatelessWidget {
  const _StubDestination(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(label)));
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(UniversityTargetAdapter());
    registerAdapterIfNeeded(TestTypeAdapter());
    registerAdapterIfNeeded(TestStatusAdapter());
    registerAdapterIfNeeded(TestEntryAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
    registerAdapterIfNeeded(DocumentStatusAdapter());
    registerAdapterIfNeeded(ApplicationDocumentStateAdapter());
    registerAdapterIfNeeded(GradeSubjectGroupAdapter());
    registerAdapterIfNeeded(GradeSubjectEntryAdapter());
    registerAdapterIfNeeded(GradeTrackAdapter());
    registerAdapterIfNeeded(StudentGradesSettingsAdapter());
  });

  tearDown(() async => tearDownTestHive());

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.studentDashboard,
      routes: [
        GoRoute(
          path: AppRoutes.studentDashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        for (final path in [
          AppRoutes.studentHome,
          AppRoutes.studentTargetUniversities,
          AppRoutes.studentClubs,
          AppRoutes.studentTests,
          AppRoutes.studentGrades,
          AppRoutes.studentMaterials,
        ])
          GoRoute(path: path, builder: (context, state) => _StubDestination(path)),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    String boxPrefix, {
    List<UniversityTarget>? targets,
    List<TestEntry>? tests,
    List<GradeSubjectEntry>? gradeEntries,
    StudentClubSelection? clubSelection,
    StudentActivitiesReport? activitiesReport,
    StudentPortfolio? portfolio,
    Map<String, ApplicationDocumentState>? applicationDocs,
    String grade = '11',
  }) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final targetsBox = await tester.runAsync(
      () => Hive.openBox<UniversityTarget>('$boxPrefix-targets'),
    );
    final testsBox = await tester.runAsync(() => Hive.openBox<TestEntry>('$boxPrefix-tests'));
    final gradesBox = await tester.runAsync(
      () => Hive.openBox<GradeSubjectEntry>('$boxPrefix-grades'),
    );
    final gradesSettingsBox = await tester.runAsync(
      () => Hive.openBox<StudentGradesSettings>('$boxPrefix-grades-settings'),
    );
    final clubsBox = await tester.runAsync(
      () => Hive.openBox<StudentClubSelection>('$boxPrefix-clubs'),
    );
    final activitiesBox = await tester.runAsync(
      () => Hive.openBox<StudentActivitiesReport>('$boxPrefix-activities'),
    );
    final portfolioBox = await tester.runAsync(
      () => Hive.openBox<StudentPortfolio>('$boxPrefix-portfolio'),
    );
    final docsBox = await tester.runAsync(
      () => Hive.openBox<ApplicationDocumentState>('$boxPrefix-docs'),
    );

    if (gradeEntries != null) {
      await tester.runAsync(() async {
        for (final e in gradeEntries) {
          await gradesBox!.put(e.id, e);
        }
      });
    }

    final container = ProviderContainer(
      overrides: [
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          _FakeTargetsRepository(targetsBox!, targets),
        ),
        studentTestsRepositoryProvider.overrideWithValue(_FakeTestsRepository(testsBox!, tests)),
        studentGradesBoxProvider.overrideWithValue(gradesBox!),
        studentGradesSettingsBoxProvider.overrideWithValue(gradesSettingsBox!),
        studentClubsRepositoryProvider
            .overrideWithValue(_FakeClubsRepository(clubsBox!, clubSelection)),
        studentActivitiesReportRepositoryProvider.overrideWithValue(
          _FakeActivitiesReportRepository(activitiesBox!, activitiesReport),
        ),
        studentPortfolioRepositoryProvider
            .overrideWithValue(_FakePortfolioRepository(portfolioBox!, portfolio)),
        studentApplicationDocumentsRepositoryProvider.overrideWithValue(
          _FakeApplicationDocumentsRepository(docsBox!, applicationDocs),
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
    testWidgets('shows the greeting, subtitle, ring at 0%, and all 7 side '
        'menu items', (tester) async {
      await pumpScreen(tester, 'dash_static');

      expect(find.text('Hey Test 👋'), findsOneWidget);
      expect(find.textContaining('major not set'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);

      // "Overview" and "Grades" only appear once (the mini-stat for
      // grades says "Latest avg", not "Grades"). The other 5 menu
      // labels are ALSO mini-stat labels in the Overview panel below —
      // legitimately shown twice, same reasoning as Nav Grid's roadmap/
      // tile title overlap.
      expect(find.text('Overview'), findsNWidgets(2));
      expect(find.text('Grades'), findsOneWidget);
      for (final label in ['Target unis', 'Tests', 'Fit', 'Activities', 'Materials']) {
        expect(find.text(label), findsNWidgets(2), reason: label);
      }
    });

    testWidgets('shows the anchor major once clubs are submitted', (tester) async {
      await pumpScreen(
        tester,
        'dash_anchor',
        clubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const [],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(find.textContaining('Computer Science'), findsOneWidget);
    });

    testWidgets('Overview panel shows the next-steps section and its '
        'first 3 items when nothing is done', (tester) async {
      await pumpScreen(tester, 'dash_overview');

      expect(find.text('YOUR NEXT STEPS'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_next_step_targetUniversities')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_next_step_clubs')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_next_step_tests')), findsOneWidget);
    });
  });

  group('completion ring reflects real data', () {
    testWidgets('3 of 6 signals done shows 50%', (tester) async {
      await pumpScreen(
        tester,
        'dash_ring_half',
        targets: [
          UniversityTarget(id: 't1', major: 'CS', country: 'Germany', university: 'TU Munich'),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts)],
        // Deliberately NOT submitting clubs here — even with zero ranked
        // others, a submission makes clubsCount=1 (the required club
        // alone), which ALSO flips hasActivities true (activities.total
        // > 0), turning this into 4 of 6, not 3. Grades is used instead
        // as the 3rd signal, keeping this test's math genuinely clean.
        gradeEntries: [
          GradeSubjectEntry(
            id: 'g1',
            semesterCode: SemesterCode.gr11s1,
            name: 'Math',
            score: 85,
            group: GradeSubjectGroup.coreSubjects,
          ),
        ],
      );

      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('all 6 signals done shows 100% and "all done" next-steps '
        'message', (tester) async {
      await pumpScreen(
        tester,
        'dash_ring_full',
        targets: [
          UniversityTarget(id: 't1', major: 'CS', country: 'Germany', university: 'TU Munich'),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts)],
        clubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const [],
          submittedAt: DateTime(2026, 1, 1),
        ),
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
        applicationDocs: {
          'personal': ApplicationDocumentState(docKey: 'personal', content: {'g11': 'Draft text'}),
        },
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_next_steps_all_done')), findsOneWidget);
    });
  });

  group('side menu switching', () {
    testWidgets('tapping a non-Overview item shows its real panel and '
        'hides the Overview panel', (tester) async {
      await pumpScreen(tester, 'dash_menu_switch');

      expect(find.text('YOUR NEXT STEPS'), findsOneWidget);

      await tester.tap(find.byKey(const Key('dashboard_menu_grades')));
      await tester.pumpAndSettle();

      expect(find.text('YOUR NEXT STEPS'), findsNothing);
      expect(find.byKey(const Key('dashboard_panel_open_grades')), findsOneWidget);
      expect(find.text('Record your marks after each report.'), findsOneWidget);
    });

    testWidgets('switching back to Overview restores it', (tester) async {
      await pumpScreen(tester, 'dash_menu_back');

      await tester.tap(find.byKey(const Key('dashboard_menu_fit')));
      await tester.pumpAndSettle();
      expect(find.text('YOUR NEXT STEPS'), findsNothing);

      await tester.tap(find.byKey(const Key('dashboard_menu_overview')));
      await tester.pumpAndSettle();
      expect(find.text('YOUR NEXT STEPS'), findsOneWidget);
    });
  });

  group('Target universities panel', () {
    testWidgets('shows "No targets yet." when empty', (tester) async {
      await pumpScreen(tester, 'dash_target_empty');
      await tester.tap(find.byKey(const Key('dashboard_menu_target')));
      await tester.pumpAndSettle();

      expect(find.text('No targets yet.'), findsOneWidget);
    });

    testWidgets('shows a chip per target and the correct count', (tester) async {
      await pumpScreen(
        tester,
        'dash_target_chips',
        targets: [
          UniversityTarget(id: 't1', major: 'CS', country: 'Germany', university: 'TU Munich'),
          UniversityTarget(id: 't2', major: 'CS', country: 'China', university: 'Tsinghua'),
        ],
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_target')));
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('TU Munich'), findsOneWidget);
      expect(find.text('Tsinghua'), findsOneWidget);
    });

    testWidgets('"Open Target universities →" navigates to the real route',
        (tester) async {
      await pumpScreen(tester, 'dash_target_nav');
      await tester.tap(find.byKey(const Key('dashboard_menu_target')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_panel_open_target')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentTargetUniversities), findsOneWidget);
    });
  });

  group('Tests panel', () {
    testWidgets('shows "None added yet." when empty', (tester) async {
      await pumpScreen(tester, 'dash_tests_empty');
      await tester.tap(find.byKey(const Key('dashboard_menu_tests')));
      await tester.pumpAndSettle();

      expect(find.text('None added yet.'), findsOneWidget);
    });

    testWidgets('shows a chip with type + latest score per test', (tester) async {
      await pumpScreen(
        tester,
        'dash_tests_chips',
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '7.0')],
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_tests')));
      await tester.pumpAndSettle();

      expect(find.text('IELTS 7.0'), findsOneWidget);
    });

    testWidgets('"Open My tests →" navigates to the real route', (tester) async {
      await pumpScreen(tester, 'dash_tests_nav');
      await tester.tap(find.byKey(const Key('dashboard_menu_tests')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_panel_open_tests')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentTests), findsOneWidget);
    });
  });

  group('Fit panel — all 4 branches', () {
    testWidgets('no targets → prompt to pick one first', (tester) async {
      await pumpScreen(tester, 'dash_fit_no_targets');
      await tester.tap(find.byKey(const Key('dashboard_menu_fit')));
      await tester.pumpAndSettle();

      expect(find.text('Pick a target university first.'), findsOneWidget);
    });

    testWidgets('targets but no IELTS test → prompt to add IELTS', (tester) async {
      await pumpScreen(
        tester,
        'dash_fit_no_ielts',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'CS',
            country: 'Australia',
            university: 'University of Melbourne',
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_fit')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('in My tests to unlock fit', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a real catalog match with a tracked IELTS requirement → '
        'shows the fit chip and university name', (tester) async {
      await pumpScreen(
        tester,
        'dash_fit_found',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'CS',
            country: 'Australia',
            university: 'University of Melbourne', // real entry, ielts: 6.5
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '6.5')],
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_fit')));
      await tester.pumpAndSettle();

      expect(find.text('Met'), findsOneWidget); // gap = 0 → met
      expect(find.text('University of Melbourne'), findsOneWidget);
    });

    testWidgets('no tracked-IELTS match anywhere → non-IELTS routes message',
        (tester) async {
      await pumpScreen(
        tester,
        'dash_fit_non_ielts',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'CS',
            country: 'Indonesia',
            university: 'Universitas Indonesia (UI)', // real entry, ielts: null
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '7.0')],
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_fit')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('non-IELTS routes'),
        findsOneWidget,
      );
    });

    testWidgets('"Open Target universities →" navigates correctly', (tester) async {
      await pumpScreen(tester, 'dash_fit_nav');
      await tester.tap(find.byKey(const Key('dashboard_menu_fit')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_panel_open_fit')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentTargetUniversities), findsOneWidget);
    });
  });

  group('Grades panel', () {
    testWidgets('shows the record-marks prompt when nothing is filled in',
        (tester) async {
      await pumpScreen(tester, 'dash_grades_empty');
      await tester.tap(find.byKey(const Key('dashboard_menu_grades')));
      await tester.pumpAndSettle();

      expect(find.text('Record your marks after each report.'), findsOneWidget);
    });

    testWidgets('shows the latest average and semester count once filled in',
        (tester) async {
      await pumpScreen(
        tester,
        'dash_grades_filled',
        gradeEntries: [
          GradeSubjectEntry(
            id: 'g1',
            semesterCode: SemesterCode.gr11s1,
            name: 'Math',
            score: 85,
            group: GradeSubjectGroup.coreSubjects,
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_grades')));
      await tester.pumpAndSettle();

      expect(find.text('85.0'), findsOneWidget);
      expect(find.text('latest · 1 semester'), findsOneWidget);
    });

    testWidgets('"Open My grades →" navigates to the real route', (tester) async {
      await pumpScreen(tester, 'dash_grades_nav');
      await tester.tap(find.byKey(const Key('dashboard_menu_grades')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_panel_open_grades')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentGrades), findsOneWidget);
    });
  });

  group('Activities panel', () {
    testWidgets('shows the combined total and the club/entry breakdown',
        (tester) async {
      await pumpScreen(
        tester,
        'dash_activities_breakdown',
        activitiesReport: StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: 'Debate Club')],
        ),
        clubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const ['Sports Club'],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_activities')));
      await tester.pumpAndSettle();

      // 1 activity row + (1 required + 1 ranked) clubs = 3 total.
      expect(find.text('3'), findsOneWidget);
      expect(find.textContaining('2 clubs'), findsOneWidget);
      expect(find.textContaining('1 entries'), findsOneWidget);
    });

    testWidgets('"Open activities →" navigates to Application Materials',
        (tester) async {
      await pumpScreen(tester, 'dash_activities_nav');
      await tester.tap(find.byKey(const Key('dashboard_menu_activities')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_panel_open_activities')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentMaterials), findsOneWidget);
    });
  });

  group('Materials panel', () {
    testWidgets('shows the started count and a non-empty progress bar',
        (tester) async {
      await pumpScreen(
        tester,
        'dash_materials_progress',
        applicationDocs: {
          'personal': ApplicationDocumentState(docKey: 'personal', content: {'g11': 'Draft'}),
        },
      );
      await tester.tap(find.byKey(const Key('dashboard_menu_materials')));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_materials_progress_bar')), findsOneWidget);
    });

    testWidgets('"Open materials →" navigates to the real route', (tester) async {
      await pumpScreen(tester, 'dash_materials_nav');
      await tester.tap(find.byKey(const Key('dashboard_menu_materials')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_panel_open_materials')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentMaterials), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping a next-step button navigates to its route',
        (tester) async {
      await pumpScreen(tester, 'dash_nav_next_step');

      await tester.tap(find.byKey(const Key('dashboard_next_step_targetUniversities')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentTargetUniversities), findsOneWidget);
    });

    testWidgets("'← Back to home' navigates to the real home route",
        (tester) async {
      await pumpScreen(tester, 'dash_nav_back');

      await tester.tap(find.byKey(const Key('dashboard_back_to_home')));
      await tester.pumpAndSettle();

      expect(find.text(AppRoutes.studentHome), findsOneWidget);
    });
  });
}