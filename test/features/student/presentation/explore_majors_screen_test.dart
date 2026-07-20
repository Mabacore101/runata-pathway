import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/data/student_majors_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_majors_settings.dart';
import 'package:runata_pathway/features/student/presentation/explore_majors_screen.dart';

/// Test-only stand-in for [StudentMajorsRepository] that keeps state in a
/// plain in-memory field instead of touching the real Hive box passed to
/// its constructor.
///
/// Real Hive reads/writes are genuine async disk I/O — `harness()` below
/// still needs `tester.runAsync` just to open the box once at setup, and
/// the same real I/O would happen again on every mutating tap
/// (`addMajor`/`toggleTop`/`setAnchor`/`removeMajor` all persist via
/// `saveSettings`). `tester.tap()`/`pumpAndSettle()` can't be run inside
/// `runAsync()` — pumping frames depends on the FakeAsync-controlled test
/// binding, which isn't active there — so there's no clean way to route
/// every tap-triggered write through real Hive AND have each tap settle
/// correctly within a single `testWidgets` body. Persistence itself is
/// already covered thoroughly against a REAL Hive box in
/// majors_controller_test.dart's plain `test()` suite. This fake lets
/// these widget tests focus on what they're actually for — screen
/// behavior — without re-fighting that same async mismatch on every tap.
///
/// [box] is only accepted to satisfy [StudentMajorsRepository]'s real
/// constructor signature — it's never read from or written to here.
class _FakeStudentMajorsRepository extends StudentMajorsRepository {
  _FakeStudentMajorsRepository(super.box);

  StudentMajorsSettings _settings = StudentMajorsSettings();

  @override
  StudentMajorsSettings loadSettings() => _settings;

  @override
  Future<void> saveSettings(StudentMajorsSettings settings) async {
    _settings = settings;
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(MajorEntryAdapter());
    registerAdapterIfNeeded(StudentMajorsSettingsAdapter());
  });

  tearDown(() async => tearDownTestHive());

  /// Opens a throwaway Hive box (needed only to satisfy
  /// [StudentMajorsRepository]'s constructor type — see
  /// [_FakeStudentMajorsRepository]'s doc comment) and builds the widget
  /// tree, backed by the in-memory fake instead of the real box.
  Future<Widget> harness(
    WidgetTester tester,
    String boxName, {
    VoidCallback? onContinue,
  }) async {
    // ExploreMajorsScreen now supplies its own Scaffold/AppBar (see that
    // file's doc comment — it was bare before, which is why the router
    // rendered it with no Material surface at all). No extra Scaffold
    // wrapping needed here anymore.
    //
    // Its root ListView holds a 17-entry catalog grid plus the majors
    // picker — Flutter's Sliver machinery only BUILDS children within the
    // viewport + a small cache extent, not the whole list, so the test
    // viewport needs to comfortably exceed the full content height or
    // later widgets (the "Add a major" buttons) never get built at all.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The ONLY real Hive I/O in this file — opening this box needs
    // tester.runAsync for the same reason as always (real disk I/O can't
    // complete inside testWidgets' FakeAsync zone). Nothing after this
    // point touches Hive again.
    final box = await tester.runAsync(
      () => Hive.openBox<StudentMajorsSettings>(boxName),
    );
    return ProviderScope(
      overrides: [
        studentMajorsRepositoryProvider.overrideWithValue(
          _FakeStudentMajorsRepository(box!),
        ),
      ],
      child: MaterialApp(
        home: ExploreMajorsScreen(onContinue: onContinue),
      ),
    );
  }

  /// Plain tap + settle — no runAsync needed here anymore. Every mutation
  /// now goes through [_FakeStudentMajorsRepository], which resolves via
  /// an ordinary in-memory Future (no real I/O), so it completes via
  /// normal microtask flushing during pumpAndSettle like any other
  /// in-test state change.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows empty state with no majors added', (tester) async {
    await tester.pumpWidget(await harness(tester, 'majors_screen_empty'));
    expect(find.text('No majors yet — add some below.'), findsOneWidget);
  });

  testWidgets('adding a major from the catalog shows it in the picker list',
      (tester) async {
    await tester.pumpWidget(await harness(tester, 'majors_screen_add'));
    await tapAndSettle(tester, find.text('+ Computer Science'));

    expect(find.text('No majors yet — add some below.'), findsNothing);
    expect(find.text('Computer Science'), findsWidgets);
  });

  testWidgets('anchor button is disabled until the major is Top-marked',
      (tester) async {
    await tester.pumpWidget(
        await harness(tester, 'majors_screen_anchor_disabled'));
    await tapAndSettle(tester, find.text('+ Psychology'));

    final anchorButton = find.widgetWithText(TextButton, 'Anchor');
    expect(tester.widget<TextButton>(anchorButton).onPressed, isNull);
  });

  testWidgets('Continue stays disabled with only 1 Top-marked major',
      (tester) async {
    await tester.pumpWidget(
        await harness(tester, 'majors_screen_continue_disabled'));
    await tapAndSettle(tester, find.text('+ Computer Science'));
    await tapAndSettle(tester, find.text('☆ Top 3'));
    await tapAndSettle(tester, find.text('Anchor'));

    final continueButton =
        find.widgetWithText(ElevatedButton, 'Continue to universities →');
    expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);
  });

  testWidgets('un-marking Top on the anchor major clears the anchor tag',
      (tester) async {
    await tester.pumpWidget(
        await harness(tester, 'majors_screen_untop_clears_anchor'));
    await tapAndSettle(tester, find.text('+ Psychology'));
    await tapAndSettle(tester, find.text('☆ Top 3'));
    await tapAndSettle(tester, find.text('Anchor'));
    expect(find.text('● Anchor'), findsOneWidget);

    await tapAndSettle(tester, find.text('★ Top 3'));

    expect(find.text('● Anchor'), findsNothing);
  });
}