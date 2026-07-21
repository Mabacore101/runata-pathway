import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/clubs_controller.dart';
import 'package:runata_pathway/features/student/application/majors_controller.dart';
import 'package:runata_pathway/features/student/data/student_majors_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
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
}