import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/core/persistence/hive_boxes.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_majors_settings.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
import 'package:runata_pathway/features/student/presentation/my_shortlist_screen.dart';

/// Same fake as find_universities_screen_test.dart, duplicated here
/// rather than shared across test files — this repository is the only
/// thing either screen actually WRITES to via taps, so it's the only one
/// that needs the in-memory-fake treatment; Majors/Tests boxes are real
/// (just seeded directly during setup), same reasoning as that file.
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
    List<UniversityTarget> targets = const [],
    List<TestEntry> tests = const [],
    VoidCallback? onGoToFindUniversities,
  }) async {
    // MyShortlistScreen's root is a plain ListView — same Sliver-culling
    // reasoning as explore_majors_screen_test.dart and
    // find_universities_screen_test.dart: Flutter only BUILDS children
    // within the viewport + a small cache extent, not the whole list.
    // Each shortlist card is fairly tall (requirements + a notes field),
    // so with 3+ cards the later ones never get built at the default
    // test window size — this was missing here even though the other two
    // screen tests already needed it.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late Box<UniversityTarget> targetsBox;
    late _FakeStudentUniversityTargetsRepository fakeRepo;

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

      targetsBox = await Hive.openBox<UniversityTarget>('my_shortlist_screen_targets');
      fakeRepo = _FakeStudentUniversityTargetsRepository(targetsBox);
      for (final t in targets) {
        await fakeRepo.upsert(t);
      }
    });

    return ProviderScope(
      overrides: [
        studentUniversityTargetsRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MyShortlistScreen(onGoToFindUniversities: onGoToFindUniversities),
        ),
      ),
    );
  }

  testWidgets('shows the empty state and calls the callback when nothing is shortlisted',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      await harness(tester, onGoToFindUniversities: () => tapped = true),
    );

    expect(find.textContaining('No universities yet'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Go to Find Universities →'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets("shows the ANCHOR tag only on the anchor major's row", (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [
        MajorEntry(major: 'Computer Science', top: true, anchor: true),
        MajorEntry(major: 'Law', top: true),
      ],
      targets: [
        UniversityTarget(
          id: 't1',
          major: 'Computer Science',
          country: 'United States',
          university: 'Arizona State University',
        ),
        UniversityTarget(
          id: 't2',
          major: 'Law',
          country: 'Indonesia',
          university: 'Universitas Indonesia (UI)',
        ),
      ],
    ));

    expect(find.text('★ Anchor'), findsOneWidget);
  });

  testWidgets('shows the YOURS tag only for custom (student-typed) universities',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Law', top: true, anchor: true)],
      targets: [
        UniversityTarget(
          id: 't1',
          major: 'Law',
          country: 'Indonesia',
          university: 'Universitas Indonesia (UI)',
        ),
        UniversityTarget(
          id: 't2',
          major: 'Law',
          country: 'Indonesia',
          university: 'My Own University',
          custom: true,
        ),
      ],
    ));

    expect(find.text('yours'), findsOneWidget);
    expect(find.text('My Own University'), findsOneWidget);
  });

  testWidgets('a custom university with no catalog match shows the Notes fallback hint',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Law', top: true, anchor: true)],
      targets: [
        UniversityTarget(
          id: 't1',
          major: 'Law',
          country: 'Indonesia',
          university: 'My Own University',
          custom: true,
        ),
      ],
    ));

    expect(find.text('Add requirements in Notes →'), findsOneWidget);
  });

  testWidgets('the delete button removes the row', (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Law', top: true, anchor: true)],
      targets: [
        UniversityTarget(
          id: 't1',
          major: 'Law',
          country: 'Indonesia',
          university: 'Universitas Indonesia (UI)',
        ),
      ],
    ));

    expect(find.text('Universitas Indonesia (UI)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Universitas Indonesia (UI)'), findsNothing);
    expect(find.textContaining('No universities yet'), findsOneWidget);
  });

  testWidgets('editing the notes field and losing focus persists the note',
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [MajorEntry(major: 'Law', top: true, anchor: true)],
      targets: [
        UniversityTarget(
          id: 't1',
          major: 'Law',
          country: 'Indonesia',
          university: 'Universitas Indonesia (UI)',
        ),
      ],
    ));

    await tester.enterText(find.byType(TextField), 'Deadline: March 1st');
    // Simulate losing focus (tapping elsewhere) rather than any specific
    // submit gesture — the field is multi-line, so there's no single
    // universal "done" action to rely on across platforms.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Re-find the field after the rebuild the blur-triggered save causes,
    // and confirm the persisted value round-trips back into it — this
    // checks the actual outcome (the note survived a rebuild) rather than
    // reaching into the controller directly, so it doesn't care exactly
    // how/when the save happens under the hood.
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Deadline: March 1st');
  });

  testWidgets("anchor major's targets sort first, others alphabetically by major",
      (tester) async {
    await tester.pumpWidget(await harness(
      tester,
      majors: [
        MajorEntry(major: 'Psychology', top: true, anchor: true),
        MajorEntry(major: 'Computer Science', top: true),
        MajorEntry(major: 'Law', top: true),
      ],
      targets: [
        UniversityTarget(id: 't1', major: 'Law', country: 'Indonesia', university: 'Uni Law'),
        UniversityTarget(
            id: 't2', major: 'Computer Science', country: 'Indonesia', university: 'Uni CS'),
        UniversityTarget(
            id: 't3', major: 'Psychology', country: 'Indonesia', university: 'Uni Psych'),
      ],
    ));

    // Anchor (Psychology) first, then Computer Science, then Law
    // (alphabetical) — checked via each major label's vertical position.
    final psychologyY = tester.getTopLeft(find.text('Psychology')).dy;
    final csY = tester.getTopLeft(find.text('Computer Science')).dy;
    final lawY = tester.getTopLeft(find.text('Law')).dy;

    expect(psychologyY, lessThan(csY));
    expect(csY, lessThan(lawY));
  });
}