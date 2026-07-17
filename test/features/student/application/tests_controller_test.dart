import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/tests_controller.dart';
import 'package:runata_pathway/features/student/data/student_tests_repository.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';

void main() {
  group('TestsController', () {
    late ProviderContainer container;

    setUp(() async {
      await setUpTestHive();
      registerAdapterIfNeeded(TestTypeAdapter());
      registerAdapterIfNeeded(TestStatusAdapter());
      registerAdapterIfNeeded(TestEntryAdapter());
    });

    tearDown(() async {
      container.dispose();
      await tearDownTestHive();
    });

    ProviderContainer buildContainer(Box<TestEntry> box) {
      return ProviderContainer(
        overrides: [
          studentTestsRepositoryProvider.overrideWithValue(
            StudentTestsRepository(box),
          ),
        ],
      );
    }

    test('addTest persists immediately and appears in state', () async {
      final box = await Hive.openBox<TestEntry>('tests_ctrl_add');
      container = buildContainer(box);

      final entry =
          await container.read(testsControllerProvider.notifier).addTest(
                TestType.ielts,
              );

      expect(entry.type, TestType.ielts);
      expect(entry.status, TestStatus.planned); // default
      expect(container.read(testsControllerProvider), contains(entry));
      expect(box.values, contains(entry));
    });

    test('deleteTest removes immediately from both state and the box',
        () async {
      final box = await Hive.openBox<TestEntry>('tests_ctrl_delete');
      container = buildContainer(box);
      final notifier = container.read(testsControllerProvider.notifier);

      final entry = await notifier.addTest(TestType.toefl);
      expect(container.read(testsControllerProvider), hasLength(1));

      await notifier.deleteTest(entry.id);
      expect(container.read(testsControllerProvider), isEmpty);
      expect(box.get(entry.id), isNull);
    });

    test(
        'a second non-AP/Other add for an already-present type is a no-op, '
        'not a duplicate row — defense in depth even if the UI somehow '
        'still offered the button', () async {
      final box = await Hive.openBox<TestEntry>('tests_ctrl_dup_guard');
      container = buildContainer(box);
      final notifier = container.read(testsControllerProvider.notifier);

      final first = await notifier.addTest(TestType.sat);
      final second = await notifier.addTest(TestType.sat);

      expect(second.id, first.id); // same row returned, not a new one
      expect(
        container
            .read(testsControllerProvider)
            .where((t) => t.type == TestType.sat),
        hasLength(1),
      );
    });

    test('AP allows a genuine second row for the same type', () async {
      final box = await Hive.openBox<TestEntry>('tests_ctrl_ap_dup');
      container = buildContainer(box);
      final notifier = container.read(testsControllerProvider.notifier);

      final first = await notifier.addTest(TestType.ap);
      final second = await notifier.addTest(TestType.ap);

      expect(second.id, isNot(first.id));
      expect(
        container
            .read(testsControllerProvider)
            .where((t) => t.type == TestType.ap),
        hasLength(2),
      );
    });

    test('saveAll persists every row\'s field edits in one batch', () async {
      final box = await Hive.openBox<TestEntry>('tests_ctrl_save');
      container = buildContainer(box);
      final notifier = container.read(testsControllerProvider.notifier);

      final entry = await notifier.addTest(TestType.hsk);
      final edited = TestEntry(
        id: entry.id,
        type: entry.type,
        target: '6',
        latest: '5',
        status: TestStatus.taken,
        date: '2026-06-01',
      );

      await notifier.saveAll([edited]);

      final reread = box.get(entry.id);
      expect(reread!.target, '6');
      expect(reread.latest, '5');
      expect(reread.status, TestStatus.taken);
      expect(reread.date, '2026-06-01');
    });
  });
}
