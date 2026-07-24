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
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/application_document_state.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
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

/// Needed because opening Activities Report (Day 5 item 2) reads
/// `clubSubmissionProvider`, which depends on this repository — without
/// an override, the real provider would try `Hive.box<StudentClubSelection>`
/// on a box this test's `setUp` never opens.
class _FakeStudentClubsRepository extends StudentClubsRepository {
  _FakeStudentClubsRepository(super.box, [StudentClubSelection? initial])
      : _selection = initial;

  StudentClubSelection? _selection;

  @override
  StudentClubSelection? loadSelection() => _selection;

  @override
  Future<void> saveSelection(StudentClubSelection selection) async {
    _selection = selection;
  }
}

/// New for Day 6's wiring step — the Hub now reads
/// `applicationDocumentsControllerProvider` unconditionally (for every
/// text/upload-kind row's status chip), so every test in this file needs
/// this override even if it never opens an essay doc itself.
class _FakeApplicationDocumentsRepository
    extends StudentApplicationDocumentsRepository {
  _FakeApplicationDocumentsRepository(
    super.box, [
    Map<String, ApplicationDocumentState>? initial,
  ]) : _docs = {...?initial};

  final Map<String, ApplicationDocumentState> _docs;

  @override
  ApplicationDocumentState load(String docKey) =>
      _docs[docKey] ?? ApplicationDocumentState(docKey: docKey);

  @override
  Future<void> save(ApplicationDocumentState doc) async {
    _docs[doc.docKey] = doc;
  }
}

/// New for Day 6's wiring step — `materialsContextProvider` (read by
/// every text-kind row's status chip) depends on this.
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
  Future<void> delete(String id) async {
    _targets.removeWhere((t) => t.id == id);
  }
}

class _StubDestination extends StatelessWidget {
  const _StubDestination(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(label)));
}

