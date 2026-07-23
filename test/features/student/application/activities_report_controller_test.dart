import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/activities_report_controller.dart';
import 'package:runata_pathway/features/student/data/student_activities_report_repository.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';

class _FakeRepository extends StudentActivitiesReportRepository {
  _FakeRepository(super.box, [StudentActivitiesReport? initial])
      : _report = initial ?? StudentActivitiesReport();

  StudentActivitiesReport _report;
  final List<StudentActivitiesReport> saved = [];

  @override
  StudentActivitiesReport load() => _report;

  @override
  Future<void> save(StudentActivitiesReport report) async {
    _report = report;
    saved.add(report);
  }
}

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeRepository repository;
  late ProviderContainer container;

  Future<ActivitiesReportController> setUpController(
    String boxName, [
    StudentActivitiesReport? initial,
  ]) async {
    final box = await Hive.openBox<StudentActivitiesReport>(boxName);
    repository = _FakeRepository(box, initial);
    container = ProviderContainer(
      overrides: [
        studentActivitiesReportRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container.read(activitiesReportControllerProvider.notifier);
  }

  StudentActivitiesReport currentState() =>
      container.read(activitiesReportControllerProvider);

  test('build() loads whatever the repository returns', () async {
    await setUpController(
      'act_ctrl_build',
      StudentActivitiesReport(sectionF: [ActivityEntry(activity: 'Chess Club')]),
    );

    expect(currentState().sectionF.single.activity, 'Chess Club');
  });

  group('addActivityRow', () {
    test('appends a blank row to the targeted section and persists immediately',
        () async {
      final controller = await setUpController('act_ctrl_add_a');

      await controller.addActivityRow(ActivitiesReportSection.a);

      expect(currentState().sectionA, hasLength(1));
      expect(currentState().sectionA.single.activity, isNull);
      expect(repository.saved, isNotEmpty);
    });

    test('D/E/F are managed independently — adding to one leaves the others '
        'untouched', () async {
      final controller = await setUpController('act_ctrl_add_def');

      await controller.addActivityRow(ActivitiesReportSection.d);
      await controller.addActivityRow(ActivitiesReportSection.f);

      expect(currentState().sectionD, hasLength(1));
      expect(currentState().sectionF, hasLength(1));
      expect(currentState().sectionE, isEmpty);
      expect(currentState().sectionA, isEmpty);
    });

    test('no cap on the number of rows', () async {
      final controller = await setUpController('act_ctrl_add_many');

      for (var i = 0; i < 10; i++) {
        await controller.addActivityRow(ActivitiesReportSection.e);
      }

      expect(currentState().sectionE, hasLength(10));
    });
  });

  group('deleteActivityRow', () {
    test('removes the row at the given index and persists', () async {
      final controller = await setUpController(
        'act_ctrl_delete',
        StudentActivitiesReport(
          sectionA: [
            ActivityEntry(activity: 'One'),
            ActivityEntry(activity: 'Two'),
          ],
        ),
      );

      await controller.deleteActivityRow(ActivitiesReportSection.a, 0);

      expect(currentState().sectionA.single.activity, 'Two');
    });

    test('an out-of-range index is a no-op, not a crash', () async {
      final controller = await setUpController(
        'act_ctrl_delete_oob',
        StudentActivitiesReport(sectionA: [ActivityEntry(activity: 'One')]),
      );

      await controller.deleteActivityRow(ActivitiesReportSection.a, 5);
      await controller.deleteActivityRow(ActivitiesReportSection.a, -1);

      expect(currentState().sectionA.single.activity, 'One');
    });
  });

  group('Section C (community service) add/delete', () {
    test('addCommunityServiceRow appends and persists', () async {
      final controller = await setUpController('act_ctrl_cs_add');

      await controller.addCommunityServiceRow();
      await controller.addCommunityServiceRow();

      expect(currentState().sectionC, hasLength(2));
    });

    test('deleteCommunityServiceRow removes by index', () async {
      final controller = await setUpController(
        'act_ctrl_cs_delete',
        StudentActivitiesReport(
          sectionC: [
            CommunityServiceEntry(activity: 'Cleanup'),
            CommunityServiceEntry(activity: 'Tutoring'),
          ],
        ),
      );

      await controller.deleteCommunityServiceRow(0);

      expect(currentState().sectionC.single.activity, 'Tutoring');
    });

    test('an out-of-range index is a no-op', () async {
      final controller = await setUpController(
        'act_ctrl_cs_delete_oob',
        StudentActivitiesReport(sectionC: [CommunityServiceEntry(activity: 'Cleanup')]),
      );

      await controller.deleteCommunityServiceRow(9);

      expect(currentState().sectionC, hasLength(1));
    });
  });

  group('saveAll', () {
    test('persists field values across every stored section in one batch',
        () async {
      final controller = await setUpController('act_ctrl_save_all');

      final updated = StudentActivitiesReport(
        sectionA: [ActivityEntry(activity: 'Debate', role: 'Captain', dates: '2025–2026')],
        sectionC: [CommunityServiceEntry(activity: 'Cleanup', months: 5, proof: true)],
        sectionD: [ActivityEntry(activity: 'Olympiad')],
        sectionE: [ActivityEntry(activity: 'Prom Committee')],
        sectionF: [ActivityEntry(activity: 'Basketball')],
      );

      await controller.saveAll(updated);

      expect(currentState().sectionA.single.role, 'Captain');
      expect(currentState().sectionC.single.months, 5);
      expect(currentState().sectionD.single.activity, 'Olympiad');
      expect(repository.load().sectionF.single.activity, 'Basketball');
    });

    test('genuinely writes to the repository, unlike the JS\'s cosmetic Save '
        '— confirms saveAll is not a no-op', () async {
      final controller = await setUpController('act_ctrl_save_writes');

      await controller.saveAll(
        StudentActivitiesReport(sectionA: [ActivityEntry(activity: 'Model UN')]),
      );

      expect(repository.saved, hasLength(1));
      expect(repository.load().sectionA.single.activity, 'Model UN');
    });
  });
}
