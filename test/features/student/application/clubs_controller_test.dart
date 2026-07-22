import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/clubs_controller.dart';
import 'package:runata_pathway/features/student/application/majors_controller.dart';
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/data/student_majors_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/student_majors_settings.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';

/// Same real-Hive, real-repository convention as majors_controller_test.dart
/// — this provider has no persistence of its own to fake around, so there's
/// no reason to reach for a fake repository here the way the widget test
/// does. Every case below is really testing ONE thing: that
/// `requiredClubProvider` is a live, uncached read over
/// `majorsControllerProvider`'s anchor, exactly as its doc comment claims.
void main() {
  group('requiredClubProvider', () {
    late ProviderContainer container;
    // MajorsController.removeMajor cascades into
    // UniversityTargetsController.removeAllForMajor (see majors_controller
    // .dart's own doc comment) — its build() unconditionally reads
    // studentUniversityTargetsRepositoryProvider, so ANY test that calls
    // removeMajor needs this box + override wired up too, not just tests
    // specifically about university targets. Same requirement
    // majors_controller_test.dart already documents for the same reason.
    late Box<UniversityTarget> uniTargetsBox;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(MajorEntryAdapter());
      registerAdapterIfNeeded(StudentMajorsSettingsAdapter());
      registerAdapterIfNeeded(UniversityTargetAdapter());
      uniTargetsBox =
          await Hive.openBox<UniversityTarget>('clubs_ctrl_uni_targets');
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestHive();
    });

    ProviderContainer buildContainer(Box<StudentMajorsSettings> box) {
      return ProviderContainer(
        overrides: [
          studentMajorsRepositoryProvider.overrideWithValue(
            StudentMajorsRepository(box),
          ),
          studentUniversityTargetsRepositoryProvider.overrideWithValue(
            StudentUniversityTargetsRepository(uniTargetsBox),
          ),
        ],
      );
    }

    test('is null when no anchor major is set', () async {
      final box =
          await Hive.openBox<StudentMajorsSettings>('clubs_ctrl_no_anchor');
      container = buildContainer(box);

      expect(container.read(requiredClubProvider), isNull);
    });

    test('resolves to the club mapped from the anchor major', () async {
      final box =
          await Hive.openBox<StudentMajorsSettings>('clubs_ctrl_resolve');
      container = buildContainer(box);
      final notifier = container.read(majorsControllerProvider.notifier);

      await notifier.addMajor('Computer Science');
      await notifier.toggleTop(0);
      await notifier.setAnchor(0);

      expect(container.read(requiredClubProvider), 'Coding & ICT Club');
    });

    test(
        'updates live when the anchor moves to a different major — no cache '
        'to invalidate', () async {
      final box =
          await Hive.openBox<StudentMajorsSettings>('clubs_ctrl_anchor_move');
      container = buildContainer(box);
      final notifier = container.read(majorsControllerProvider.notifier);

      await notifier.addMajor('Computer Science');
      await notifier.addMajor('Biology');
      await notifier.toggleTop(0);
      await notifier.toggleTop(1);
      await notifier.setAnchor(0);
      expect(container.read(requiredClubProvider), 'Coding & ICT Club');

      await notifier.setAnchor(1);

      expect(container.read(requiredClubProvider), 'Science Research Club');
    });

    test('goes back to null when the anchor major is removed entirely',
        () async {
      final box = await Hive.openBox<StudentMajorsSettings>(
          'clubs_ctrl_anchor_removed');
      container = buildContainer(box);
      final notifier = container.read(majorsControllerProvider.notifier);

      await notifier.addMajor('Computer Science');
      await notifier.toggleTop(0);
      await notifier.setAnchor(0);
      expect(container.read(requiredClubProvider), 'Coding & ICT Club');

      await notifier.removeMajor(0);

      expect(container.read(requiredClubProvider), isNull);
    });

    test(
        'un-Top-marking the anchor also clears the required club — rides on '
        "MajorsController.toggleTop's existing cascade, not new logic here",
        () async {
      final box = await Hive.openBox<StudentMajorsSettings>(
          'clubs_ctrl_untop_anchor');
      container = buildContainer(box);
      final notifier = container.read(majorsControllerProvider.notifier);

      await notifier.addMajor('Computer Science');
      await notifier.toggleTop(0);
      await notifier.setAnchor(0);
      expect(container.read(requiredClubProvider), 'Coding & ICT Club');

      await notifier.toggleTop(0); // un-Top also clears anchor

      expect(container.read(requiredClubProvider), isNull);
    });
  });

  group('ClubRankingController (Day 4 item 2)', () {
    // No Hive setup needed for this group at all — unlike
    // requiredClubProvider above, ClubRankingController holds plain
    // in-memory ranking state (`build() => []`) with nothing to persist
    // and no dependency on majorsControllerProvider, so a bare
    // ProviderContainer is the whole fixture.
    test('starts empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(clubRankingProvider), isEmpty);
    });

    group('addClub', () {
      test('appends when under the cap', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);

        final added = notifier.addClub('Sports Club', 2);

        expect(added, isTrue);
        expect(container.read(clubRankingProvider), ['Sports Club']);
      });

      test('refuses once the cap is reached', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);

        notifier.addClub('Sports Club', 2);
        notifier.addClub('Music Club', 2);
        final thirdAdd = notifier.addClub('Debate & MUN Club', 2);

        expect(thirdAdd, isFalse);
        expect(container.read(clubRankingProvider), ['Sports Club', 'Music Club']);
      });

      test('respects a DIFFERENT cap for a Grade 11/12-sized band', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);

        expect(notifier.addClub('Sports Club', 3), isTrue);
        expect(notifier.addClub('Music Club', 3), isTrue);
        expect(notifier.addClub('Debate & MUN Club', 3), isTrue);
        expect(notifier.addClub('Art & Design Studio', 3), isFalse);
        expect(container.read(clubRankingProvider), hasLength(3));
      });

      test('is a no-op if the club is already ranked (defense-in-depth)', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);

        notifier.addClub('Sports Club', 2);
        final dup = notifier.addClub('Sports Club', 2);

        expect(dup, isFalse);
        expect(container.read(clubRankingProvider), ['Sports Club']);
      });
    });

    test('removeClub splices out the entry at the given index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clubRankingProvider.notifier);
      notifier.addClub('Sports Club', 3);
      notifier.addClub('Music Club', 3);
      notifier.addClub('Debate & MUN Club', 3);

      notifier.removeClub(1);

      expect(container.read(clubRankingProvider),
          ['Sports Club', 'Debate & MUN Club']);
    });

    group('moveUp / moveDown', () {
      test('moveUp swaps with the previous entry', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);
        notifier.addClub('Sports Club', 3);
        notifier.addClub('Music Club', 3);

        notifier.moveUp(1);

        expect(container.read(clubRankingProvider), ['Music Club', 'Sports Club']);
      });

      test('moveUp at index 0 is a no-op', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);
        notifier.addClub('Sports Club', 2);
        notifier.addClub('Music Club', 2);

        notifier.moveUp(0);

        expect(container.read(clubRankingProvider), ['Sports Club', 'Music Club']);
      });

      test('moveDown swaps with the next entry', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);
        notifier.addClub('Sports Club', 3);
        notifier.addClub('Music Club', 3);

        notifier.moveDown(0);

        expect(container.read(clubRankingProvider), ['Music Club', 'Sports Club']);
      });

      test('moveDown at the last index is a no-op', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);
        notifier.addClub('Sports Club', 2);
        notifier.addClub('Music Club', 2);

        notifier.moveDown(1);

        expect(container.read(clubRankingProvider), ['Sports Club', 'Music Club']);
      });
    });

    group('reorder', () {
      test('moving an earlier entry later re-inserts correctly', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);
        notifier.addClub('A', 3);
        notifier.addClub('B', 3);
        notifier.addClub('C', 3);

        notifier.reorder(0, 3); // move 'A' to the end

        expect(container.read(clubRankingProvider), ['B', 'C', 'A']);
      });

      test('moving a later entry earlier re-inserts correctly', () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final notifier = container.read(clubRankingProvider.notifier);
        notifier.addClub('A', 3);
        notifier.addClub('B', 3);
        notifier.addClub('C', 3);

        notifier.reorder(2, 0); // move 'C' to the front

        expect(container.read(clubRankingProvider), ['C', 'A', 'B']);
      });
    });

    test('reset replaces the ranking wholesale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clubRankingProvider.notifier);
      notifier.addClub('Sports Club', 2);

      notifier.reset(['Music Club', 'Debate & MUN Club']);

      expect(
          container.read(clubRankingProvider), ['Music Club', 'Debate & MUN Club']);
    });
  });

  group('ClubsViewController (Day 4 items 3–4)', () {
    // Hive setup IS needed here now, unlike before — ClubsViewController.
    // build() reads clubSubmissionProvider (to decide the starting view),
    // whose own build() reads studentClubsRepositoryProvider, which needs
    // a real, opened Box<StudentClubSelection>. Same class of gap as
    // requiredClubProvider's removeMajor cascade needing the university-
    // targets box even for tests that never touch a university target.
    late Box<StudentClubSelection> clubsBox;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(StudentClubSelectionAdapter());
      clubsBox = await Hive.openBox<StudentClubSelection>('clubs_view_box');
    });

    tearDown(() async => tearDownTestHive());

    ProviderContainer buildContainer() {
      return ProviderContainer(
        overrides: [
          studentClubsRepositoryProvider.overrideWithValue(
            StudentClubsRepository(clubsBox),
          ),
        ],
      );
    }

    test('starts on the ranking view when nothing has been submitted', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(clubsViewProvider), ClubsView.ranking);
    });

    test('starts on the currentSchedule view when a submission already exists',
        () async {
      await clubsBox.put(
        'club_selection',
        StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const ['Sports Club', 'Music Club'],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(clubsViewProvider), ClubsView.currentSchedule);
    });

    test('showPreview switches to the preview view', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clubsViewProvider.notifier);

      notifier.showPreview();

      expect(container.read(clubsViewProvider), ClubsView.preview);
    });

    test('editRanking switches back to the ranking view', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clubsViewProvider.notifier);
      notifier.showPreview();

      notifier.editRanking();

      expect(container.read(clubsViewProvider), ClubsView.ranking);
    });

    test('showCurrentSchedule switches to the currentSchedule view', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clubsViewProvider.notifier);

      notifier.showCurrentSchedule();

      expect(container.read(clubsViewProvider), ClubsView.currentSchedule);
    });

    test('showSubmitted switches to the submitted view', () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final notifier = container.read(clubsViewProvider.notifier);

      notifier.showSubmitted();

      expect(container.read(clubsViewProvider), ClubsView.submitted);
    });

    test(
        "editRanking does NOT touch clubRankingProvider's state — going "
        'back to edit should show what was already ranked, not reset it',
        () {
      final container = buildContainer();
      addTearDown(container.dispose);
      final rankingNotifier = container.read(clubRankingProvider.notifier);
      final viewNotifier = container.read(clubsViewProvider.notifier);
      rankingNotifier.addClub('Sports Club', 2);
      rankingNotifier.addClub('Music Club', 2);
      viewNotifier.showPreview();

      viewNotifier.editRanking();

      expect(container.read(clubRankingProvider), ['Sports Club', 'Music Club']);
    });

    test(
        'the starting view is NOT silently reverted when a submission '
        "happens later — build() reads clubSubmissionProvider ONCE, not "
        'reactively, so an explicit showSubmitted() call right after a '
        'submit() is never clobbered by an automatic rebuild (the exact '
        "race avoided by using ref.read instead of ref.watch in build())",
        () async {
      final container = buildContainer();
      addTearDown(container.dispose);
      expect(container.read(clubsViewProvider), ClubsView.ranking);

      await container.read(clubSubmissionProvider.notifier).submit(
            anchorMajor: 'Computer Science',
            rankedOthers: const ['Sports Club', 'Music Club'],
          );
      container.read(clubsViewProvider.notifier).showSubmitted();

      expect(container.read(clubsViewProvider), ClubsView.submitted);
      // Confirms clubSubmissionProvider itself DID update (the state
      // change genuinely happened) — it's specifically clubsViewProvider
      // that must stay put, not that nothing changed at all.
      expect(container.read(clubSubmissionProvider), isNotNull);
    });
  });

  group('ClubSubmissionController (Day 4 item 4)', () {
    late Box<StudentClubSelection> clubsBox;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(StudentClubSelectionAdapter());
      clubsBox = await Hive.openBox<StudentClubSelection>('submission_box');
    });

    tearDown(() async => tearDownTestHive());

    ProviderContainer buildContainer() {
      return ProviderContainer(
        overrides: [
          studentClubsRepositoryProvider.overrideWithValue(
            StudentClubsRepository(clubsBox),
          ),
        ],
      );
    }

    test('starts null when nothing has been submitted', () {
      final container = buildContainer();
      addTearDown(container.dispose);

      expect(container.read(clubSubmissionProvider), isNull);
    });

    test('submit persists a selection and updates state immediately',
        () async {
      final container = buildContainer();
      addTearDown(container.dispose);

      await container.read(clubSubmissionProvider.notifier).submit(
            anchorMajor: 'Computer Science',
            rankedOthers: const ['Sports Club', 'Music Club'],
          );

      final selection = container.read(clubSubmissionProvider);
      expect(selection, isNotNull);
      expect(selection!.anchorMajor, 'Computer Science');
      expect(selection.rankedOthers, ['Sports Club', 'Music Club']);
      expect(
        selection.submittedAt.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('submit genuinely persists — a SEPARATE container reading the same '
        'box sees it too, not just an in-memory illusion', () async {
      final container1 = buildContainer();
      addTearDown(container1.dispose);
      await container1.read(clubSubmissionProvider.notifier).submit(
            anchorMajor: 'Biology',
            rankedOthers: const ['Environmental Club', 'Sports Club'],
          );

      final container2 = buildContainer();
      addTearDown(container2.dispose);
      final selection = container2.read(clubSubmissionProvider);

      expect(selection, isNotNull);
      expect(selection!.anchorMajor, 'Biology');
      expect(selection.rankedOthers, ['Environmental Club', 'Sports Club']);
    });

    test('loads a pre-existing selection already in the box on a fresh '
        'container', () async {
      await clubsBox.put(
        'club_selection',
        StudentClubSelection(
          anchorMajor: 'Psychology',
          rankedOthers: const ['Music Club'],
          submittedAt: DateTime(2025, 12, 25, 9, 0),
        ),
      );

      final container = buildContainer();
      addTearDown(container.dispose);
      final selection = container.read(clubSubmissionProvider);

      expect(selection, isNotNull);
      expect(selection!.anchorMajor, 'Psychology');
      expect(selection.submittedAt, DateTime(2025, 12, 25, 9, 0));
    });
  });

  group('startMakingChanges logic (Day 4 item 4)', () {
    // startMakingChanges itself takes a WidgetRef, which needs a real
    // widget tree to construct — exercised end-to-end that way in
    // my_clubs_screen_test.dart. This group instead proves the
    // UNDERLYING state-machine steps it performs are correct, by
    // replicating them directly against a ProviderContainer.
    test(
        'strips the CURRENT required club from the prior submission, '
        'preserving the rest in order — even when the persisted ranking '
        'defensively still contained the (old) required club itself',
        () async {
      final clubsBox =
          await Hive.openBox<StudentClubSelection>('make_changes_clubs');
      final majorsBox = await Hive.openBox<StudentMajorsSettings>(
          'make_changes_majors');
      final uniBox =
          await Hive.openBox<UniversityTarget>('make_changes_uni');
      registerAdapterIfNeeded(StudentClubSelectionAdapter());
      registerAdapterIfNeeded(MajorEntryAdapter());
      registerAdapterIfNeeded(StudentMajorsSettingsAdapter());
      registerAdapterIfNeeded(UniversityTargetAdapter());

      await clubsBox.put(
        'club_selection',
        StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const [
            'Coding & ICT Club', // the (old) required club itself —
            // shouldn't normally end up here via real ranking, but the
            // filter should strip it defensively regardless.
            'Sports Club',
            'Music Club',
          ],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      final container = ProviderContainer(overrides: [
        studentClubsRepositoryProvider.overrideWithValue(
          StudentClubsRepository(clubsBox),
        ),
        studentMajorsRepositoryProvider.overrideWithValue(
          StudentMajorsRepository(majorsBox),
        ),
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          StudentUniversityTargetsRepository(uniBox),
        ),
      ]);
      addTearDown(container.dispose);

      final majorsNotifier = container.read(majorsControllerProvider.notifier);
      await majorsNotifier.addMajor('Computer Science');
      await majorsNotifier.toggleTop(0);
      await majorsNotifier.setAnchor(0);

      // The same 5 steps startMakingChanges performs, via container.read
      // instead of a WidgetRef.
      final selection = container.read(clubSubmissionProvider);
      final requiredClub = container.read(requiredClubProvider);
      final filtered = (selection?.rankedOthers ?? const <String>[])
          .where((c) => c != requiredClub)
          .toList();
      container.read(clubRankingProvider.notifier).reset(filtered);
      container.read(clubsViewProvider.notifier).editRanking();

      expect(requiredClub, 'Coding & ICT Club');
      expect(container.read(clubRankingProvider), ['Sports Club', 'Music Club']);
      expect(container.read(clubsViewProvider), ClubsView.ranking);
    });
  });
}