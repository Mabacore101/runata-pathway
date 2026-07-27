import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/counsellor_corner_controller.dart';
import 'package:runata_pathway/features/student/data/student_counsellor_corner_repository.dart';
import 'package:runata_pathway/features/student/domain/counsellor_corner.dart';

class _FakeRepository extends StudentCounsellorCornerRepository {
  _FakeRepository(super.box, [CounsellorCorner? initial])
      : _record = initial ?? CounsellorCorner();

  CounsellorCorner _record;
  final List<CounsellorCorner> saved = [];

  @override
  CounsellorCorner load() => _record;

  @override
  Future<void> save(CounsellorCorner record) async {
    _record = record;
    saved.add(record);
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(CounsellorCornerAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeRepository repository;
  late ProviderContainer container;

  Future<CounsellorCornerController> setUpController(
    String boxName, [
    CounsellorCorner? initial,
  ]) async {
    final box = await Hive.openBox<CounsellorCorner>(boxName);
    repository = _FakeRepository(box, initial);
    container = ProviderContainer(
      overrides: [
        studentCounsellorCornerRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container.read(counsellorCornerControllerProvider.notifier);
  }

  CounsellorCorner currentState() =>
      container.read(counsellorCornerControllerProvider);

  test('build() loads whatever the repository returns', () async {
    await setUpController(
      'counsel_ctrl_build',
      CounsellorCorner(qualityTime: 'Existing answer'),
    );

    expect(currentState().qualityTime, 'Existing answer');
  });

  group('updateAll — autosave-on-change', () {
    test('persists a single changed field, built via copyWith, in one '
        'write', () async {
      final controller = await setUpController('counsel_ctrl_update_field');

      await controller.updateAll(currentState().copyWith(rules: 'Curfew at 8pm'));

      expect(currentState().rules, 'Curfew at 8pm');
      expect(repository.load().rules, 'Curfew at 8pm');
    });

    test('genuinely writes to the repository on every call — this is real '
        'autosave, not a cosmetic no-op', () async {
      final controller = await setUpController('counsel_ctrl_writes');

      await controller.updateAll(currentState().copyWith(qualityTime: 'Draft one'));
      await controller.updateAll(currentState().copyWith(qualityTime: 'Draft two'));
      await controller.updateAll(currentState().copyWith(qualityTime: 'Draft three'));

      expect(repository.saved, hasLength(3));
      expect(repository.load().qualityTime, 'Draft three');
    });

    test('updating one field preserves every other already-answered field',
        () async {
      final controller = await setUpController(
        'counsel_ctrl_preserve_others',
        CounsellorCorner(
          qualityTime: 'Dinner together nightly',
          addressedBy: 'Mother',
        ),
      );

      await controller.updateAll(currentState().copyWith(rules: 'New rule'));

      expect(currentState().qualityTime, 'Dinner together nightly');
      expect(currentState().addressedBy, 'Mother');
      expect(currentState().rules, 'New rule');
    });

    test('selecting "Other" on a "who" dropdown and filling its own-text '
        'field both persist correctly together', () async {
      final controller = await setUpController('counsel_ctrl_who_other');

      await controller.updateAll(currentState().copyWith(addressedBy: 'Other'));
      await controller.updateAll(currentState().copyWith(addressedOther: 'Grandmother'));

      expect(repository.load().addressedBy, 'Other');
      expect(repository.load().addressedOther, 'Grandmother');
    });

    test('the Yes/No therapy dropdown persists like any other field',
        () async {
      final controller = await setUpController('counsel_ctrl_therapy');

      await controller.updateAll(currentState().copyWith(hadTherapy: 'Yes'));

      expect(repository.load().hadTherapy, 'Yes');
    });
  });
}
