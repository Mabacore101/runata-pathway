import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

import '../domain/application_document_state.dart';
import 'student_hive_providers.dart';

/// Wraps the flat, id-keyed [ApplicationDocumentState] box — same shape
/// as `StudentUniversityTargetsRepository` (one independent record per
/// key, no single fixed `HiveKeys` entry), NOT the single-record shape
/// `StudentActivitiesReportRepository`/`StudentPortfolioRepository` use.
///
/// [load] mirrors the JS's `docState(name, key)` get-or-create exactly —
/// a doc that's never been written to reads back as a fresh blank
/// [ApplicationDocumentState], not null, so callers (the controller,
/// specifically) never need their own null-handling branch for "never
/// touched yet."
class StudentApplicationDocumentsRepository {
  StudentApplicationDocumentsRepository(this._box);

  final Box<ApplicationDocumentState> _box;

  ApplicationDocumentState load(String docKey) {
    return _box.get(docKey) ?? ApplicationDocumentState(docKey: docKey);
  }

  Future<void> save(ApplicationDocumentState doc) {
    return _box.put(doc.docKey, doc);
  }
}

final studentApplicationDocumentsRepositoryProvider =
    Provider<StudentApplicationDocumentsRepository>((ref) {
  final box = ref.watch(applicationDocumentsBoxProvider);
  return StudentApplicationDocumentsRepository(box);
});
