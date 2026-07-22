import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
  });

  tearDown(() async => tearDownTestHive());

  test('round-trips a work entry and the maker statement through a real '
      'Hive box', () async {
    final box = await Hive.openBox<StudentPortfolio>('portfolio_box_full');

    final portfolio = StudentPortfolio(
      works: [
        PortfolioWorkEntry(
          title: 'Campus wayfinding app',
          type: 'Mobile app',
          year: '2026',
          role: 'Solo developer',
          brief: 'A Flutter app helping new students navigate campus.',
          link: 'https://github.com/example/wayfinding',
        ),
      ],
      statement: 'I build small tools that solve problems I run into myself.',
    );

    await box.put('portfolio', portfolio);
    await box.close();

    final reopened = await Hive.openBox<StudentPortfolio>('portfolio_box_full');
    final loaded = reopened.get('portfolio');

    expect(loaded, isNotNull);
    expect(loaded!.works.single.title, 'Campus wayfinding app');
    expect(loaded.works.single.type, 'Mobile app');
    expect(loaded.works.single.year, '2026');
    expect(loaded.works.single.role, 'Solo developer');
    expect(loaded.works.single.brief, contains('navigate campus'));
    expect(loaded.works.single.link, 'https://github.com/example/wayfinding');
    expect(
      loaded.statement,
      'I build small tools that solve problems I run into myself.',
    );
  });

  test('a box with nothing written returns null, not a default instance',
      () async {
    final box = await Hive.openBox<StudentPortfolio>('portfolio_box_empty');

    expect(box.get('portfolio'), isNull);
  });

  test('a new StudentPortfolio() starts with an empty works list, not a '
      'seeded blank entry — unlike Parent/Guardian, an empty Portfolio has '
      'nothing to show but the "no works yet" empty state', () {
    expect(StudentPortfolio().works, isEmpty);
  });

  test(
      'works.length is a raw count, not filtered by whether an entry has '
      'real data — matches the JS\'s live "# Works" counter reading '
      'portfolioWorks[n].works.length directly', () async {
    final box = await Hive.openBox<StudentPortfolio>('portfolio_box_count');
    await box.put(
      'portfolio',
      StudentPortfolio(
        works: [
          PortfolioWorkEntry(), // entirely blank
          PortfolioWorkEntry(title: 'Real work'),
        ],
      ),
    );

    expect(box.get('portfolio')!.works.length, 2);
  });
}
