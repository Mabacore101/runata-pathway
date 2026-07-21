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
}