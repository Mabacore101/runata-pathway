import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/activity_entry.dart';
import 'package:runata_pathway/features/student/domain/community_service_entry.dart';
import 'package:runata_pathway/features/student/domain/student_activities_report.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(ActivityEntryAdapter());
    registerAdapterIfNeeded(CommunityServiceEntryAdapter());
    registerAdapterIfNeeded(StudentActivitiesReportAdapter());
  });

  tearDown(() async => tearDownTestHive());

  test('round-trips every section through a real Hive box', () async {
    final box = await Hive.openBox<StudentActivitiesReport>(
      'activities_report_box_full',
    );

    final report = StudentActivitiesReport(
      sectionA: [ActivityEntry(activity: 'Model UN', role: 'Delegate', dates: '2025–2026')],
      sectionC: [
        CommunityServiceEntry(
          activity: 'Beach cleanup',
          role: 'Volunteer',
          months: 5,
          proof: true,
        ),
      ],
      sectionD: [ActivityEntry(activity: 'Science Olympiad')],
      sectionE: [ActivityEntry(activity: 'Prom Committee')],
      sectionF: [ActivityEntry(activity: 'Basketball')],
    );

    await box.put('activities_report', report);
    await box.close();

    final reopened = await Hive.openBox<StudentActivitiesReport>(
      'activities_report_box_full',
    );
    final loaded = reopened.get('activities_report');

    expect(loaded, isNotNull);
    expect(loaded!.sectionA.single.activity, 'Model UN');
    expect(loaded.sectionA.single.role, 'Delegate');
    expect(loaded.sectionC.single.months, 5);
    expect(loaded.sectionC.single.proof, isTrue);
    expect(loaded.sectionD.single.activity, 'Science Olympiad');
    expect(loaded.sectionE.single.activity, 'Prom Committee');
    expect(loaded.sectionF.single.activity, 'Basketball');
  });

  test('a box with nothing written returns null, not a default instance',
      () async {
    final box = await Hive.openBox<StudentActivitiesReport>(
      'activities_report_box_empty',
    );

    expect(box.get('activities_report'), isNull);
  });

  group('CommunityServiceEntry.isEligible (months>=4 && proof)', () {
    test('eligible only when both months>=4 AND proof are true', () {
      expect(
        CommunityServiceEntry(months: 4, proof: true).isEligible,
        isTrue,
      );
      expect(
        CommunityServiceEntry(months: 12, proof: true).isEligible,
        isTrue,
      );
      expect(
        CommunityServiceEntry(months: 3, proof: true).isEligible,
        isFalse,
      );
      expect(
        CommunityServiceEntry(months: 4, proof: false).isEligible,
        isFalse,
      );
    });

    test('"min 4 months" is descriptive only — not enforced anywhere; a '
        'sub-4-month or no-proof entry still round-trips normally, it just '
        'reads as not-yet-eligible', () async {
      final box =
          await Hive.openBox<StudentActivitiesReport>('activities_report_cs');
      await box.put(
        'activities_report',
        StudentActivitiesReport(
          sectionC: [
            CommunityServiceEntry(activity: 'Tutoring', months: 1, proof: false),
          ],
        ),
      );

      final loaded = box.get('activities_report')!;
      expect(loaded.sectionC.single.activity, 'Tutoring');
      expect(loaded.sectionC.single.isEligible, isFalse);
    });
  });

  group('StudentActivitiesReport.hasAnyData (mirrors JS actStarted)', () {
    test('false when every section is empty', () {
      expect(StudentActivitiesReport().hasAnyData, isFalse);
    });

    test('true when any section has a row with a non-blank activity name',
        () {
      expect(
        StudentActivitiesReport(
          sectionF: [ActivityEntry(activity: 'Chess Club')],
        ).hasAnyData,
        isTrue,
      );
    });

    test(
        'a row with only role/months/proof filled in but a blank activity '
        'name does NOT count — matches the JS checking r.act specifically, '
        'not any field', () {
      expect(
        StudentActivitiesReport(
          sectionC: [
            CommunityServiceEntry(role: 'Volunteer', months: 6, proof: true),
          ],
        ).hasAnyData,
        isFalse,
      );
    });

    test('whitespace-only activity name does not count as started', () {
      expect(
        StudentActivitiesReport(
          sectionA: [ActivityEntry(activity: '   ')],
        ).hasAnyData,
        isFalse,
      );
    });
  });
}
