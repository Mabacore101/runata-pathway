import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/auth/application/auth_controller.dart';
import 'package:runata_pathway/features/auth/application/auth_state.dart';
import 'package:runata_pathway/features/auth/domain/student_session.dart';
import 'package:runata_pathway/features/student/data/student_activities_report_repository.dart';
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/presentation/activities_report_screen.dart';

class _FakeActivitiesReportRepository extends StudentActivitiesReportRepository {
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
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeActivitiesReportRepository reportRepository;
  bool backTapped = false;

  Future<void> pumpScreen(
    WidgetTester tester,
    String boxName, {
    String grade = '10',
    StudentActivitiesReport? initialReport,
    StudentClubSelection? initialClubSelection,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    backTapped = false;

    final reportBox = await tester.runAsync(
      () => Hive.openBox<StudentActivitiesReport>('$boxName-report'),
    );
    final clubsBox = await tester.runAsync(
      () => Hive.openBox<StudentClubSelection>('$boxName-clubs'),
    );

    reportRepository = _FakeActivitiesReportRepository(reportBox!, initialReport);

    final container = ProviderContainer(
      overrides: [
        studentActivitiesReportRepositoryProvider.overrideWithValue(reportRepository),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeStudentClubsRepository(clubsBox!, initialClubSelection),
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
        child: MaterialApp(
          home: ActivitiesReportScreen(onBack: () => backTapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('static content', () {
    testWidgets('shows the docinfo banner and all 6 section headers',
        (tester) async {
      await pumpScreen(tester, 'act_screen_static');

      expect(find.textContaining('official record of involvement'), findsOneWidget);
      expect(find.text('A. Mandatory Grade Level Program'), findsOneWidget);
      expect(find.text('B. Student Organizations'), findsOneWidget);
      expect(find.text('C. Community Services'), findsOneWidget);
      expect(find.text('D. Competitions & School Representative'), findsOneWidget);
      expect(find.text('E. Event Committees'), findsOneWidget);
      expect(find.text('F. School Teams'), findsOneWidget);
    });

    testWidgets('rid bar shows the session name/grade and falls back for '
        'major when clubs were never submitted', (tester) async {
      await pumpScreen(tester, 'act_screen_rid_fallback', grade: '11');

      expect(find.text('Test Student'), findsOneWidget);
      expect(find.text('Grade 11'), findsOneWidget);
      expect(find.text('— (clubs not submitted)'), findsOneWidget);
    });
  });

  group('Section B — auto-fill from clubs', () {
    testWidgets('shows the placeholder prompt when clubs were never submitted',
        (tester) async {
      await pumpScreen(tester, 'act_screen_secb_empty');

      expect(
        find.text('Submit your clubs to auto-fill this section'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows real rows once clubs are submitted — Member role, hardcoded '
        'placeholder dates, deduplicated', (tester) async {
      await pumpScreen(
        tester,
        'act_screen_secb_filled',
        grade: '10',
        initialClubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: ['Sports Club'],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(find.text('Coding & ICT Club'), findsOneWidget);
      expect(find.text('Sports Club'), findsOneWidget);
      expect(find.text('Member'), findsNWidgets(2));
      expect(find.text('Jul 2025 – Jun 2026'), findsNWidgets(2));
      expect(
        find.text('Submit your clubs to auto-fill this section'),
        findsNothing,
      );
    });

    testWidgets('rid bar shows the submitted anchor major once available',
        (tester) async {
      await pumpScreen(
        tester,
        'act_screen_rid_major',
        initialClubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: ['Sports Club'],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(find.text('Computer Science'), findsOneWidget);
    });
  });

  group('Sections A/D/E/F — repeatable rows', () {
    testWidgets('adding a row to Section A shows a new empty row and '
        'persists it', (tester) async {
      await pumpScreen(tester, 'act_screen_add_a');

      expect(find.byKey(const Key('activity_row_a_0')), findsNothing);

      await tester.tap(find.byKey(const Key('add_row_a')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activity_row_a_0')), findsOneWidget);
      expect(reportRepository.load().sectionA, hasLength(1));
    });

    testWidgets('deleting a row removes it and persists', (tester) async {
      await pumpScreen(
        tester,
        'act_screen_delete_d',
        initialReport: StudentActivitiesReport(
          sectionD: [
            ActivityEntry(activity: 'Science Fair'),
            ActivityEntry(activity: 'Debate'),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('activity_delete_d_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('activity_row_d_1')), findsNothing);
      expect(reportRepository.load().sectionD, hasLength(1));
    });

    testWidgets('D/E/F use the "+ Add entry" label, A uses "+ Add activity"',
        (tester) async {
      await pumpScreen(tester, 'act_screen_labels');

      expect(find.text('+ Add activity'), findsOneWidget);
      expect(find.text('+ Add entry'), findsNWidgets(3)); // D, E, F
      expect(find.text('+ Add community service'), findsOneWidget);
    });
  });

  group('Section C — community service eligibility', () {
    testWidgets('a new row starts as "not yet" eligible', (tester) async {
      await pumpScreen(tester, 'act_screen_cs_new');

      await tester.tap(find.byKey(const Key('add_row_c')));
      await tester.pumpAndSettle();

      expect(find.text('not yet'), findsOneWidget);
    });

    testWidgets('becomes "eligible" once months>=4 AND proof are both true',
        (tester) async {
      await pumpScreen(tester, 'act_screen_cs_eligible');

      await tester.tap(find.byKey(const Key('add_row_c')));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('cs_months_plus')));
      }
      await tester.pumpAndSettle();
      expect(find.text('not yet'), findsOneWidget); // proof still false

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(find.text('eligible'), findsOneWidget);
    });

    testWidgets('months cannot go below 0', (tester) async {
      await pumpScreen(tester, 'act_screen_cs_floor');

      await tester.tap(find.byKey(const Key('add_row_c')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cs_months_minus')), findsOneWidget);
      final minusButton = tester.widget<IconButton>(
        find.byKey(const Key('cs_months_minus')),
      );
      expect(minusButton.onPressed, isNull); // disabled at 0
    });
  });

  group('Save and navigation', () {
    testWidgets('Save persists typed field values and shows a confirmation',
        (tester) async {
      await pumpScreen(tester, 'act_screen_save');

      await tester.tap(find.byKey(const Key('add_row_f')));
      await tester.pumpAndSettle();

      final activityField = find.descendant(
        of: find.byKey(const Key('activity_row_f_0')),
        matching: find.widgetWithText(TextField, 'Activity'),
      );
      await tester.enterText(activityField, 'Basketball');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('activities_save')));
      await tester.pumpAndSettle();

      expect(reportRepository.load().sectionF.single.activity, 'Basketball');
      expect(find.text('Activities report saved.'), findsOneWidget);
    });

    testWidgets("'← All documents' calls onBack", (tester) async {
      await pumpScreen(tester, 'act_screen_back');

      await tester.tap(find.byKey(const Key('activities_back_to_hub')));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });
  });
}
