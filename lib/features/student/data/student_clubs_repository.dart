import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/student_club_selection.dart';
import 'student_hive_providers.dart';

/// Single-record box, same pattern as [StudentMajorsSettings]'s
/// repository — one [StudentClubSelection] per student under a fixed
/// key, not a natural collection.
///
/// Returns `null` from [loadSelection] for "never submitted" rather than
/// an empty default instance — see [StudentClubSelection]'s own doc
/// comment for why that distinction matters here specifically.
class StudentClubsRepository {
  StudentClubsRepository(this._box);

  final Box<StudentClubSelection> _box;

  StudentClubSelection? loadSelection() {
    return _box.get(HiveKeys.studentClubSelection);
  }

  Future<void> saveSelection(StudentClubSelection selection) {
    return _box.put(HiveKeys.studentClubSelection, selection);
  }
}

final studentClubsRepositoryProvider = Provider<StudentClubsRepository>((ref) {
  final box = ref.watch(studentClubsBoxProvider);
  return StudentClubsRepository(box);
});
