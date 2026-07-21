import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/core/persistence/hive_boxes.dart';
import 'package:runata_pathway/features/student/application/majors_controller.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_majors_settings.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
import 'package:runata_pathway/features/student/presentation/find_universities_screen.dart';

/// Only [UniversityTarget] writes need a fake — this screen never writes
/// to Majors or Tests data (only reads it), so those two use their real
/// Hive-backed repositories, seeded directly during setup instead of
/// through a controller's async methods. Only the repository this screen
/// actually mutates via taps (add/remove target) needs the same
/// in-memory-fake treatment explore_majors_screen_test.dart uses, for the
/// same FakeAsync-vs-real-I/O reason.
class _FakeStudentUniversityTargetsRepository
    extends StudentUniversityTargetsRepository {
  _FakeStudentUniversityTargetsRepository(super.box);

  List<UniversityTarget> _targets = [];

  @override
  List<UniversityTarget> loadAll() => _targets;

  @override
  Future<void> upsert(UniversityTarget target) async {
    _targets = [..._targets.where((t) => t.id != target.id), target];
  }

  @override
  Future<void> delete(String id) async {
    _targets = _targets.where((t) => t.id != id).toList();
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(MajorEntryAdapter());
    registerAdapterIfNeeded(StudentMajorsSettingsAdapter());
    registerAdapterIfNeeded(TestTypeAdapter());
    registerAdapterIfNeeded(TestStatusAdapter());
    registerAdapterIfNeeded(TestEntryAdapter());
    registerAdapterIfNeeded(UniversityTargetAdapter());
  });

  tearDown(() async => tearDownTestHive());

  Future<Widget> harness(
    WidgetTester tester, {
    List<MajorEntry> majors = const [],
    List<TestEntry> tests = const [],
    VoidCallback? onGoToExploreMajors,
    VoidCallback? onReviewShortlist,
  }) async {
    // Long card list (up to 4 US universities, each with an expandable
    // requirements section) — same Sliver-culling reasoning as Explore
    // Majors' test: the viewport needs to exceed the full content height
    // or later cards/buttons never get built at all.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late Box<UniversityTarget> targetsBox;
    await tester.runAsync(() async {
      final majorsBox =
          await Hive.openBox<StudentMajorsSettings>(HiveBoxes.studentMajors);
      await majorsBox.put(
        HiveKeys.studentMajorsSettings,
        StudentMajorsSettings(majors: majors),
      );

      final testsBox = await Hive.openBox<TestEntry>(HiveBoxes.studentTests);
      for (final t in tests) {
        await testsBox.put(t.id, t);
      }

      targetsBox = await Hive.openBox<UniversityTarget>('find_uni_screen_targets');
    });

    return ProviderScope(
      overrides: [
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          _FakeStudentUniversityTargetsRepository(targetsBox),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: FindUniversitiesScreen(
            onGoToExploreMajors: onGoToExploreMajors,
            onReviewShortlist: onReviewShortlist,
          ),
        ),
      ),
    );
  }

  testWidgets(
      'shows the gate message and calls the callback when no majors are Top-marked',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      await harness(tester, onGoToExploreMajors: () => tapped = true),
    );

    expect(find.textContaining('Mark your'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Go to Explore Majors →'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('shows matching universities once a Top-marked major exists',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
    ));

    expect(find.textContaining('Mark your'), findsNothing);
    // Country auto-fills to the anchor's country (United States, the only
    // value MajorEntry.country can currently hold) — all 4 US catalog
    // entries either match "all" or explicitly list Computing & Math.
    expect(find.text('Arizona State University'), findsOneWidget);
    expect(find.text('Purdue University'), findsOneWidget);
  });

  testWidgets('adding a university from the list marks it as chosen',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
    ));

    await tester.tap(find.widgetWithText(OutlinedButton, '+ Add to my list').first);
    await tester.pumpAndSettle();

    expect(find.text('✓ On your list'), findsOneWidget);
    expect(find.text('1/3 chosen'), findsOneWidget);
  });

  testWidgets('per-major cap disables further adds after 3', (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
    ));

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.widgetWithText(OutlinedButton, '+ Add to my list').first);
      await tester.pumpAndSettle();
    }

    expect(find.text('3/3 chosen'), findsOneWidget);
    final maxedButton = find.widgetWithText(OutlinedButton, 'Max 3 reached');
    expect(maxedButton, findsOneWidget);
    expect(tester.widget<OutlinedButton>(maxedButton).onPressed, isNull);
  });

  testWidgets('removing via the chosen chip un-marks the university',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
    ));

    await tester.tap(find.widgetWithText(OutlinedButton, '+ Add to my list').first);
    await tester.pumpAndSettle();
    expect(find.text('1/3 chosen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(find.text('0/3 chosen'), findsOneWidget);
    expect(find.text('✓ On your list'), findsNothing);
  });

  testWidgets('IELTS fit chip appears once the student has a matching test score',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
      tests: [TestEntry(id: 'ielts_1', type: TestType.ielts, latest: '6.5')],
    ));

    // Every US catalog entry requires exactly IELTS 6.5 → gap 0 → "Met"
    // on all of them.
    expect(find.text('MET'), findsWidgets);
  });

  testWidgets('no fit chip appears when the student has no IELTS score yet',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
    ));

    expect(find.text('MET'), findsNothing);
    expect(find.text('ADD IELTS'), findsNothing);
  });

  testWidgets('bottom Next button is disabled until every Top major has a '
      'university, then enabled and calls onReviewShortlist', (tester) async {
    var reviewed = false;
    await tester.pumpWidget(await harness(
      tester,
      majors: [
        MajorEntry(major: 'Computer Science', top: true, anchor: true),
        MajorEntry(major: 'Law', top: true),
      ],
      onReviewShortlist: () => reviewed = true,
    ));

    final nextButton =
        find.widgetWithText(ElevatedButton, 'Next: review shortlist →');
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);
    expect(
      find.text('Add at least 1 university for each of your Top majors to continue.'),
      findsOneWidget,
    );

    // Give Computer Science a university, but Law still has none.
    await tester.tap(find.widgetWithText(OutlinedButton, '+ Add to my list').first);
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNull);

    // Switch to Law and give it one too — now every Top major qualifies.
    await tester.tap(find.text('Law').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '+ Add to my list').first);
    await tester.pumpAndSettle();

    expect(tester.widget<ElevatedButton>(nextButton).onPressed, isNotNull);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();
    expect(reviewed, isTrue);
  });

  testWidgets('bottom Previous button calls onGoToExploreMajors', (tester) async {
    var wentBack = false;
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Computer Science', top: true, anchor: true)],
      onGoToExploreMajors: () => wentBack = true,
    ));

    await tester.tap(find.widgetWithText(OutlinedButton, '← Previous'));
    await tester.pumpAndSettle();

    expect(wentBack, isTrue);
  });

  testWidgets(
      'changing the anchor mid-session updates the default major/country '
      'shown here — without the student ever touching a dropdown '
      'themselves (cascade scenario 3, tested end-to-end rather than just '
      'reasoned about)', (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [
        MajorEntry(major: 'Computer Science', country: 'United States', top: true, anchor: true),
        MajorEntry(major: 'Law', country: 'Indonesia', top: true),
      ],
    ));

    // No explicit dropdown selection made — the default follows whichever
    // major is currently anchor.
    expect(find.text('Universities for Computer Science in United States'),
        findsOneWidget);

    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    // setAnchor does a REAL Hive write underneath (_persist -> saveSettings)
    // — same reasoning as harness()'s Hive.openBox call: real async I/O
    // can't complete inside testWidgets' FakeAsync zone without runAsync.
    await tester.runAsync(
      () => container.read(majorsControllerProvider.notifier).setAnchor(1),
    );
    await tester.pumpAndSettle();

    // The default now follows the NEW anchor (Law / Indonesia) — the
    // student did nothing on this screen at all.
    expect(find.text('Universities for Law in Indonesia'), findsOneWidget);
  });
}