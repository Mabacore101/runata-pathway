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
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';
import 'package:runata_pathway/features/student/presentation/application_materials_screen.dart';

/// Same fake-repository rationale as my_clubs_screen_test.dart's own doc
/// comment: real Hive I/O can't resolve inside testWidgets' pumped
/// frames. Accepts a seed record so tests can start from "already has
/// data" without driving row-entry UI that doesn't exist until items 2/3.
class _FakeActivitiesReportRepository
    extends StudentActivitiesReportRepository {
  _FakeActivitiesReportRepository(super.box, [StudentActivitiesReport? initial])
      : _report = initial ?? StudentActivitiesReport();

  StudentActivitiesReport _report;

  @override
  StudentActivitiesReport load() => _report;

  @override
  Future<void> save(StudentActivitiesReport report) async {
    _report = report;
  }
}

class _FakePortfolioRepository extends StudentPortfolioRepository {
  _FakePortfolioRepository(super.box, [StudentPortfolio? initial])
      : _portfolio = initial ?? StudentPortfolio();

  StudentPortfolio _portfolio;

  @override
  StudentPortfolio load() => _portfolio;

  @override
  Future<void> save(StudentPortfolio portfolio) async {
    _portfolio = portfolio;
  }
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
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
  });

  tearDown(() async => tearDownTestHive());

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.studentMaterials,
      routes: [
        GoRoute(
          path: AppRoutes.studentMaterials,
          builder: (context, state) => const ApplicationMaterialsScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (context, state) => const _StubDestination('Home stub'),
        ),
      ],
    );
  }

  Future<Widget> harness(
    WidgetTester tester,
    String boxName, {
    required String grade,
    StudentActivitiesReport? initialReport,
    StudentPortfolio? initialPortfolio,
  }) async {
    // Same viewport-size fix as the other Day 2–4 screen tests: 8 rows +
    // header + tabs + back button push past the default 800x600 surface.
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final reportBox = await tester.runAsync(
      () => Hive.openBox<StudentActivitiesReport>('$boxName-activities'),
    );
    final portfolioBox = await tester.runAsync(
      () => Hive.openBox<StudentPortfolio>('$boxName-portfolio'),
    );

    final container = ProviderContainer(
      overrides: [
        studentActivitiesReportRepositoryProvider.overrideWithValue(
          _FakeActivitiesReportRepository(reportBox!, initialReport),
        ),
        studentPortfolioRepositoryProvider.overrideWithValue(
          _FakePortfolioRepository(portfolioBox!, initialPortfolio),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider.notifier).state = AuthState(
      session: StudentSession(
        studentId: '2627001',
        name: 'Test Student',
        grade: grade,
      ),
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  Color? colorOfTabLabel(WidgetTester tester, String label) {
    return tester.widget<Text>(find.text(label)).style?.color;
  }

  group('the 8 DOCS rows', () {
    testWidgets('all 8 rows render with their real names', (tester) async {
      await tester.pumpWidget(await harness(tester, 'materials_rows', grade: '10'));
      await tester.pumpAndSettle();

      expect(find.text('Student Activities Report'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Personal Statement (UCAS)'), findsOneWidget);
      expect(find.text('Common App Essay'), findsOneWidget);
      expect(find.text('Study Plan'), findsOneWidget);
      expect(find.text('Statement of Purpose / Motivation Letter'), findsOneWidget);
      expect(find.text('CV / Resume'), findsOneWidget);
      expect(find.text('Recommendation Letters'), findsOneWidget);
    });

    testWidgets(
        'only Activities Report and Portfolio have an Open button — the '
        'other 6 show a DAY 6 tag instead', (tester) async {
      await tester.pumpWidget(await harness(tester, 'materials_open', grade: '10'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open_doc_activities')), findsOneWidget);
      expect(find.byKey(const Key('open_doc_portfolio')), findsOneWidget);
      expect(find.byKey(const Key('open_doc_personal')), findsNothing);
      expect(find.byKey(const Key('open_doc_recletter')), findsNothing);
      expect(find.text('DAY 6'), findsNWidgets(6));
    });
  });

  group('status chips', () {
    testWidgets('Activities Report shows "Not started" when empty',
        (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_status_act_empty', grade: '10'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not started'), findsNWidgets(2)); // report + portfolio
    });

    testWidgets(
        'Activities Report shows "Started" once any section has an '
        'activity name filled in', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_status_act_started',
          grade: '10',
          initialReport: StudentActivitiesReport(
            sectionF: [ActivityEntry(activity: 'Chess Club')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Started'), findsOneWidget);
    });

    testWidgets(
        'Portfolio shows a live "N works" count, not just started/not '
        'started', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_status_portfolio_count',
          grade: '10',
          initialPortfolio: StudentPortfolio(
            works: [
              PortfolioWorkEntry(title: 'Piece 1'),
              PortfolioWorkEntry(title: 'Piece 2'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 works'), findsOneWidget);
    });

    testWidgets('Portfolio shows singular "1 work" for exactly one entry',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_status_portfolio_singular',
          grade: '10',
          initialPortfolio: StudentPortfolio(
            works: [PortfolioWorkEntry(title: 'Only piece')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 work'), findsOneWidget);
    });
  });

  group('grade tabs', () {
    testWidgets('Grade 10 session defaults to the Gr 10 tab selected',
        (tester) async {
      await tester.pumpWidget(await harness(tester, 'materials_tabs_g10', grade: '10'));
      await tester.pumpAndSettle();

      expect(colorOfTabLabel(tester, 'Gr 10'), Colors.white);
      expect(colorOfTabLabel(tester, 'Gr 11'), isNot(Colors.white));
      expect(colorOfTabLabel(tester, 'Gr 12'), isNot(Colors.white));
    });

    testWidgets('Grade 12 session defaults to the Gr 12 tab selected',
        (tester) async {
      await tester.pumpWidget(await harness(tester, 'materials_tabs_g12', grade: '12'));
      await tester.pumpAndSettle();

      expect(colorOfTabLabel(tester, 'Gr 12'), Colors.white);
      expect(colorOfTabLabel(tester, 'Gr 10'), isNot(Colors.white));
    });

    testWidgets('tapping a different tab switches the selected tab',
        (tester) async {
      await tester.pumpWidget(await harness(tester, 'materials_tabs_switch', grade: '10'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('ay_tab_g12')));
      await tester.pumpAndSettle();

      expect(colorOfTabLabel(tester, 'Gr 12'), Colors.white);
      expect(colorOfTabLabel(tester, 'Gr 10'), isNot(Colors.white));
    });

    testWidgets(
        "switching tabs doesn't change Activities Report/Portfolio's "
        'status — neither is scoped by AY (only Day 6\'s essay docs are)',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_tabs_no_scope',
          grade: '10',
          initialReport: StudentActivitiesReport(
            sectionA: [ActivityEntry(activity: 'Debate Team')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Started'), findsOneWidget);

      await tester.tap(find.byKey(const Key('ay_tab_g12')));
      await tester.pumpAndSettle();

      expect(find.text('Started'), findsOneWidget);
    });
  });

  group('opening a real doc', () {
    testWidgets(
        'tapping Open on Activities Report shows its placeholder detail '
        'view, with a way back to the row list', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_open_activities', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_doc_activities')));
      await tester.pumpAndSettle();

      expect(find.text('Student Activities Report — coming next'), findsOneWidget);
      expect(find.text('Portfolio'), findsNothing); // Hub row list is gone

      await tester.tap(find.byKey(const Key('materials_back_to_hub')));
      await tester.pumpAndSettle();

      expect(find.text('Student Activities Report'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
    });

    testWidgets('tapping Open on Portfolio shows its own placeholder',
        (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_open_portfolio', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_doc_portfolio')));
      await tester.pumpAndSettle();

      expect(find.text('Portfolio — coming next'), findsOneWidget);
    });
  });

  testWidgets("'← Back to home' navigates to the home route", (tester) async {
    await tester.pumpWidget(await harness(tester, 'materials_back_home', grade: '10'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('← Back to home'));
    await tester.pumpAndSettle();

    expect(find.text('Home stub'), findsOneWidget);
  });
}