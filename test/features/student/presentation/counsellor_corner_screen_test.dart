import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/core/routing/app_router.dart';
import 'package:runata_pathway/features/student/data/student_counsellor_corner_repository.dart';
import 'package:runata_pathway/features/student/domain/counsellor_corner.dart';
import 'package:runata_pathway/features/student/presentation/counsellor_corner_screen.dart';

class _FakeRepository extends StudentCounsellorCornerRepository {
  _FakeRepository(super.box, [CounsellorCorner? initial])
      : _record = initial ?? CounsellorCorner();

  CounsellorCorner _record;
  final List<CounsellorCorner> saved = [];

  @override
  CounsellorCorner load() => _record;

  @override
  Future<void> save(CounsellorCorner record) async {
    _record = record;
    saved.add(record);
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
    registerAdapterIfNeeded(CounsellorCornerAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeRepository repository;

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.studentCounsellorCorner,
      routes: [
        GoRoute(
          path: AppRoutes.studentCounsellorCorner,
          builder: (context, state) => const CounsellorCornerScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (context, state) => const _StubDestination('Home stub'),
        ),
      ],
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    String boxName, [
    CounsellorCorner? initial,
  ]) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final box = await tester.runAsync(() => Hive.openBox<CounsellorCorner>(boxName));
    repository = _FakeRepository(box!, initial);

    final container = ProviderContainer(
      overrides: [
        studentCounsellorCornerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: buildTestRouter()),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('static content', () {
    testWidgets('shows the header, autosave description, and both section '
        'headers', (tester) async {
      await pumpScreen(tester, 'counsel_screen_static');

      expect(find.text('Counsellor\'s Corner'), findsWidgets);
      expect(find.textContaining('saves automatically'), findsOneWidget);
      expect(find.text('STUDENT\'S FAMILY BACKGROUND'), findsOneWidget);
      expect(find.text('STUDENT\'S EDUCATION BACKGROUND'), findsOneWidget);
    });

    testWidgets('shows Save and back buttons', (tester) async {
      await pumpScreen(tester, 'counsel_screen_nav');

      expect(find.byKey(const Key('counsellor_save')), findsOneWidget);
      expect(find.byKey(const Key('counsellor_back_to_home')), findsOneWidget);
    });
  });

  group('autosave — every field persists immediately, no Save needed', () {
    testWidgets('typing in a plain textarea persists on that keystroke',
        (tester) async {
      await pumpScreen(tester, 'counsel_screen_autosave_text');

      await tester.enterText(
        find.byKey(const Key('counsellor_field_qualityTime')),
        'Dinner together every night',
      );
      await tester.pump();

      expect(repository.load().qualityTime, 'Dinner together every night');
    });

    testWidgets('editing one field never touches another', (tester) async {
      await pumpScreen(
        tester,
        'counsel_screen_field_isolation',
        CounsellorCorner(rules: 'Existing rule'),
      );

      await tester.enterText(
        find.byKey(const Key('counsellor_field_enjoyMost')),
        'Basketball',
      );
      await tester.pump();

      expect(repository.load().enjoyMost, 'Basketball');
      expect(repository.load().rules, 'Existing rule');
    });
  });

  group('"who" dropdowns — Father/Mother/Both/None/Other', () {
    testWidgets('the "Other" free-text field is hidden until "Other" is '
        'selected', (tester) async {
      await pumpScreen(tester, 'counsel_screen_who_hidden');

      expect(find.byKey(const Key('counsellor_field_addressedOther')), findsNothing);
    });

    testWidgets('selecting "Other" reveals the free-text field, and typing '
        'in it persists', (tester) async {
      await pumpScreen(tester, 'counsel_screen_who_reveal');

      await tester.tap(find.byKey(const Key('counsellor_dropdown_addressedOther')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('counsellor_field_addressedOther')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('counsellor_field_addressedOther')),
        'Grandmother',
      );
      await tester.pump();

      expect(repository.load().addressedBy, 'Other');
      expect(repository.load().addressedOther, 'Grandmother');
    });

    testWidgets('switching away from "Other" hides the field but does NOT '
        'clear its stored value — switching back shows it again',
        (tester) async {
      await pumpScreen(
        tester,
        'counsel_screen_who_preserve',
        CounsellorCorner(addressedBy: 'Other', addressedOther: 'Grandmother'),
      );

      expect(find.byKey(const Key('counsellor_field_addressedOther')), findsOneWidget);

      await tester.tap(find.byKey(const Key('counsellor_dropdown_addressedOther')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Father').last);
      await tester.pumpAndSettle();

      // Hidden now, but the underlying value must survive untouched.
      expect(find.byKey(const Key('counsellor_field_addressedOther')), findsNothing);
      expect(repository.load().addressedOther, 'Grandmother');

      await tester.tap(find.byKey(const Key('counsellor_dropdown_addressedOther')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('counsellor_field_addressedOther')), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Grandmother'), findsOneWidget);
    });

    testWidgets('the 3 "who" dropdowns are independent of each other',
        (tester) async {
      await pumpScreen(tester, 'counsel_screen_who_independent');

      await tester.tap(find.byKey(const Key('counsellor_dropdown_talksOther')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Both').last);
      await tester.pumpAndSettle();

      expect(repository.load().talksWith, 'Both');
      expect(repository.load().addressedBy, ''); // untouched
      expect(repository.load().eduAdult, ''); // untouched
    });
  });

  group('therapy Yes/No dropdown', () {
    testWidgets('has no "Other" field of its own, regardless of selection',
        (tester) async {
      await pumpScreen(tester, 'counsel_screen_therapy_no_other');

      await tester.tap(find.byKey(const Key('counsellor_dropdown_hadTherapy')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes').last);
      await tester.pumpAndSettle();

      expect(repository.load().hadTherapy, 'Yes');
      expect(find.textContaining('Please specify'), findsNothing);
    });
  });

  group('Save and navigation', () {
    testWidgets('Save shows a confirmation', (tester) async {
      await pumpScreen(tester, 'counsel_screen_save');

      await tester.tap(find.byKey(const Key('counsellor_save')));
      await tester.pumpAndSettle();

      expect(find.text('Counsellor\'s Corner saved.'), findsOneWidget);
    });

    testWidgets("'← Back to home' navigates to the home route", (tester) async {
      await pumpScreen(tester, 'counsel_screen_back');

      await tester.tap(find.byKey(const Key('counsellor_back_to_home')));
      await tester.pumpAndSettle();

      expect(find.text('Home stub'), findsOneWidget);
    });
  });
}