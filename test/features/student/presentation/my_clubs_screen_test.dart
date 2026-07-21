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
import 'package:runata_pathway/features/student/application/majors_controller.dart';
import 'package:runata_pathway/features/student/data/student_majors_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_majors_settings.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
import 'package:runata_pathway/features/student/presentation/my_clubs_screen.dart';

/// Same fake-repository rationale as explore_majors_screen_test.dart's own
/// doc comment: real Hive I/O can't run inside testWidgets' pumped frames,
/// and requiredClubProvider's own persistence-adjacent behavior is already
/// covered against a REAL box in clubs_controller_test.dart. This fake
/// additionally accepts a seed [StudentMajorsSettings] so tests can start
/// from "anchor already set" without needing to simulate Explore Majors
/// button taps just to get there.
class _FakeStudentMajorsRepository extends StudentMajorsRepository {
  _FakeStudentMajorsRepository(super.box, [StudentMajorsSettings? initial])
      : _settings = initial ?? StudentMajorsSettings();

  StudentMajorsSettings _settings;

  @override
  StudentMajorsSettings loadSettings() => _settings;

  @override
  Future<void> saveSettings(StudentMajorsSettings settings) async {
    _settings = settings;
  }
}

/// Trivial destination screens standing in for the real
/// TargetUniversitiesScreen/StudentHomeScreen — this test only needs to
/// confirm MyClubsScreen navigates to the RIGHT route when its buttons are
/// tapped, not that those destination screens themselves render correctly
/// (each has its own screen test elsewhere). Deliberately built on a
/// minimal standalone GoRouter using the real `AppRoutes` path constants,
/// rather than the full `goRouterProvider` graph — pulling in the whole
/// app's routes (and every provider Target Universities' 3 tabs depend on)
/// would couple this screen's test to unrelated screens' wiring.
class _StubDestination extends StatelessWidget {
  const _StubDestination(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(MajorEntryAdapter());
    registerAdapterIfNeeded(StudentMajorsSettingsAdapter());
    // Only the reactivity group's removeMajor() call actually needs this
    // adapter (see that test's box-opening comment for why) — registered
    // here rather than inline there simply because every other adapter
    // used anywhere in this file is already registered in one shared
    // place, and a 3rd registerAdapterIfNeeded call costs nothing for the
    // tests that don't need it.
    registerAdapterIfNeeded(UniversityTargetAdapter());
  });

  tearDown(() async => tearDownTestHive());

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.studentClubs,
      routes: [
        GoRoute(
          path: AppRoutes.studentClubs,
          builder: (context, state) => const MyClubsScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentTargetUniversities,
          builder: (context, state) =>
              const _StubDestination('Target Universities stub'),
        ),
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (context, state) => const _StubDestination('Home stub'),
        ),
      ],
    );
  }

  /// Builds the widget tree for the common case: a signed-in session with
  /// [grade], majors state seeded via [initialSettings] (defaults to
  /// empty — no anchor), wired to a fresh throwaway Hive box (needed only
  /// to satisfy [StudentMajorsRepository]'s constructor type, per
  /// [_FakeStudentMajorsRepository]'s doc comment).
  Future<Widget> harness(
    WidgetTester tester,
    String boxName, {
    required String grade,
    StudentMajorsSettings? initialSettings,
  }) async {
    final box = await tester.runAsync(
      () => Hive.openBox<StudentMajorsSettings>(boxName),
    );

    final container = ProviderContainer(
      overrides: [
        studentMajorsRepositoryProvider.overrideWithValue(
          _FakeStudentMajorsRepository(box!, initialSettings),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Same pattern app_router_redirect_test.dart already relies on: the
    // Notifier's `state` setter is public, so a signed-in session can be
    // injected directly without going through a real sign-in flow.
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

  group('no anchor set', () {
    testWidgets('shows the anchor-first prompt, not a required club',
        (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'my_clubs_no_anchor', grade: '10'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose your anchor major first'), findsOneWidget);
      expect(find.text('Your required club'), findsNothing);
    });

    testWidgets("tapping 'Go to Target universities →' navigates there",
        (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'my_clubs_nav_unis', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Go to Target universities →'));
      await tester.pumpAndSettle();

      expect(find.text('Target Universities stub'), findsOneWidget);
    });

    testWidgets("tapping '← Back to home' navigates there", (tester) async {
      await tester.pumpWidget(
        await harness(tester, 'my_clubs_nav_home', grade: '10'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('← Back to home'));
      await tester.pumpAndSettle();

      expect(find.text('Home stub'), findsOneWidget);
    });
  });

  group('anchor set — required club display', () {
    testWidgets(
        'shows the club mapped from the anchor major, locked, for a Grade '
        '10 session', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_grade10',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your required club'), findsOneWidget);
      expect(find.text('Coding & ICT Club'), findsOneWidget);
      expect(find.textContaining('Computer Science'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.text('Choose your anchor major first'), findsNothing);
      // Coding & ICT Club's teacher (Mr Eric) is available every day, so
      // the days shown reduce to whichever session days Grade 10 gets.
      expect(find.textContaining('Mon, Tue'), findsOneWidget);
    });

    testWidgets(
        'shows a DIFFERENT days label for the SAME club on a Grade 11/12 '
        'session — the whole point of today\'s grade-dependent fix',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_grade12',
          grade: '12',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coding & ICT Club'), findsOneWidget);
      expect(find.textContaining('Tue, Wed, Fri'), findsOneWidget);
      expect(find.textContaining('Mon, Tue'), findsNothing);
    });
  });

  group('reactivity — no stale cache', () {
    testWidgets(
        'clearing the anchor after the screen is already showing falls '
        'back to the prompt live, same cascade Day 3 already proved for '
        'Explore Majors, exercised here from My Clubs\' side', (tester) async {
      final box = await tester.runAsync(
        () => Hive.openBox<StudentMajorsSettings>('my_clubs_reactivity'),
      );
      // removeMajor() below cascades into UniversityTargetsController,
      // whose build() unconditionally reads
      // studentUniversityTargetsRepositoryProvider — this test has no
      // university targets to clean up, but the box still has to genuinely
      // exist or that read throws before removeMajor can even finish. Same
      // requirement clubs_controller_test.dart's own removeMajor case
      // needed, just via tester.runAsync here since this is a widget test.
      final uniTargetsBox = await tester.runAsync(
        () => Hive.openBox<UniversityTarget>('my_clubs_reactivity_uni_targets'),
      );

      final container = ProviderContainer(
        overrides: [
          studentMajorsRepositoryProvider.overrideWithValue(
            _FakeStudentMajorsRepository(
              box!,
              StudentMajorsSettings(majors: [
                MajorEntry(major: 'Computer Science', top: true, anchor: true),
              ]),
            ),
          ),
          studentUniversityTargetsRepositoryProvider.overrideWithValue(
            StudentUniversityTargetsRepository(uniTargetsBox!),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider.notifier).state = AuthState(
        session: const StudentSession(
          studentId: '2627001',
          name: 'Test Student',
          grade: '10',
        ),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: buildTestRouter()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Coding & ICT Club'), findsOneWidget);

      await container.read(majorsControllerProvider.notifier).removeMajor(0);
      await tester.pumpAndSettle();

      expect(find.text('Choose your anchor major first'), findsOneWidget);
      expect(find.text('Coding & ICT Club'), findsNothing);
    });
  });
}