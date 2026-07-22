import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../../../core/persistence/hive_boxes.dart';
import '../domain/student_portfolio.dart';
import 'student_hive_providers.dart';

/// Thin synchronous wrapper, same shape as `StudentProfileRepository`.
class StudentPortfolioRepository {
  StudentPortfolioRepository(Box<StudentPortfolio> box) : _box = box;

  final Box<StudentPortfolio> _box;

  StudentPortfolio load() {
    return _box.get(HiveKeys.studentPortfolio) ?? StudentPortfolio();
  }

  Future<void> save(StudentPortfolio portfolio) {
    return _box.put(HiveKeys.studentPortfolio, portfolio);
  }
}

final studentPortfolioRepositoryProvider =
    Provider<StudentPortfolioRepository>((ref) {
  final box = ref.watch(studentPortfolioBoxProvider);
  return StudentPortfolioRepository(box);
});
