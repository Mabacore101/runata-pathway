import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/dashboard_data.dart';
import 'package:runata_pathway/features/student/data/student_activities_report_repository.dart';
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/data/student_portfolio_repository.dart';
import 'package:runata_pathway/features/student/data/student_tests_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/fit_status.dart';
import 'package:runata_pathway/features/student/domain/portfolio_work_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/student_portfolio.dart';
import 'package:runata_pathway/features/student/domain/test_entry.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';

class _FakeTargetsRepository extends StudentUniversityTargetsRepository {
  _FakeTargetsRepository(super.box, [List<UniversityTarget>? initial]) : _targets = [...?initial];
  final List<UniversityTarget> _targets;
  @override
  List<UniversityTarget> loadAll() => _targets;
  @override
  Future<void> upsert(UniversityTarget target) async => _targets.add(target);
  @override
  Future<void> delete(String id) async => _targets.removeWhere((t) => t.id == id);
}

class _FakeTestsRepository extends StudentTestsRepository {
  _FakeTestsRepository(super.box, [List<TestEntry>? initial]) : _tests = [...?initial];
  final List<TestEntry> _tests;
  @override
  List<TestEntry> loadAll() => _tests;
  @override
  Future<void> upsert(TestEntry entry) async => _tests.add(entry);
  @override
  Future<void> delete(String id) async => _tests.removeWhere((t) => t.id == id);
}

class _FakeActivitiesReportRepository extends StudentActivitiesReportRepository {
  _FakeActivitiesReportRepository(super.box, [StudentActivitiesReport? initial])
      : _report = initial ?? StudentActivitiesReport();
  StudentActivitiesReport _report;
  @override
  StudentActivitiesReport load() => _report;
  @override
  Future<void> save(StudentActivitiesReport report) async => _report = report;
}

class _FakeClubsRepository extends StudentClubsRepository {
  _FakeClubsRepository(super.box, [StudentClubSelection? initial]) : _selection = initial;
  StudentClubSelection? _selection;
  @override
  StudentClubSelection? loadSelection() => _selection;
  @override
  Future<void> saveSelection(StudentClubSelection selection) async => _selection = selection;
}

