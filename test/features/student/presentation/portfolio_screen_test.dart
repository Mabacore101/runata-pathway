import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';
import 'package:runata_pathway/features/student/presentation/portfolio_screen.dart';

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

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakePortfolioRepository portfolioRepository;
  bool backTapped = false;

  Future<void> pumpScreen(
    WidgetTester tester,
    String boxName, {
    StudentPortfolio? initialPortfolio,
    StudentClubSelection? initialClubSelection,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    backTapped = false;

    final portfolioBox = await tester.runAsync(
      () => Hive.openBox<StudentPortfolio>('$boxName-portfolio'),
    );
    final clubsBox = await tester.runAsync(
      () => Hive.openBox<StudentClubSelection>('$boxName-clubs'),
    );

    portfolioRepository = _FakePortfolioRepository(portfolioBox!, initialPortfolio);

    final container = ProviderContainer(
      overrides: [
        studentPortfolioRepositoryProvider.overrideWithValue(portfolioRepository),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeStudentClubsRepository(clubsBox!, initialClubSelection),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PortfolioScreen(onBack: () => backTapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('static content', () {
    testWidgets('shows the docinfo blurb and the collapsed explainer',
        (tester) async {
      await pumpScreen(tester, 'pf_screen_static');

      expect(find.textContaining('curated set of your actual work'), findsOneWidget);
      expect(
        find.text("📁 What's the difference — Portfolio vs Activities Report?"),
        findsOneWidget,
      );
      // Collapsed by default — suitability rows not built/visible yet.
      expect(find.text('Do I need a portfolio? — start collecting from Grade 10'),
          findsNothing);
    });

    testWidgets('tapping the explainer expands it to show the suitability '
        'table', (tester) async {
      await pumpScreen(tester, 'pf_screen_expand');

      await tester.tap(
        find.text("📁 What's the difference — Portfolio vs Activities Report?"),
      );
      await tester.pumpAndSettle();

      expect(find.text('Do I need a portfolio? — start collecting from Grade 10'),
          findsOneWidget);
      expect(find.text('Student Activities Report'), findsOneWidget);
      expect(find.text('Art · DKV / Graphic Design · Music · Architecture · Film'),
          findsOneWidget);
    });

    testWidgets('no suggestion banner when clubs were never submitted',
        (tester) async {
      await pumpScreen(tester, 'pf_screen_no_suggestion');

      expect(find.textContaining('💡'), findsNothing);
    });

    testWidgets('shows a major-based suggestion once clubs are submitted '
        'with a mapped field', (tester) async {
      await pumpScreen(
        tester,
        'pf_screen_suggestion',
        initialClubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const [],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(find.textContaining('hackathon builds'), findsOneWidget);
    });
  });

  group('works list', () {
    testWidgets('shows the empty state with no works', (tester) async {
      await pumpScreen(tester, 'pf_screen_empty');

      expect(find.text('No works yet — add your first piece below.'), findsOneWidget);
      expect(find.text('0 works'), findsOneWidget);
    });

    testWidgets('adding a work shows a new card and persists it immediately',
        (tester) async {
      await pumpScreen(tester, 'pf_screen_add');

      await tester.tap(find.byKey(const Key('add_work')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('work_row_0')), findsOneWidget);
      expect(find.text('1 work'), findsOneWidget); // singular
      expect(portfolioRepository.load().works, hasLength(1));
    });

    testWidgets('removing a work deletes it and persists', (tester) async {
      await pumpScreen(
        tester,
        'pf_screen_remove',
        initialPortfolio: StudentPortfolio(
          works: [
            PortfolioWorkEntry(title: 'One'),
            PortfolioWorkEntry(title: 'Two'),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('work_remove_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('work_row_1')), findsNothing);
      expect(portfolioRepository.load().works, hasLength(1));
      expect(find.text('1 work'), findsOneWidget);
    });
  });

  group('autosave — the key behavioral difference from Activities Report', () {
    testWidgets('typing a work\'s title persists immediately, with no Save '
        'tap required', (tester) async {
      await pumpScreen(tester, 'pf_screen_autosave_title');

      await tester.tap(find.byKey(const Key('add_work')));
      await tester.pumpAndSettle();

      final titleField = find.descendant(
        of: find.byKey(const Key('work_row_0')),
        matching: find.widgetWithText(TextField, 'Title of the work'),
      );
      await tester.enterText(titleField, 'Campus wayfinding app');
      await tester.pump();

      expect(portfolioRepository.load().works.single.title, 'Campus wayfinding app');
    });

    testWidgets('typing the maker statement persists immediately',
        (tester) async {
      await pumpScreen(tester, 'pf_screen_autosave_statement');

      await tester.enterText(
        find.byKey(const Key('maker_statement')),
        'I like building small useful things.',
      );
      await tester.pump();

      expect(
        portfolioRepository.load().statement,
        'I like building small useful things.',
      );
    });
  });

  group('Save button and navigation', () {
    testWidgets('Save shows a reassurance snackbar — cosmetic, not load-'
        'bearing, since everything already autosaved', (tester) async {
      await pumpScreen(tester, 'pf_screen_save');

      await tester.tap(find.byKey(const Key('portfolio_save')));
      await tester.pump();

      expect(find.text('All changes saved ✓'), findsOneWidget);
    });

    testWidgets("'← All documents' calls onBack", (tester) async {
      await pumpScreen(tester, 'pf_screen_back');

      await tester.tap(find.byKey(const Key('portfolio_back_to_hub')));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });
  });
}