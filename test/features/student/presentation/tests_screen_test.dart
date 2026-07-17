import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';

import 'package:runata_pathway/features/student/data/student_tests_repository.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';
import 'package:runata_pathway/features/student/presentation/tests_screen.dart';

/// See profile_screen_test.dart's top comment for why this is a mock, not
/// a real Hive box — `testWidgets()`'s FakeAsync zone never lets real
/// Hive I/O resolve (isar/hive#386), and `tester.runAsync()` isn't a safe
/// fix here either (flutter/flutter#95203). `.values`/`.put`/`.delete`
/// are stubbed against a plain in-memory [_store] map so seeding is just
/// a synchronous map write, and taps that add/delete rows resolve as
/// ordinary Futures that FakeAsync's `pump()` observes normally.
class _MockTestsBox extends Mock implements Box<TestEntry> {}

Future<void> _pumpTestsScreen(
  WidgetTester tester, {
  required Box<TestEntry> box,
}) async {
  // Same reasoning as profile_screen_test.dart's helper: a plain
  // ListView only mounts what's within the viewport + cache extent
  // regardless of `children:` vs `.builder()`. With a couple of rows
  // seeded, the "+ [Type]" buttons and Save/Back row can fall outside the
  // default test window and never get built at all.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentTestsRepositoryProvider.overrideWithValue(
          StudentTestsRepository(box),
        ),
      ],
      child: const MaterialApp(home: TestsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(TestEntry(id: 'fallback', type: TestType.other));
  });

  late _MockTestsBox box;
  late Map<String, TestEntry> store;

  setUp(() {
    store = {};
    box = _MockTestsBox();
    when(() => box.values).thenAnswer((_) => store.values);
    when(() => box.put(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as TestEntry;
      store[key] = value;
    });
    when(() => box.delete(any())).thenAnswer((invocation) async {
      store.remove(invocation.positionalArguments[0] as String);
    });
  });

  testWidgets(
    'a non-AP/Other type\'s "+ [Type]" button is no longer offered once '
    'that type is already added — mirrors the JS filtering the button out '
    'entirely rather than showing it disabled',
    (tester) async {
      store['row1'] = TestEntry(id: 'row1', type: TestType.ielts);

      await _pumpTestsScreen(tester, box: box);

      expect(find.byKey(const Key('add_test_ielts')), findsNothing);
      // A still-available type's button remains, for contrast.
      expect(find.byKey(const Key('add_test_toefl')), findsOneWidget);
    },
  );

  testWidgets(
    'AP\'s "+ AP" button stays available even with two AP rows already '
    'added',
    (tester) async {
      store['ap1'] = TestEntry(id: 'ap1', type: TestType.ap);
      store['ap2'] = TestEntry(id: 'ap2', type: TestType.ap);

      await _pumpTestsScreen(tester, box: box);

      expect(find.byKey(const Key('add_test_ap')), findsOneWidget);
    },
  );

  testWidgets(
    'Other\'s "+ Other" button stays available even with a row already '
    'added',
    (tester) async {
      store['other1'] = TestEntry(id: 'other1', type: TestType.other);

      await _pumpTestsScreen(tester, box: box);

      expect(find.byKey(const Key('add_test_other')), findsOneWidget);
    },
  );

  testWidgets(
    'tapping "+ [Type]" for an available type adds a new row to the '
    'rendered list',
    (tester) async {
      await _pumpTestsScreen(tester, box: box);

      expect(find.text('SAT'), findsNothing);

      await tester.tap(find.byKey(const Key('add_test_sat')));
      await tester.pumpAndSettle();

      expect(find.text('SAT'), findsOneWidget);
      // Non-AP/Other, now present → its own add-button should disappear.
      expect(find.byKey(const Key('add_test_sat')), findsNothing);
    },
  );

  testWidgets(
    'deleting a row removes it from the rendered list',
    (tester) async {
      store['row1'] = TestEntry(id: 'row1', type: TestType.ielts);

      await _pumpTestsScreen(tester, box: box);
      expect(find.text('IELTS'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete_test_row1')));
      await tester.pumpAndSettle();

      expect(find.text('IELTS'), findsNothing);
      // Deleting it also brings its add-button back, since it's no
      // longer "already added".
      expect(find.byKey(const Key('add_test_ielts')), findsOneWidget);
    },
  );

  testWidgets(
    'deleting one of two rows only removes that row, not both',
    (tester) async {
      store['row1'] = TestEntry(id: 'row1', type: TestType.ielts);
      store['row2'] = TestEntry(id: 'row2', type: TestType.hsk);

      await _pumpTestsScreen(tester, box: box);
      expect(find.text('IELTS'), findsOneWidget);
      expect(find.text('HSK'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete_test_row1')));
      await tester.pumpAndSettle();

      expect(find.text('IELTS'), findsNothing);
      expect(find.text('HSK'), findsOneWidget);
    },
  );
}