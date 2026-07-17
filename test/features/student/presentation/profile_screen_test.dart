import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';

import 'package:runata_pathway/features/student/data/student_profile_repository.dart';
import 'package:runata_pathway/features/student/domain/student_profile.dart';
import 'package:runata_pathway/features/student/presentation/profile_screen.dart';

/// A `mocktail`-based fake `Box`, deliberately NOT a real Hive box.
///
/// `testWidgets()` runs inside a FakeAsync zone, and Hive's real file I/O
/// (`Box.get`/`.put`/even a first `Box.open`) never resolves inside that
/// zone — a well-documented Hive+flutter_test interaction (isar/hive#386).
/// `WidgetTester.runAsync()` looks like the fix but isn't one here: its
/// own docs say "consider restructuring your code so you do not need
/// runAsync — this is the optimal solution," and calling `tester.tap()`/
/// `pump()`/`pumpAndSettle()` *inside* `runAsync()` is documented to break
/// their normal semantics (flutter/flutter#95203 — a long-press turned
/// into a tap when run that way). That's exactly the failure mode this
/// hit: finders suddenly returning zero widgets.
///
/// The actual fix is to not need real async I/O here at all — this mock
/// stands in for the box, stubbed to resolve like an ordinary (non-real-IO)
/// Future, which `pump()`'s FakeAsync time-advancement CAN observe
/// normally. Real Hive round-trip behavior is already covered where it
/// belongs: the plain `test()`-based files (profile_controller_test.dart,
/// student_profile_hive_test.dart), which have no FakeAsync zone and no
/// such restriction.
class _MockProfileBox extends Mock implements Box<StudentProfile> {}

Future<void> _pumpProfileScreen(
  WidgetTester tester, {
  required Box<StudentProfile> box,
}) async {
  // ProfileScreen is a long form (many fields, a variable number of
  // parent blocks). A plain ListView is lazy about which children it
  // actually builds regardless of whether you passed `children:` or
  // `.builder(...)` — only what's within the viewport + a small cache
  // extent gets mounted. The default flutter_test window is small enough
  // that the Save button at the bottom never gets built at all (not just
  // invisible — genuinely absent from the Element tree), so `find` comes
  // up empty. Growing the virtual screen so the whole form fits avoids
  // needing to scroll-then-interact for every field near the bottom.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studentProfileRepositoryProvider.overrideWithValue(
          StudentProfileRepository(box),
        ),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // google_fonts would otherwise try a real network fetch — widget
    // tests don't run through main.dart, so this guard never executes
    // unless set here too.
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(StudentProfile());
  });

  late _MockProfileBox box;

  setUp(() {
    box = _MockProfileBox();
    // A fresh box: nothing saved yet → ProfileController.build() should
    // fall back to a blank StudentProfile.
    when(() => box.get(any())).thenReturn(null);
    when(() => box.put(any(), any())).thenAnswer((_) async {});
  });

  testWidgets(
    'entering an invalid date of birth and tapping Save renders the '
    'visible warning (planning.md §6\'s decided fix)',
    (tester) async {
      await _pumpProfileScreen(tester, box: box);

      await tester.enterText(
        find.byKey(const Key('profile_dob_field')),
        '30/02/2026', // Feb 30 doesn't exist
      );
      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining("doesn't look valid"), findsOneWidget);
    },
  );

  testWidgets(
    'a valid date of birth does NOT render the warning',
    (tester) async {
      await _pumpProfileScreen(tester, box: box);

      await tester.enterText(
        find.byKey(const Key('profile_dob_field')),
        '12/04/2008',
      );
      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining("doesn't look valid"), findsNothing);
    },
  );

  testWidgets(
    '"+ Add another parent/guardian" adds a second parent block',
    (tester) async {
      await _pumpProfileScreen(tester, box: box);

      // A fresh profile always starts with exactly one block.
      expect(find.byKey(const Key('parent_block_0')), findsOneWidget);
      expect(find.byKey(const Key('parent_block_1')), findsNothing);

      await tester.tap(find.byKey(const Key('add_parent_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('parent_block_0')), findsOneWidget);
      expect(find.byKey(const Key('parent_block_1')), findsOneWidget);
    },
  );

  testWidgets(
    'the delete (✕) button is hidden with only one parent block and '
    'appears once there are two or more',
    (tester) async {
      await _pumpProfileScreen(tester, box: box);

      // Only one block → no delete button anywhere (can't delete down to
      // zero parent blocks).
      expect(find.byKey(const Key('parent_delete_0')), findsNothing);

      await tester.tap(find.byKey(const Key('add_parent_button')));
      await tester.pumpAndSettle();

      // Two blocks → both now show a delete button.
      expect(find.byKey(const Key('parent_delete_0')), findsOneWidget);
      expect(find.byKey(const Key('parent_delete_1')), findsOneWidget);

      // Removing back down to one hides it again.
      await tester.tap(find.byKey(const Key('parent_delete_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('parent_block_1')), findsNothing);
      expect(find.byKey(const Key('parent_delete_0')), findsNothing);
    },
  );

  testWidgets(
    'a successful save shows the "Profile saved." confirmation',
    (tester) async {
      await _pumpProfileScreen(tester, box: box);

      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Profile saved.'), findsOneWidget);
    },
  );

  testWidgets(
    'an invalid-date save does NOT show the success confirmation',
    (tester) async {
      await _pumpProfileScreen(tester, box: box);

      await tester.enterText(
        find.byKey(const Key('profile_dob_field')),
        '31/04/2020', // April has 30 days
      );
      await tester.tap(find.byKey(const Key('profile_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Profile saved.'), findsNothing);
    },
  );
}