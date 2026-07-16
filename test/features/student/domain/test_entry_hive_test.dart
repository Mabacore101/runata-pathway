import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(TestTypeAdapter());
    registerAdapterIfNeeded(TestStatusAdapter());
    registerAdapterIfNeeded(TestEntryAdapter());
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('TestEntry Hive round-trip', () {
    test('writes and reads back a fully-populated row, keyed by id',
        () async {
      final box = await Hive.openBox<TestEntry>('tests_box_full');

      final entry = TestEntry(
        id: 'row-1',
        type: TestType.ielts,
        target: '7.0',
        latest: '6.5',
        status: TestStatus.registered,
        date: '2026-08-01',
      );

      await box.put(entry.id, entry);
      await box.close();

      final reopened = await Hive.openBox<TestEntry>('tests_box_full');
      final result = reopened.get('row-1');

      expect(result, isNotNull);
      expect(result!.type, TestType.ielts);
      expect(result.target, '7.0');
      expect(result.latest, '6.5');
      expect(result.status, TestStatus.registered);
      expect(result.date, '2026-08-01');
    });

    test(
        'status defaults to planned when not explicitly set '
        '(field/datatype doc: default value is "planed")', () async {
      final box = await Hive.openBox<TestEntry>('tests_box_default');

      await box.put('row-2', TestEntry(id: 'row-2', type: TestType.sat));
      await box.close();

      final reopened = await Hive.openBox<TestEntry>('tests_box_default');
      expect(reopened.get('row-2')!.status, TestStatus.planned);
    });

    test('optional text fields (target/latest/date) round-trip as null',
        () async {
      final box = await Hive.openBox<TestEntry>('tests_box_nulls');

      await box.put(
        'row-3',
        TestEntry(id: 'row-3', type: TestType.toefl),
      );
      await box.close();

      final reopened = await Hive.openBox<TestEntry>('tests_box_nulls');
      final result = reopened.get('row-3');

      expect(result!.target, isNull);
      expect(result.latest, isNull);
      expect(result.date, isNull);
    });

    test('every TestType and TestStatus enum value survives a round-trip',
        () async {
      final box = await Hive.openBox<TestEntry>('tests_box_enum_matrix');

      for (final type in TestType.values) {
        for (final status in TestStatus.values) {
          final id = '${type.name}_${status.name}';
          await box.put(id, TestEntry(id: id, type: type, status: status));
        }
      }
      await box.close();

      final reopened = await Hive.openBox<TestEntry>('tests_box_enum_matrix');
      for (final type in TestType.values) {
        for (final status in TestStatus.values) {
          final id = '${type.name}_${status.name}';
          final result = reopened.get(id);
          expect(result, isNotNull, reason: 'missing round-tripped row $id');
          expect(result!.type, type);
          expect(result.status, status);
        }
      }
    });

    test('multiple distinct ids for the same type coexist in the box '
        '(model layer allows it — the duplicate BLOCK is UI/controller '
        'logic for a later step, not enforced here)', () async {
      final box = await Hive.openBox<TestEntry>('tests_box_same_type');

      await box.put('a', TestEntry(id: 'a', type: TestType.ielts));
      await box.put('b', TestEntry(id: 'b', type: TestType.ielts));

      expect(box.values.where((e) => e.type == TestType.ielts).length, 2);
    });
  });

  group('duplicate-blocking rule surface (model-layer contract only)', () {
    test('AP and Other are the only types marked duplicate-allowed', () {
      // The actual dedup CHECK is UI/controller logic for a later Day 2
      // step — this locks in the set the model exposes, since a typo here
      // would silently make every test type either always or never
      // duplicate-blockable once that logic is built on top of it.
      expect(duplicateAllowedTestTypes, {TestType.ap, TestType.other});

      for (final type in TestType.values) {
        if (type == TestType.ap || type == TestType.other) continue;
        expect(
          duplicateAllowedTestTypes.contains(type),
          isFalse,
          reason: '$type should require duplicate-blocking per the spec',
        );
      }
    });
  });
}
