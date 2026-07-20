import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/student_majors_settings.dart';
import 'student_hive_providers.dart';

/// Wraps [StudentMajorsSettings]' single-record box — same fixed-key
/// pattern as [StudentGradesRepository]'s settings half. Unlike Grades,
/// Explore Majors has no separate per-row box: the whole majors list (max
/// 6 entries) lives inside the one settings record, since every mutation
/// (add/remove/toggle-top/set-anchor) already needs to read and rewrite
/// the full list to keep the top-count/anchor rules consistent — see
/// `majors_controller.dart`.
class StudentMajorsRepository {
  StudentMajorsRepository(this._settingsBox);

  final Box<StudentMajorsSettings> _settingsBox;

  StudentMajorsSettings loadSettings() {
    return _settingsBox.get(HiveKeys.studentMajorsSettings) ??
        StudentMajorsSettings();
  }

  Future<void> saveSettings(StudentMajorsSettings settings) {
    return _settingsBox.put(HiveKeys.studentMajorsSettings, settings);
  }
}

final studentMajorsRepositoryProvider =
    Provider<StudentMajorsRepository>((ref) {
  final settingsBox = ref.watch(studentMajorsSettingsBoxProvider);
  return StudentMajorsRepository(settingsBox);
});
