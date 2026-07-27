import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/counsellor_corner.dart';
import 'student_hive_providers.dart';

/// Thin synchronous wrapper, same shape as `StudentPortfolioRepository`.
class StudentCounsellorCornerRepository {
  StudentCounsellorCornerRepository(this._box);

  final Box<CounsellorCorner> _box;

  CounsellorCorner load() {
    return _box.get(HiveKeys.counsellorCorner) ?? CounsellorCorner();
  }

  Future<void> save(CounsellorCorner record) {
    return _box.put(HiveKeys.counsellorCorner, record);
  }
}

final studentCounsellorCornerRepositoryProvider =
    Provider<StudentCounsellorCornerRepository>((ref) {
  final box = ref.watch(counsellorCornerBoxProvider);
  return StudentCounsellorCornerRepository(box);
});
