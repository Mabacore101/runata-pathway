import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/portfolio_controller.dart';
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';

class _FakeRepository extends StudentPortfolioRepository {
  _FakeRepository(super.box, [StudentPortfolio? initial])
      : _portfolio = initial ?? StudentPortfolio();

  StudentPortfolio _portfolio;
  final List<StudentPortfolio> saved = [];

  @override
  StudentPortfolio load() => _portfolio;

  @override
  Future<void> save(StudentPortfolio portfolio) async {
    _portfolio = portfolio;
    saved.add(portfolio);
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeRepository repository;
  late ProviderContainer container;

  Future<PortfolioController> setUpController(
    String boxName, [
    StudentPortfolio? initial,
  ]) async {
    final box = await Hive.openBox<StudentPortfolio>(boxName);
    repository = _FakeRepository(box, initial);
    container = ProviderContainer(
      overrides: [studentPortfolioRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container.read(portfolioControllerProvider.notifier);
  }

  StudentPortfolio currentState() => container.read(portfolioControllerProvider);

  test('build() loads whatever the repository returns', () async {
    await setUpController(
      'pf_ctrl_build',
      StudentPortfolio(works: [PortfolioWorkEntry(title: 'Existing')]),
    );

    expect(currentState().works.single.title, 'Existing');
  });

  group('addWork', () {
    test('appends a blank work and persists immediately', () async {
      final controller = await setUpController('pf_ctrl_add');

      await controller.addWork();

      expect(currentState().works, hasLength(1));
      expect(currentState().works.single.title, isNull);
      expect(repository.saved, isNotEmpty);
    });

    test('no cap on the number of works', () async {
      final controller = await setUpController('pf_ctrl_add_many');

      for (var i = 0; i < 12; i++) {
        await controller.addWork();
      }

      expect(currentState().works, hasLength(12));
    });

    test('preserves the existing maker statement when adding a work',
        () async {
      final controller = await setUpController(
        'pf_ctrl_add_keeps_statement',
        StudentPortfolio(statement: 'I make things.'),
      );

      await controller.addWork();

      expect(currentState().statement, 'I make things.');
    });
  });

  group('deleteWork', () {
    test('removes the work at the given index and persists', () async {
      final controller = await setUpController(
        'pf_ctrl_delete',
        StudentPortfolio(
          works: [
            PortfolioWorkEntry(title: 'One'),
            PortfolioWorkEntry(title: 'Two'),
          ],
        ),
      );

      await controller.deleteWork(0);

      expect(currentState().works.single.title, 'Two');
    });

    test('an out-of-range index is a no-op, not a crash', () async {
      final controller = await setUpController(
        'pf_ctrl_delete_oob',
        StudentPortfolio(works: [PortfolioWorkEntry(title: 'One')]),
      );

      await controller.deleteWork(9);
      await controller.deleteWork(-1);

      expect(currentState().works, hasLength(1));
    });

    test('preserves the maker statement when deleting a work', () async {
      final controller = await setUpController(
        'pf_ctrl_delete_keeps_statement',
        StudentPortfolio(
          works: [PortfolioWorkEntry(title: 'One')],
          statement: 'My statement.',
        ),
      );

      await controller.deleteWork(0);

      expect(currentState().statement, 'My statement.');
    });
  });

  group('updateAll — autosave-on-change', () {
    test('persists every field of every work plus the statement, in one '
        'write', () async {
      final controller = await setUpController('pf_ctrl_update_all');

      final updated = StudentPortfolio(
        works: [
          PortfolioWorkEntry(
            title: 'Campus app',
            type: 'Mobile app',
            year: '2026',
            role: 'Solo developer',
            brief: 'A wayfinding app.',
            link: 'https://github.com/example',
          ),
        ],
        statement: 'I build small tools.',
      );

      await controller.updateAll(updated);

      expect(currentState().works.single.title, 'Campus app');
      expect(currentState().works.single.link, 'https://github.com/example');
      expect(currentState().statement, 'I build small tools.');
      expect(repository.load().works.single.type, 'Mobile app');
    });

    test('genuinely writes to the repository on every call — this is real '
        'autosave, not a cosmetic no-op the way Activities Report\'s '
        'original JS Save was', () async {
      final controller = await setUpController('pf_ctrl_update_writes');

      await controller.updateAll(StudentPortfolio(statement: 'Draft one'));
      await controller.updateAll(StudentPortfolio(statement: 'Draft two'));
      await controller.updateAll(StudentPortfolio(statement: 'Draft three'));

      expect(repository.saved, hasLength(3));
      expect(repository.load().statement, 'Draft three');
    });
  });
}
