import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/student_profile.dart';
import 'student_hive_providers.dart';

/// Thin wrapper around the already-open [studentProfileBoxProvider] box.
///
/// Hive's local `Box.get`/`Box.put` are synchronous — there's no loading
/// spinner or `FutureProvider` needed anywhere above this. Unlike
/// `LocalStudentAuthRepository` (which simulates I/O with
/// `Future.delayed` because a real backend will eventually be async),
/// this repository has no equivalent need: it's genuinely local-only per
/// planning.md §4, not a stand-in for a future network call.
class StudentProfileRepository {
  StudentProfileRepository(this._box);

  final Box<StudentProfile> _box;

  /// Returns the stored profile, or a blank one if nothing's been saved
  /// yet — mirrors the flow spec's "Has Any Data? → Pre-filled Form /
  /// Blank Form" diamond, so callers don't need to special-case "no
  /// profile exists yet" separately from "an empty profile exists".
  StudentProfile load() {
    return _box.get(HiveKeys.studentProfile) ?? StudentProfile();
  }

  Future<void> save(StudentProfile profile) {
    return _box.put(HiveKeys.studentProfile, profile);
  }
}

final studentProfileRepositoryProvider =
    Provider<StudentProfileRepository>((ref) {
  final box = ref.watch(studentProfileBoxProvider);
  return StudentProfileRepository(box);
});