// Same sample essay verified word-for-word in document_rubric_test.dart —
// 458 words, meets all 6 of "personal"'s criteria.
const _fullMarksPersonalEssay =
    'Ever since I built my first robot out of spare Lego pieces at age nine, I have been fascinated by how machines can be taught to solve problems on their own. That early curiosity turned into a genuine passion for computer science, one that has only grown stronger through every project I have taken on since, and it now shapes almost every choice I make about how I spend my free time outside of school.\n'
    '\n'
    'In my final two years of school, I led a team of four students in a regional robotics competition, where we designed and programmed an autonomous sorting arm from scratch. When I hit a wall debugging our sensor calibration two days before the deadline, I spent an entire weekend rewriting our control loop, testing each change against the same three obstacle courses over and over until the timing finally felt right. The arm worked exactly as intended on the day of the competition, and we went on to win second place out of eighteen teams from across the region. More importantly than the result itself, I discovered how much I genuinely enjoy the slow, sometimes frustrating process of taking a rough sketch on paper and turning it into something that actually functions reliably in the real world.\n'
    '\n'
    'Outside of competitions, I also founded a small coding club at school to teach younger students the basics of Python, an experience that taught me as much about patient communication as it did about programming itself. Explaining a loop or a conditional statement to a twelve-year-old who has never touched a keyboard before forces you to understand the idea far more deeply than any exam ever could, and watching students who started the term afraid of the terminal end it by building their own simple games was one of the most rewarding things I have done. Running the club for a full academic year also meant learning how to plan sessions, manage a modest budget for equipment, and keep a group of very different personalities engaged week after week.\n'
    '\n'
    'I have come to realise that the course I want to study is not just about writing code, but about understanding the systems that code controls and the people those systems ultimately serve. That is exactly what a Computer Science degree at university would let me explore in far greater depth, moving from the small, self-contained projects I have built so far toward genuinely complex, collaborative systems. Studying this field would let me combine the analytical rigour I developed through the robotics competition with the creative problem solving I have always been drawn to since childhood, and I am ready to bring that same persistence and curiosity to a university programme that challenges me every single day.';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
    registerAdapterIfNeeded(DocumentStatusAdapter());
    registerAdapterIfNeeded(ApplicationDocumentStateAdapter());
    registerAdapterIfNeeded(UniversityTargetAdapter());
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
    StudentClubSelection? initialClubSelection,
    Map<String, ApplicationDocumentState>? initialDocs,
    List<UniversityTarget>? initialTargets,
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
    final clubsBox = await tester.runAsync(
      () => Hive.openBox<StudentClubSelection>('$boxName-clubs'),
    );
    final docsBox = await tester.runAsync(
      () => Hive.openBox<ApplicationDocumentState>('$boxName-docs'),
    );
    final targetsBox = await tester.runAsync(
      () => Hive.openBox<UniversityTarget>('$boxName-targets'),
    );

    final container = ProviderContainer(
      overrides: [
        studentActivitiesReportRepositoryProvider.overrideWithValue(
          _FakeActivitiesReportRepository(reportBox!, initialReport),
        ),
        studentPortfolioRepositoryProvider.overrideWithValue(
          _FakePortfolioRepository(portfolioBox!, initialPortfolio),
        ),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeStudentClubsRepository(clubsBox!, initialClubSelection),
        ),
        studentApplicationDocumentsRepositoryProvider.overrideWithValue(
          _FakeApplicationDocumentsRepository(docsBox!, initialDocs),
        ),
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          _FakeUniversityTargetsRepository(targetsBox!, initialTargets),
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

  /// Finds a widget by [matching] scoped to one specific row — needed
  /// since Day 6 added 6 more rows that can also show a "Not started"
  /// chip, making a bare `find.text('Not started')` count fragile and
  /// coupled to unrelated rows' state.
  Finder inRow(String docKey, Finder matching) {
    return find.descendant(
      of: find.byKey(Key('material_row_$docKey')),
      matching: matching,
    );
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

    testWidgets('all 8 rows have an Open button — nothing is placeholder/'
        'disabled anymore, and no "DAY 6" tag exists anywhere', (tester) async {
      await tester.pumpWidget(await harness(tester, 'materials_open', grade: '10'));
      await tester.pumpAndSettle();

      for (final key in [
        'activities',
        'portfolio',
        'personal',
        'commonapp',
        'studyplan',
        'sop',
        'cv',
        'recletter',
      ]) {
        expect(find.byKey(Key('open_doc_$key')), findsOneWidget, reason: key);
      }
      expect(find.text('DAY 6'), findsNothing);
    });
  });

  group('status chips — Activities Report / Portfolio (report/builder-kind)', () {
    testWidgets('both show "Not started" when empty', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_status_act_empty', grade: '10'),
      );
      await tester.pumpAndSettle();

      expect(inRow('activities', find.text('Not started')), findsOneWidget);
      expect(inRow('portfolio', find.text('Not started')), findsOneWidget);
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

  group('status chips — text-kind essays (Day 6)', () {
    testWidgets('shows "Not started" when nothing has been written for '
        'the currently-selected AY tab', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_text_status_empty', grade: '10'),
      );
      await tester.pumpAndSettle();

      expect(inRow('personal', find.text('Not started')), findsOneWidget);
    });

    testWidgets('shows "Looks strong" once the current tab\'s draft meets '
        '80%+ of its criteria', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_text_status_strong',
          grade: '11', // defaults to the Gr 11 tab
          initialDocs: {
            'personal': ApplicationDocumentState(
              docKey: 'personal',
              content: {'g11': _fullMarksPersonalEssay},
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(inRow('personal', find.text('Looks strong')), findsOneWidget);
    });

    testWidgets('the chip is scoped to the selected AY tab, not to whether '
        'ANY tab has content — switching tabs changes it', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_text_status_ay_scoped',
          grade: '11', // defaults to the Gr 11 tab
          initialDocs: {
            'personal': ApplicationDocumentState(
              docKey: 'personal',
              content: {'g10': _fullMarksPersonalEssay}, // g10 only
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Gr 11 is selected by default, and 'personal' has no g11 content.
      expect(inRow('personal', find.text('Not started')), findsOneWidget);

      await tester.tap(find.byKey(const Key('ay_tab_g10')));
      await tester.pumpAndSettle();

      expect(inRow('personal', find.text('Looks strong')), findsOneWidget);
    });
  });

  group('status chips — Recommendation Letters (upload-kind, Day 6)', () {
    testWidgets('shows "Not started" until uploaded', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_upload_status_empty', grade: '10'),
      );
      await tester.pumpAndSettle();

      expect(inRow('recletter', find.text('Not started')), findsOneWidget);
    });

    testWidgets('shows "Uploaded" once submitted, even with no link text',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_upload_status_submitted',
          grade: '10',
          initialDocs: {
            'recletter': ApplicationDocumentState(docKey: 'recletter', submitted: true),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(inRow('recletter', find.text('Uploaded')), findsOneWidget);
    });

    testWidgets('shows "Uploaded" once a non-empty link/filename is saved, '
        'even without the submitted toggle', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'materials_upload_status_note',
          grade: '10',
          initialDocs: {
            'recletter': ApplicationDocumentState(docKey: 'recletter', note: 'letter.pdf'),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(inRow('recletter', find.text('Uploaded')), findsOneWidget);
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
        'tapping Open on Activities Report shows the real report screen, '
        'with a way back to the row list', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_open_activities', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_doc_activities')));
      await tester.pumpAndSettle();

      expect(find.text('A. Mandatory Grade Level Program'), findsOneWidget);
      expect(find.text('Portfolio'), findsNothing); // Hub row list is gone

      await tester.tap(find.byKey(const Key('activities_back_to_hub')));
      await tester.pumpAndSettle();

      expect(find.text('Student Activities Report'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
    });

    testWidgets('tapping Open on Portfolio shows the real portfolio screen',
        (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_open_portfolio', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_doc_portfolio')));
      await tester.pumpAndSettle();

      expect(find.text('My works'), findsOneWidget);
      expect(find.text('Maker / artist statement'), findsOneWidget);
    });

    testWidgets(
        'tapping Open on Personal Statement shows the shared essay screen, '
        'with a way back to the row list', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_open_personal', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_doc_personal')));
      await tester.pumpAndSettle();

      expect(find.text('Personal Statement (UCAS)'), findsOneWidget); // AppBar
      expect(find.byKey(const Key('essay_doc_content')), findsOneWidget);
      expect(find.text('Portfolio'), findsNothing); // Hub row list is gone

      await tester.tap(find.byKey(const Key('essay_doc_back')));
      await tester.pumpAndSettle();

      expect(find.text('Student Activities Report'), findsOneWidget);
    });

    testWidgets('tapping Open on Recommendation Letters shows the '
        'upload-kind variant of the shared essay screen (no textarea, no '
        'checklist)', (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'materials_open_recletter', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open_doc_recletter')));
      await tester.pumpAndSettle();

      expect(find.text('Recommendation Letters'), findsOneWidget); // AppBar
      expect(find.byKey(const Key('essay_doc_content')), findsNothing);
      expect(find.byKey(const Key('essay_doc_toggle_uploaded')), findsOneWidget);
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