class _FakePortfolioRepository extends StudentPortfolioRepository {
  _FakePortfolioRepository(super.box, [StudentPortfolio? initial])
      : _portfolio = initial ?? StudentPortfolio();
  StudentPortfolio _portfolio;
  @override
  StudentPortfolio load() => _portfolio;
  @override
  Future<void> save(StudentPortfolio portfolio) async => _portfolio = portfolio;
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(UniversityTargetAdapter());
    registerAdapterIfNeeded(TestTypeAdapter());
    registerAdapterIfNeeded(TestStatusAdapter());
    registerAdapterIfNeeded(TestEntryAdapter());
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
    registerAdapterIfNeeded(PortfolioWorkEntryAdapter());
    registerAdapterIfNeeded(StudentPortfolioAdapter());
  });

  tearDown(() async => tearDownTestHive());

  Future<ProviderContainer> buildContainer(
    String boxPrefix, {
    List<UniversityTarget>? targets,
    List<TestEntry>? tests,
    StudentActivitiesReport? activitiesReport,
    StudentClubSelection? clubSelection,
    StudentPortfolio? portfolio,
  }) async {
    final targetsBox = await Hive.openBox<UniversityTarget>('$boxPrefix-targets');
    final testsBox = await Hive.openBox<TestEntry>('$boxPrefix-tests');
    final activitiesBox = await Hive.openBox<StudentActivitiesReport>('$boxPrefix-activities');
    final clubsBox = await Hive.openBox<StudentClubSelection>('$boxPrefix-clubs');
    final portfolioBox = await Hive.openBox<StudentPortfolio>('$boxPrefix-portfolio');

    final container = ProviderContainer(
      overrides: [
        studentUniversityTargetsRepositoryProvider
            .overrideWithValue(_FakeTargetsRepository(targetsBox, targets)),
        studentTestsRepositoryProvider.overrideWithValue(_FakeTestsRepository(testsBox, tests)),
        studentActivitiesReportRepositoryProvider.overrideWithValue(
          _FakeActivitiesReportRepository(activitiesBox, activitiesReport),
        ),
        studentClubsRepositoryProvider
            .overrideWithValue(_FakeClubsRepository(clubsBox, clubSelection)),
        studentPortfolioRepositoryProvider
            .overrideWithValue(_FakePortfolioRepository(portfolioBox, portfolio)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('dashboardFitProvider', () {
    test('no targets at all → noTargets', () async {
      final container = await buildContainer('fit_no_targets');
      expect(container.read(dashboardFitProvider).kind, DashboardFitKind.noTargets);
    });

    test('targets exist but no IELTS test recorded → noIelts', () async {
      final container = await buildContainer(
        'fit_no_ielts',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'Computer Science',
            country: 'Australia',
            university: 'University of Melbourne',
          ),
        ],
      );
      expect(container.read(dashboardFitProvider).kind, DashboardFitKind.noIelts);
    });

    test('an IELTS test with no latest score still counts as "no IELTS" — '
        'matches studentIeltsScore\'s own null-parse contract', () async {
      final container = await buildContainer(
        'fit_ielts_no_score',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'Computer Science',
            country: 'Australia',
            university: 'University of Melbourne',
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts)], // no `latest` set
      );
      expect(container.read(dashboardFitProvider).kind, DashboardFitKind.noIelts);
    });

    test('a real catalog match with a tracked IELTS requirement → found, '
        'with the correct status and university name', () async {
      final container = await buildContainer(
        'fit_found',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'Computer Science',
            country: 'Australia',
            university: 'University of Melbourne', // real catalog entry, ielts: 6.5
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '6.5')],
      );

      final fit = container.read(dashboardFitProvider);
      expect(fit.kind, DashboardFitKind.found);
      expect(fit.universityName, 'University of Melbourne');
      expect(fit.status!.tier, FitTier.met); // gap = 6.5-6.5 = 0 → met
    });

    test('the FIRST target with no tracked IELTS requirement is skipped — '
        'fit is computed from the next target that DOES have one, not '
        'treated as "no fit data"', () async {
      final container = await buildContainer(
        'fit_skip_past',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'Computer Science',
            country: 'Indonesia',
            university: 'Universitas Indonesia (UI)', // real entry, ielts: null
          ),
          UniversityTarget(
            id: 't2',
            major: 'Computer Science',
            country: 'Australia',
            university: 'University of Melbourne', // real entry, ielts: 6.5
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '7.0')],
      );

      final fit = container.read(dashboardFitProvider);
      expect(fit.kind, DashboardFitKind.found);
      expect(fit.universityName, 'University of Melbourne');
    });

    test('every target lacking a tracked IELTS requirement → '
        'nonIeltsRoute, not found', () async {
      final container = await buildContainer(
        'fit_non_ielts_route',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'Computer Science',
            country: 'Indonesia',
            university: 'Universitas Indonesia (UI)', // ielts: null
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '7.0')],
      );

      expect(container.read(dashboardFitProvider).kind, DashboardFitKind.nonIeltsRoute);
    });

    test('a custom (student-typed) university not in the catalog at all '
        'also falls through to nonIeltsRoute', () async {
      final container = await buildContainer(
        'fit_custom_uni',
        targets: [
          UniversityTarget(
            id: 't1',
            major: 'Computer Science',
            country: 'Australia',
            university: 'Some University Not In The Catalog',
            custom: true,
          ),
        ],
        tests: [TestEntry(id: 'e1', type: TestType.ielts, latest: '7.0')],
      );

      expect(container.read(dashboardFitProvider).kind, DashboardFitKind.nonIeltsRoute);
    });
  });

  group('dashboardActivitiesProvider', () {
    test('everything empty → all zeros', () async {
      final container = await buildContainer('activities_empty');
      final summary = container.read(dashboardActivitiesProvider);

      expect(summary.activityRows, 0);
      expect(summary.clubsCount, 0);
      expect(summary.portfolioWorks, 0);
      expect(summary.total, 0);
    });

    test('activity rows are counted across all 5 sections (A/C/D/E/F), '
        'not just one', () async {
      final container = await buildContainer(
        'activities_rows',
        activitiesReport: StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: 'Debate Club')],
          sectionC: [CommunityServiceEntry(activity: 'Beach Cleanup')],
          sectionD: [ActivityEntry(activity: 'Math Olympiad')],
          sectionE: [ActivityEntry(activity: 'Prom Committee')],
          sectionF: [ActivityEntry(activity: 'Basketball')],
        ),
      );

      expect(container.read(dashboardActivitiesProvider).activityRows, 5);
    });

    test('a row with a blank activity field does not count', () async {
      final container = await buildContainer(
        'activities_blank_row',
        activitiesReport: StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: '   '), ActivityEntry(activity: 'Real one')],
        ),
      );

      expect(container.read(dashboardActivitiesProvider).activityRows, 1);
    });

    test('clubsCount is 0 when clubs were never submitted', () async {
      final container = await buildContainer('activities_clubs_unsubmitted');
      expect(container.read(dashboardActivitiesProvider).clubsCount, 0);
    });

    test('clubsCount is 1 (required club only) + rankedOthers.length once '
        'submitted', () async {
      final container = await buildContainer(
        'activities_clubs_submitted',
        clubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const ['Sports Club', 'Art & Design Studio'],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      // 1 required + 2 ranked others = 3.
      expect(container.read(dashboardActivitiesProvider).clubsCount, 3);
    });

    test('portfolio works are filtered by non-blank title, matching the '
        'JS exactly — NOT the same raw count the Hub chip uses', () async {
      final container = await buildContainer(
        'activities_portfolio_works',
        portfolio: StudentPortfolio(
          works: [
            PortfolioWorkEntry(title: 'Real work'),
            PortfolioWorkEntry(), // blank title — should not count
            PortfolioWorkEntry(title: '   '), // whitespace-only — should not count
          ],
        ),
      );

      expect(container.read(dashboardActivitiesProvider).portfolioWorks, 1);
    });

    test('total is activityRows + clubsCount, NOT including portfolioWorks',
        () async {
      final container = await buildContainer(
        'activities_total',
        activitiesReport: StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: 'Debate Club')],
        ),
        clubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const ['Sports Club'],
          submittedAt: DateTime(2026, 1, 1),
        ),
        portfolio: StudentPortfolio(works: [PortfolioWorkEntry(title: 'Some work')]),
      );

      final summary = container.read(dashboardActivitiesProvider);
      expect(summary.activityRows, 1);
      expect(summary.clubsCount, 2); // 1 required + 1 ranked
      expect(summary.portfolioWorks, 1);
      expect(summary.total, 3); // 1 + 2, NOT +1 for portfolioWorks
    });
  });
}
