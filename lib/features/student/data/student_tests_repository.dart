import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../domain/test_entry.dart';
import 'student_hive_providers.dart';

/// Thin wrapper around the already-open [studentTestsBoxProvider] box.
/// Unlike [StudentProfile] (one record under a fixed key), this is a
/// genuine collection — each [TestEntry] is stored under its own `id`,
/// so add/delete/update-one-row operate directly on the box instead of
/// reading/rewriting one big list every time.
class StudentTestsRepository {
  StudentTestsRepository(this._box);

  final Box<TestEntry> _box;

  List<TestEntry> loadAll() => _box.values.toList();

  Future<void> upsert(TestEntry entry) => _box.put(entry.id, entry);

  Future<void> delete(String id) => _box.delete(id);
}

final studentTestsRepositoryProvider =
    Provider<StudentTestsRepository>((ref) {
  final box = ref.watch(studentTestsBoxProvider);
  return StudentTestsRepository(box);
});
