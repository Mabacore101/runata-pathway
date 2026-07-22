import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/student_activities_report.dart';
import 'student_hive_providers.dart';

/// Thin synchronous wrapper, same shape as `StudentProfileRepository` —
/// Hive's local reads/writes don't need a loading state or async
/// provider layered on top.
class StudentActivitiesReportRepository {
  StudentActivitiesReportRepository(Box<StudentActivitiesReport> box)
      : _box = box;

  final Box<StudentActivitiesReport> _box;

  StudentActivitiesReport load() {
    return _box.get(HiveKeys.studentActivitiesReport) ??
        StudentActivitiesReport();
  }

  Future<void> save(StudentActivitiesReport report) {
    return _box.put(HiveKeys.studentActivitiesReport, report);
  }
}

final studentActivitiesReportRepositoryProvider =
    Provider<StudentActivitiesReportRepository>((ref) {
  final box = ref.watch(studentActivitiesReportBoxProvider);
  return StudentActivitiesReportRepository(box);
});
