import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/university_targets_controller.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';

void main() {
  group('UniversityTargetsController + StudentUniversityTargetsRepository', () {
    late ProviderContainer container;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(UniversityTargetAdapter());
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestHive();
    });

    ProviderContainer buildContainer(Box<UniversityTarget> box) {
      return ProviderContainer(
        overrides: [
          studentUniversityTargetsRepositoryProvider.overrideWithValue(
            StudentUniversityTargetsRepository(box),
          ),
        ],
      );
    }

    test('starts empty when nothing has been saved yet', () async {
      final box = await Hive.openBox<UniversityTarget>('uni_ctrl_empty');
      container = buildContainer(box);

      expect(container.read(universityTargetsControllerProvider), isEmpty);
    });

    group('addTarget', () {
      test('adds a new target with the given major/country/university', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_basic');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        final ok = await notifier.addTarget(
          major: 'Computer Science',
          country: 'Indonesia',
          university: 'Universitas Indonesia (UI)',
        );

        expect(ok, isTrue);
        final t = container.read(universityTargetsControllerProvider).single;
        expect(t.major, 'Computer Science');
        expect(t.country, 'Indonesia');
        expect(t.university, 'Universitas Indonesia (UI)');
        expect(t.custom, isFalse);
      });

      test('custom flag is stored when passed', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_custom');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(
          major: 'Law',
          country: 'Indonesia',
          university: 'A University Not In The Catalog',
          custom: true,
        );

        expect(container.read(universityTargetsControllerProvider).single.custom, isTrue);
      });

      test('refuses a 4th university for the same major', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_cap');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        for (final name in ['Uni A', 'Uni B', 'Uni C']) {
          await notifier.addTarget(major: 'Law', country: 'Indonesia', university: name);
        }
        final ok = await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Uni D');

        expect(ok, isFalse);
        expect(container.read(universityTargetsControllerProvider), hasLength(3));
      });

      test('the per-major cap is independent per major — a full major does '
          'not block adding for a different major', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_cap_independent');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        for (final name in ['Uni A', 'Uni B', 'Uni C']) {
          await notifier.addTarget(major: 'Law', country: 'Indonesia', university: name);
        }
        final ok = await notifier.addTarget(
          major: 'Computer Science',
          country: 'Indonesia',
          university: 'Uni D',
        );

        expect(ok, isTrue);
        expect(container.read(universityTargetsControllerProvider), hasLength(4));
      });

      test('refuses a case-insensitive duplicate for the same major+country', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_dup');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Universitas Indonesia');
        final ok = await notifier.addTarget(
          major: 'Law',
          country: 'Indonesia',
          university: 'universitas indonesia',
        );

        expect(ok, isFalse);
        expect(container.read(universityTargetsControllerProvider), hasLength(1));
      });

      test('the same university name is allowed again under a different major', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_dup_diff_major');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Universitas Indonesia (UI)');
        final ok = await notifier.addTarget(
          major: 'Computer Science',
          country: 'Indonesia',
          university: 'Universitas Indonesia (UI)',
        );

        expect(ok, isTrue);
        expect(container.read(universityTargetsControllerProvider), hasLength(2));
      });

      test('persists across a rebuilt controller', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_add_persist');
        container = buildContainer(box);
        await container.read(universityTargetsControllerProvider.notifier).addTarget(
              major: 'Psychology',
              country: 'Australia',
              university: 'Monash University',
            );

        final rebuilt = buildContainer(box);
        addTearDown(rebuilt.dispose);

        expect(rebuilt.read(universityTargetsControllerProvider).single.university, 'Monash University');
      });
    });

    group('removeTarget', () {
      test('removes the matching major+country+university row', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_remove_basic');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Uni A');
        await notifier.removeTarget(university: 'Uni A', major: 'Law', country: 'Indonesia');

        expect(container.read(universityTargetsControllerProvider), isEmpty);
      });

      test('only removes the row matching ALL of major+country+university, '
          'not just the name', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_remove_scoped');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Shared Uni');
        await notifier.addTarget(major: 'Computer Science', country: 'Indonesia', university: 'Shared Uni');

        await notifier.removeTarget(university: 'Shared Uni', major: 'Law', country: 'Indonesia');

        final remaining = container.read(universityTargetsControllerProvider);
        expect(remaining, hasLength(1));
        expect(remaining.single.major, 'Computer Science');
      });

      test('is a no-op if nothing matches', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_remove_noop');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Uni A');
        await notifier.removeTarget(university: 'Uni A', major: 'Law', country: 'United States');

        expect(container.read(universityTargetsControllerProvider), hasLength(1));
      });

      test('frees up the per-major cap after removal', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_remove_frees_cap');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        for (final name in ['Uni A', 'Uni B', 'Uni C']) {
          await notifier.addTarget(major: 'Law', country: 'Indonesia', university: name);
        }
        await notifier.removeTarget(university: 'Uni A', major: 'Law', country: 'Indonesia');
        final ok = await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Uni D');

        expect(ok, isTrue);
        expect(container.read(universityTargetsControllerProvider), hasLength(3));
      });
    });

    group('UniversityTargetsDerived (countForMajor/forMajor)', () {
      test('countForMajor and forMajor scope correctly across majors', () async {
        final box = await Hive.openBox<UniversityTarget>('uni_ctrl_derived');
        container = buildContainer(box);
        final notifier = container.read(universityTargetsControllerProvider.notifier);

        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Uni A');
        await notifier.addTarget(major: 'Law', country: 'Indonesia', university: 'Uni B');
        await notifier.addTarget(major: 'Computer Science', country: 'Indonesia', university: 'Uni C');

        final state = container.read(universityTargetsControllerProvider);
        expect(state.countForMajor('Law'), 2);
        expect(state.countForMajor('Computer Science'), 1);
        expect(state.countForMajor('Medicine'), 0);
        expect(state.forMajor('Law'), hasLength(2));
      });
    });
  });
}
