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
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/data/student_majors_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
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

/// Same rationale as [_FakeStudentMajorsRepository] — Day 4 item 4's
/// ClubSubmissionController.submit() awaits a real repository write, which
/// can't resolve correctly inside testWidgets' pumped frames either.
/// Accepts a seed [StudentClubSelection] so re-entry tests can start from
/// "already submitted" without needing to drive a full ranking+submit
/// flow first just to get there.
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
    // Needed by EVERY test now, not just item 4's new ones —
    // ClubsViewController.build() reads clubSubmissionProvider to decide
    // its starting view, whose own build() needs this adapter registered
    // and a real box open, regardless of whether a given test cares about
    // submissions at all. Same class of gap as the university-targets
    // adapter above.
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
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
  /// [_FakeStudentMajorsRepository]'s doc comment). [initialSubmission]
  /// (Day 4 item 4) seeds an already-submitted state for re-entry tests —
  /// defaults to `null` ("never submitted"), which is what every item
  /// 1–3 test implicitly relied on before this parameter existed.
  Future<Widget> harness(
    WidgetTester tester,
    String boxName, {
    required String grade,
    StudentMajorsSettings? initialSettings,
    StudentClubSelection? initialSubmission,
  }) async {
    // Item 2 (Rank Other Clubs) pushed this screen's content well past the
    // default 800x600 test surface — required-club card + description +
    // counter + ranked tiles + backup divider + the full addable pool
    // (~13 clubs once the required one and any ranked ones are excluded)
    // + the Generate button. Same fix explore_majors_screen_test.dart
    // already needed for its 17-card catalog grid, for the same reason:
    // tester.tap() silently misses anything positioned beyond the
    // rendered surface rather than failing loudly, so an undersized
    // viewport shows up downstream as "state never changed" instead of a
    // clear layout error.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final box = await tester.runAsync(
      () => Hive.openBox<StudentMajorsSettings>(boxName),
    );
    final clubsBox = await tester.runAsync(
      () => Hive.openBox<StudentClubSelection>('$boxName-clubs'),
    );

    final container = ProviderContainer(
      overrides: [
        studentMajorsRepositoryProvider.overrideWithValue(
          _FakeStudentMajorsRepository(box!, initialSettings),
        ),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeStudentClubsRepository(clubsBox!, initialSubmission),
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

  group('Rank Other Clubs (item 2) — grade-dependent pick count', () {
    testWidgets('the required club itself is never offered in the pool',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_pool_excludes_required',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+ Coding & ICT Club'), findsNothing);
    });

    testWidgets(
        'Grade 10: adding 2 clubs fills the ranking and enables Generate '
        'my week', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_grade10_full',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ranked 0/2'), findsOneWidget);
      final generateButton =
          find.widgetWithText(ElevatedButton, 'Generate my week →');
      expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNull);

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      expect(find.text('Ranked 1/2'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNull);

      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();

      expect(find.text('Ranked 2/2'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(generateButton).onPressed, isNotNull);
    });

    testWidgets(
        'Grade 11/12: the same 2 clubs that fill Grade 10 are NOT enough '
        'here — needs a 3rd (the whole point of the grade-dependent fix)',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_grade12_full',
          grade: '12',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ranked 0/3'), findsOneWidget);

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();

      expect(find.text('Ranked 2/3'), findsOneWidget);
      final generateButton =
          find.widgetWithText(ElevatedButton, 'Generate my week →');
      expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNull);

      await tester.tap(find.text('+ Debate & MUN Club'));
      await tester.pumpAndSettle();

      expect(find.text('Ranked 3/3'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(generateButton).onPressed, isNotNull);
    });

    testWidgets(
        'Grade 10 labels the 1st ranked club CHOICE 2 and the 2nd BACKUP '
        '(only 1 scheduled slot beyond the required club)', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_grade10_labels',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();

      expect(find.text('CHOICE 2'), findsOneWidget);
      expect(find.text('BACKUP'), findsOneWidget);
      expect(find.text('BACKUP — USED ONLY IF A CHOICE ABOVE IS FULL'),
          findsOneWidget);
    });

    testWidgets(
        'Grade 11/12 labels the first TWO ranked clubs CHOICE 2/CHOICE 3 — '
        'only the 3rd is BACKUP', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_grade12_labels',
          grade: '12',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Debate & MUN Club'));
      await tester.pumpAndSettle();

      expect(find.text('CHOICE 2'), findsOneWidget);
      expect(find.text('CHOICE 3'), findsOneWidget);
      expect(find.text('BACKUP'), findsOneWidget);
    });

    testWidgets(
        'removing a ranked club decrements the count and disables the gate '
        'again', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_remove',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      expect(find.text('Ranked 2/2'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.text('Ranked 1/2'), findsOneWidget);
      final generateButton =
          find.widgetWithText(ElevatedButton, 'Generate my week →');
      expect(tester.widget<ElevatedButton>(generateButton).onPressed, isNull);
    });

    testWidgets(
        'moving the BACKUP club up (via the ▲ button) promotes it into a '
        'scheduled CHOICE slot, and bumps the previous occupant down',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_rank_reorder_promotes_backup',
          grade: '12',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Debate & MUN Club'));
      await tester.pumpAndSettle();

      // Order so far: Sports Club (CHOICE 2), Music Club (CHOICE 3),
      // Debate & MUN Club (BACKUP) — exactly one BACKUP tile exists.
      expect(find.text('BACKUP'), findsOneWidget);

      final debateTile = find.ancestor(
        of: find.text('Debate & MUN Club'),
        matching: find.byType(Container),
      ).first;

      await tester.tap(find.descendant(
        of: debateTile,
        matching: find.byIcon(Icons.keyboard_arrow_up),
      ));
      await tester.pumpAndSettle();

      // Debate & MUN Club moved from index 2 to index 1 — now scheduled.
      // `debateTile` and `musicTile` are still valid Finders here (they
      // re-evaluate the tree lazily), even though each club's position
      // in the list has changed since they were defined.
      final musicTile = find.ancestor(
        of: find.text('Music Club'),
        matching: find.byType(Container),
      ).first;
      expect(
        find.descendant(of: musicTile, matching: find.text('BACKUP')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: debateTile, matching: find.text('CHOICE 3')),
        findsOneWidget,
      );
    });
  });

  group('Preview/Confirm (item 3) — real clash-detection, end to end', () {
    testWidgets(
        'Grade 10: Generate my week shows a perfect week for an '
        'always-available combo', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_preview_grade10_perfect',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      expect(find.text('Rank your other clubs'), findsNothing);
      expect(find.text('Your week'), findsOneWidget);
      expect(find.text('Perfect — you got all your picks.'), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Coding & ICT Club'), findsOneWidget);
      expect(find.text('Sports Club'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets(
        'Grade 11/12: Generate my week shows a perfect week across all 3 '
        'days', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_preview_grade12_perfect',
          grade: '12',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Debate & MUN Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      expect(find.text('Perfect — you got all your picks.'), findsOneWidget);
      expect(find.text('Tuesday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      // Debate & MUN Club was ranked as backup but never needed — the
      // real point of this test alongside the Grade 10 one above: prove
      // the SAME "3rd pick unused" behavior holds for the larger band.
      expect(find.text('Debate & MUN Club'), findsNothing);
    });

    testWidgets(
        '← Edit ranking returns to the ranking view WITHOUT clearing what '
        'was already ranked', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_preview_edit_ranking',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();
      expect(find.text('Your week'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, '← Edit ranking'));
      await tester.pumpAndSettle();

      expect(find.text('Rank your other clubs'), findsOneWidget);
      expect(find.text('Your week'), findsNothing);
      expect(find.text('Ranked 2/2'), findsOneWidget);
    });

    testWidgets(
        'a real own-schedule clash between two ranked clubs surfaces the '
        'adjustment banner and reassigns to backup', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_preview_clash',
          grade: '12',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Architecture', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      // Architecture's required club (Architecture & Built Env Club) and
      // Art & Design Studio share the same 'art' track teacher, both only
      // available Friday for Grade 11/12 — a genuine same-day collision
      // using real school data, same scenario proven at the algorithm
      // level in club_schedule_preview_test.dart.
      await tester.tap(find.text('+ Art & Design Studio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      expect(find.text('We adjusted one of your picks:'), findsOneWidget);
      // Art & Design Studio was never successfully scheduled at all (it
      // lost the Friday collision), so it appears exactly once — in the
      // banner's substitution message — not as a day tile anywhere.
      expect(find.textContaining('Art & Design Studio'), findsOneWidget);
      expect(find.textContaining('Music Club instead.'), findsOneWidget);
      expect(find.text('Backup'), findsOneWidget);
    });

    testWidgets('Confirm & submit now actually persists and shows the '
        'Submitted! success card, not the old placeholder SnackBar',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_preview_confirm_real',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm & submit ✓'));
      await tester.pumpAndSettle();

      expect(find.text('Submit is coming in the next item'), findsNothing);
      expect(find.text('Submitted!'), findsOneWidget);
      expect(find.text('Thanks! Your club selection has been saved.'),
          findsOneWidget);
    });
  });

  group('Submit + re-entry (item 4) — full round trip', () {
    testWidgets(
        'entering My Clubs fresh with an EXISTING submission lands '
        'directly on Your Current Schedule, not the ranking flow',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_reentry_existing',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
          initialSubmission: StudentClubSelection(
            anchorMajor: 'Computer Science',
            rankedOthers: const ['Sports Club', 'Music Club'],
            submittedAt: DateTime(2026, 1, 1, 9, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your current schedule'), findsOneWidget);
      expect(find.text('Rank your other clubs'), findsNothing);
      expect(find.text('Choose your anchor major first'), findsNothing);
      expect(find.textContaining('Submitted 1 Jan 2026'), findsOneWidget);
      expect(find.text('Coding & ICT Club'), findsOneWidget);
      expect(find.text('Sports Club'), findsOneWidget);
    });

    testWidgets(
        'FULL ROUND TRIP: submit → Submitted! card → back to home → '
        're-enter shows Your Current Schedule (not Submitted! again) → '
        'Make Changes pre-fills the exact prior picks, in order — this is '
        'the state-transition class of bug Day 3 found that unit tests '
        'alone missed, so it gets a dedicated end-to-end test here rather '
        'than trusting the individual pieces in isolation', (tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final majorsBox = await tester.runAsync(
        () => Hive.openBox<StudentMajorsSettings>('roundtrip_majors'),
      );
      final uniBox = await tester.runAsync(
        () => Hive.openBox<UniversityTarget>('roundtrip_uni'),
      );
      final clubsBox = await tester.runAsync(
        () => Hive.openBox<StudentClubSelection>('roundtrip_clubs'),
      );

      final container = ProviderContainer(
        overrides: [
          studentMajorsRepositoryProvider.overrideWithValue(
            _FakeStudentMajorsRepository(
              majorsBox!,
              StudentMajorsSettings(majors: [
                MajorEntry(major: 'Computer Science', top: true, anchor: true),
              ]),
            ),
          ),
          studentUniversityTargetsRepositoryProvider.overrideWithValue(
            StudentUniversityTargetsRepository(uniBox!),
          ),
          studentClubsRepositoryProvider.overrideWithValue(
            _FakeStudentClubsRepository(clubsBox!),
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

      // Built directly (not via harness()) so the SAME router instance
      // can be navigated again later, to actually simulate "leaving and
      // re-entering" rather than just checking the initial render.
      final router = buildTestRouter();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Rank 2 clubs (Grade 10 needs 2) and generate the preview.
      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      // Submit.
      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Confirm & submit ✓'));
      await tester.pumpAndSettle();
      expect(find.text('Submitted!'), findsOneWidget);

      // Leave via the one-time success card's own "Back to home".
      await tester.tap(find.widgetWithText(OutlinedButton, 'Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('Home stub'), findsOneWidget);

      // Re-enter My Clubs — same route, same container/state, simulating
      // a real navigate-away-and-back within one app session.
      router.go(AppRoutes.studentClubs);
      await tester.pumpAndSettle();

      // The actual point of this test: NOT the one-time success card
      // again — the read-only current-schedule view.
      expect(find.text('Submitted!'), findsNothing);
      expect(find.text('Your current schedule'), findsOneWidget);
      expect(find.text('Coding & ICT Club'), findsOneWidget);
      expect(find.text('Sports Club'), findsOneWidget);

      // Make changes.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Make changes'));
      await tester.pumpAndSettle();

      // Back on the ranking screen, with BOTH prior picks intact, in the
      // SAME order they were originally ranked — Sports Club still the
      // scheduled choice, Music Club still the backup, not reset to
      // empty and not shuffled.
      expect(find.text('Rank your other clubs'), findsOneWidget);
      expect(find.text('Ranked 2/2'), findsOneWidget);
      final sportsTile = find.ancestor(
        of: find.text('Sports Club'),
        matching: find.byType(Container),
      ).first;
      expect(
        find.descendant(of: sportsTile, matching: find.text('CHOICE 2')),
        findsOneWidget,
      );
      final musicTile = find.ancestor(
        of: find.text('Music Club'),
        matching: find.byType(Container),
      ).first;
      expect(
        find.descendant(of: musicTile, matching: find.text('BACKUP')),
        findsOneWidget,
      );
    });
  });

  group('Cascade (item 5) — anchor change reconciles an in-progress ranking',
      () {
    testWidgets(
        'ranking a club that later BECOMES the new required club gets it '
        'silently stripped, live, without navigating away from My Clubs',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final majorsBox = await tester.runAsync(
        () => Hive.openBox<StudentMajorsSettings>('cascade_widget_strip'),
      );
      final uniBox = await tester.runAsync(
        () => Hive.openBox<UniversityTarget>('cascade_widget_strip_uni'),
      );
      final clubsBox = await tester.runAsync(
        () => Hive.openBox<StudentClubSelection>('cascade_widget_strip_clubs'),
      );

      final container = ProviderContainer(overrides: [
        studentMajorsRepositoryProvider.overrideWithValue(
          _FakeStudentMajorsRepository(
            majorsBox!,
            StudentMajorsSettings(majors: [
              MajorEntry(major: 'Computer Science', top: true, anchor: true),
            ]),
          ),
        ),
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          StudentUniversityTargetsRepository(uniBox!),
        ),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeStudentClubsRepository(clubsBox!),
        ),
      ]);
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

      await tester.tap(find.text('+ Science Research Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      expect(find.text('Ranked 2/2'), findsOneWidget);

      // Simulate changing the anchor "elsewhere" (Target Universities) —
      // directly through the container, not through this screen's own
      // UI, exactly like a real navigate-away-and-change would look from
      // My Clubs' perspective (it's a different screen entirely).
      final majorsNotifier = container.read(majorsControllerProvider.notifier);
      await majorsNotifier.addMajor('Biology');
      await majorsNotifier.toggleTop(1);
      await majorsNotifier.setAnchor(1);
      await tester.pumpAndSettle();

      // Science Research Club is now the anchor's required club — it
      // should have been silently stripped from the ranking, live, with
      // no navigation away from and back to My Clubs at all.
      expect(find.text('Ranked 1/2'), findsOneWidget);
      expect(find.text('Sports Club'), findsOneWidget);
      expect(find.text('Your required club'), findsOneWidget);
    });

    testWidgets(
        'if the cascade shrinks an already-GENERATED preview below the '
        'needed count, Confirm & submit disables until Edit ranking '
        'refills it', (tester) async {
      tester.view.physicalSize = const Size(1080, 4200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final majorsBox = await tester.runAsync(
        () => Hive.openBox<StudentMajorsSettings>('cascade_widget_gate'),
      );
      final uniBox = await tester.runAsync(
        () => Hive.openBox<UniversityTarget>('cascade_widget_gate_uni'),
      );
      final clubsBox = await tester.runAsync(
        () => Hive.openBox<StudentClubSelection>('cascade_widget_gate_clubs'),
      );

      final container = ProviderContainer(overrides: [
        studentMajorsRepositoryProvider.overrideWithValue(
          _FakeStudentMajorsRepository(
            majorsBox!,
            StudentMajorsSettings(majors: [
              MajorEntry(major: 'Computer Science', top: true, anchor: true),
            ]),
          ),
        ),
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          StudentUniversityTargetsRepository(uniBox!),
        ),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeStudentClubsRepository(clubsBox!),
        ),
      ]);
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

      await tester.tap(find.text('+ Science Research Club'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Sports Club'));
      await tester.pumpAndSettle();
      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      final confirmButton =
          find.widgetWithText(ElevatedButton, 'Confirm & submit ✓');
      expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNotNull);

      final majorsNotifier = container.read(majorsControllerProvider.notifier);
      await majorsNotifier.addMajor('Biology');
      await majorsNotifier.toggleTop(1);
      await majorsNotifier.setAnchor(1);
      await tester.pumpAndSettle();

      // Ranking shrank from under this exact screen — Confirm & submit
      // must not allow persisting an incomplete ranking just because it
      // started full.
      expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
      expect(
        find.textContaining('go back to Edit ranking'),
        findsOneWidget,
      );

      // Go fix it — back to ranking, refill, regenerate.
      await tester
          .tap(find.widgetWithText(OutlinedButton, '← Edit ranking'));
      await tester.pumpAndSettle();
      expect(find.text('Ranked 1/2'), findsOneWidget);
      await tester.tap(find.text('+ Music Club'));
      await tester.pumpAndSettle();
      expect(find.text('Ranked 2/2'), findsOneWidget);
      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Generate my week →'));
      await tester.pumpAndSettle();

      final confirmButtonAgain =
          find.widgetWithText(ElevatedButton, 'Confirm & submit ✓');
      expect(
        tester.widget<ElevatedButton>(confirmButtonAgain).onPressed,
        isNotNull,
      );
    });
  });

  group('Staleness banner (item 5) — Your Current Schedule', () {
    testWidgets(
        'shows an informational banner when the anchor has changed to a '
        'DIFFERENT club since submitting — no embedded Make Changes CTA, '
        'just states the fact', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_stale_banner_shows',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Biology', top: true, anchor: true),
          ]),
          initialSubmission: StudentClubSelection(
            anchorMajor: 'Computer Science', // frozen: Coding & ICT Club
            rankedOthers: const ['Sports Club', 'Music Club'],
            submittedAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Live anchor (Biology -> Science Research Club) differs from the
      // frozen submission's (Computer Science -> Coding & ICT Club).
      expect(
        find.textContaining('Your anchor major has changed since you '
            'submitted'),
        findsOneWidget,
      );
      // No directive/CTA wording embedded in the banner itself.
      expect(find.textContaining('Tap Make changes'), findsNothing);
    });

    testWidgets(
        'does NOT show a banner when the anchor changed to a DIFFERENT '
        'major that maps to the SAME club — nothing is actually stale',
        (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_stale_banner_hidden',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            // Economics also maps to Business & Finance Club.
            MajorEntry(major: 'Economics', top: true, anchor: true),
          ]),
          initialSubmission: StudentClubSelection(
            anchorMajor: 'Accounting', // also -> Business & Finance Club
            rankedOthers: const ['Sports Club', 'Music Club'],
            submittedAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Your anchor major has changed since you '
            'submitted'),
        findsNothing,
      );
    });

    testWidgets('does NOT show a banner when the anchor has not changed at '
        'all', (tester) async {
      await tester.pumpWidget(
        await harness(
          tester,
          'my_clubs_stale_banner_unchanged',
          grade: '10',
          initialSettings: StudentMajorsSettings(majors: [
            MajorEntry(major: 'Computer Science', top: true, anchor: true),
          ]),
          initialSubmission: StudentClubSelection(
            anchorMajor: 'Computer Science',
            rankedOthers: const ['Sports Club', 'Music Club'],
            submittedAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Your anchor major has changed since you '
            'submitted'),
        findsNothing,
      );
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
      // Same requirement as everywhere else in this file now —
      // ClubsViewController.build() reads clubSubmissionProvider
      // regardless of what this specific test is exercising.
      final clubsBox = await tester.runAsync(
        () => Hive.openBox<StudentClubSelection>('my_clubs_reactivity_clubs'),
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
          studentClubsRepositoryProvider.overrideWithValue(
            _FakeStudentClubsRepository(clubsBox!),
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