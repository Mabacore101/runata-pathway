import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/majors_controller.dart';
import 'package:runata_pathway/features/student/data/student_majors_repository.dart';
import 'package:runata_pathway/features/student/domain/major_entry.dart';
import 'package:runata_pathway/features/student/domain/student_majors_settings.dart';

void main() {
  group('MajorsController + StudentMajorsRepository', () {
    late ProviderContainer container;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(MajorEntryAdapter());
      registerAdapterIfNeeded(StudentMajorsSettingsAdapter());
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestHive();
    });

    ProviderContainer buildContainer(Box<StudentMajorsSettings> settingsBox) {
      return ProviderContainer(
        overrides: [
          studentMajorsRepositoryProvider.overrideWithValue(
            StudentMajorsRepository(settingsBox),
          ),
        ],
      );
    }

    test('starts empty when nothing has been saved yet', () async {
      final box =
          await Hive.openBox<StudentMajorsSettings>('majors_ctrl_empty');
      container = buildContainer(box);

      expect(container.read(majorsControllerProvider).majors, isEmpty);
    });

    group('addMajor', () {
      test('adds a new major with defaults', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_add_defaults');
        container = buildContainer(box);

        await container
            .read(majorsControllerProvider.notifier)
            .addMajor('Computer Science');

        final m = container.read(majorsControllerProvider).majors.single;
        expect(m.major, 'Computer Science');
        expect(m.top, isFalse);
        expect(m.anchor, isFalse);
        expect(m.country, 'United States');
      });

      test('is a no-op if the major is already present', () async {
        final box =
            await Hive.openBox<StudentMajorsSettings>('majors_ctrl_add_dup');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('Computer Science');
        await notifier.addMajor('Computer Science');

        expect(container.read(majorsControllerProvider).majors, hasLength(1));
      });

      test('refuses a 7th major', () async {
        final box =
            await Hive.openBox<StudentMajorsSettings>('majors_ctrl_add_max');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        for (final m in ['A', 'B', 'C', 'D', 'E', 'F']) {
          await notifier.addMajor(m);
        }
        await notifier.addMajor('G');

        final majors = container.read(majorsControllerProvider).majors;
        expect(majors, hasLength(6));
        expect(majors.any((m) => m.major == 'G'), isFalse);
      });

      test('persists across a rebuilt controller', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_add_persist');
        container = buildContainer(box);
        await container
            .read(majorsControllerProvider.notifier)
            .addMajor('Psychology');

        final rebuilt = buildContainer(box);
        addTearDown(rebuilt.dispose);

        expect(rebuilt.read(majorsControllerProvider).majors.single.major,
            'Psychology');
      });
    });

    group('removeMajor — the "free" half of the delete cascade', () {
      test('removes the entry at the given index', () async {
        final box =
            await Hive.openBox<StudentMajorsSettings>('majors_ctrl_rm_basic');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.addMajor('B');
        await notifier.removeMajor(0);

        expect(
            container.read(majorsControllerProvider).majors.single.major, 'B');
      });

      test('removing the anchor major clears the derived anchor', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_rm_anchor');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.toggleTop(0);
        await notifier.setAnchor(0);
        expect(container.read(majorsControllerProvider).anchor?.major, 'A');

        await notifier.removeMajor(0);

        expect(container.read(majorsControllerProvider).anchor, isNull);
        expect(container.read(majorsControllerProvider).majors, isEmpty);
      });

      test('removing a non-anchor major leaves the anchor intact', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_rm_other');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.addMajor('B');
        await notifier.toggleTop(0);
        await notifier.setAnchor(0);

        await notifier.removeMajor(1);

        expect(container.read(majorsControllerProvider).anchor?.major, 'A');
      });
    });

    group('toggleTop', () {
      test('marks an entry top', () async {
        final box =
            await Hive.openBox<StudentMajorsSettings>('majors_ctrl_top_mark');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        expect(await notifier.toggleTop(0), isTrue);
        expect(
            container.read(majorsControllerProvider).majors.single.top, isTrue);
      });

      test('refuses a 4th top mark', () async {
        final box =
            await Hive.openBox<StudentMajorsSettings>('majors_ctrl_top_max');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        for (final m in ['A', 'B', 'C', 'D']) {
          await notifier.addMajor(m);
        }
        await notifier.toggleTop(0);
        await notifier.toggleTop(1);
        await notifier.toggleTop(2);

        expect(await notifier.toggleTop(3), isFalse);
        final majors = container.read(majorsControllerProvider).majors;
        expect(majors[3].top, isFalse);
        expect(
            container.read(majorsControllerProvider).topMarked, hasLength(3));
      });

      test('un-marking top also clears anchor on that entry', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_top_untop');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.toggleTop(0);
        await notifier.setAnchor(0);

        await notifier.toggleTop(0);

        final entry = container.read(majorsControllerProvider).majors.single;
        expect(entry.top, isFalse);
        expect(entry.anchor, isFalse);
        expect(container.read(majorsControllerProvider).anchor, isNull);
      });
    });

    group('setCountry', () {
      test('changes the entry\'s country field', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_country_set');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        expect(container.read(majorsControllerProvider).majors.single.country,
            'United States');

        await notifier.setCountry(0, 'Indonesia');

        expect(container.read(majorsControllerProvider).majors.single.country,
            'Indonesia');
      });

      test('does not affect top/anchor flags on the same entry', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_country_preserves_flags');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.toggleTop(0);
        await notifier.setAnchor(0);

        await notifier.setCountry(0, 'Australia');

        final entry = container.read(majorsControllerProvider).majors.single;
        expect(entry.top, isTrue);
        expect(entry.anchor, isTrue);
        expect(entry.country, 'Australia');
      });

      test('persists across a rebuilt controller', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_country_persist');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);
        await notifier.addMajor('A');
        await notifier.setCountry(0, 'China');

        final rebuilt = buildContainer(box);
        addTearDown(rebuilt.dispose);

        expect(rebuilt.read(majorsControllerProvider).majors.single.country,
            'China');
      });
    });

    group('setAnchor', () {
      test('sets anchor on a top-marked entry', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_anchor_set');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.toggleTop(0);
        await notifier.setAnchor(0);

        expect(container.read(majorsControllerProvider).anchor?.major, 'A');
      });

      test('is a no-op on a non-top entry', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_anchor_noop');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.setAnchor(0);

        expect(container.read(majorsControllerProvider).anchor, isNull);
      });

      test('moving the anchor clears the previous one', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_anchor_move');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.addMajor('B');
        await notifier.toggleTop(0);
        await notifier.toggleTop(1);
        await notifier.setAnchor(0);
        await notifier.setAnchor(1);

        final majors = container.read(majorsControllerProvider).majors;
        expect(majors[0].anchor, isFalse);
        expect(container.read(majorsControllerProvider).anchor?.major, 'B');
      });
    });

    group('readyToContinue', () {
      test('false below 3 top-marked', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_ready_below');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        await notifier.addMajor('A');
        await notifier.toggleTop(0);
        await notifier.setAnchor(0);

        expect(
            container.read(majorsControllerProvider).readyToContinue, isFalse);
      });

      test('false with 3 top-marked but no anchor', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_ready_noanchor');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        for (final m in ['A', 'B', 'C']) {
          await notifier.addMajor(m);
        }
        await notifier.toggleTop(0);
        await notifier.toggleTop(1);
        await notifier.toggleTop(2);

        expect(
            container.read(majorsControllerProvider).readyToContinue, isFalse);
      });

      test('true with exactly 3 top-marked and 1 anchor', () async {
        final box = await Hive.openBox<StudentMajorsSettings>(
            'majors_ctrl_ready_true');
        container = buildContainer(box);
        final notifier = container.read(majorsControllerProvider.notifier);

        for (final m in ['A', 'B', 'C']) {
          await notifier.addMajor(m);
        }
        await notifier.toggleTop(0);
        await notifier.toggleTop(1);
        await notifier.toggleTop(2);
        await notifier.setAnchor(0);

        expect(
            container.read(majorsControllerProvider).readyToContinue, isTrue);
      });
    });
  });
}