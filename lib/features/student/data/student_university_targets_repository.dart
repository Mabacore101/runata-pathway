import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../domain/university_target.dart';
import 'student_hive_providers.dart';

/// Wraps the flat [UniversityTarget] box — same shape as
/// `StudentTestsRepository` (loadAll/upsert/delete over a box keyed by
/// each row's own `id`), not the single-settings-record shape
/// `StudentMajorsRepository` uses.
class StudentUniversityTargetsRepository {
  StudentUniversityTargetsRepository(this._box);

  final Box<UniversityTarget> _box;

  List<UniversityTarget> loadAll() => _box.values.toList();

  Future<void> upsert(UniversityTarget target) {
    return _box.put(target.id, target);
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }
}

final studentUniversityTargetsRepositoryProvider =
    Provider<StudentUniversityTargetsRepository>((ref) {
  final box = ref.watch(studentUniversityTargetsBoxProvider);
  return StudentUniversityTargetsRepository(box);
});
