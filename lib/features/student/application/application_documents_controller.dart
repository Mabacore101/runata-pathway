import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_application_documents_repository.dart';
import '../domain/application_document_state.dart';
import '../domain/application_materials_catalog.dart';

/// Day 6 item 1/2: shared controller for all 6 text/upload-kind
/// Application Materials docs (5 essays + Recommendation Letters).
///
/// **One controller for all 6 docs, not 6 separate controllers.** Every
/// other controller in this app (`ActivitiesReportController`,
/// `PortfolioController`, `UniversityTargetsController`) is singular —
/// one per screen/feature — so a `NotifierProvider.family` (one instance
/// per doc key) would be the more "textbook" Riverpod shape for 6
/// interchangeable docs. Deliberately not used here: it would be a first
/// `.family` provider in a codebase that has never needed one, and the
/// Hub screen (later) needs to read all 6 docs' state at once for its
/// row chips — trivial as one method call on a single `Map`-holding
/// controller, but real wiring overhead across 6 separate family
/// instances. [state] is therefore `Map<docKey, ApplicationDocumentState>`
/// rather than a single record — each doc stays fully independent inside
/// that map; nothing here ever reads or writes across doc keys.
///
/// **Content/note are batched-until-[save]; status/submitted are
/// immediate.** This mirrors the exact split `ActivitiesReportController`
/// already uses (row add/delete immediate, field edits batched), not
/// `PortfolioController`'s full-autosave shape — chosen because the
/// essay-section spec (`runata-pathway-student-flow-spec.md` §6c–6g) has
/// no "autosaved" language anywhere, unlike Portfolio's explicit callout,
/// and its flow diagram ends in a distinct `[Save] or [All Documents]`
/// step, the same shape Activities Report's diagram uses. [updateContent]/
/// [updateNote] only mutate local state; [save] is the only place either
/// actually reaches Hive. [markReady]/[toggleSubmitted] mirror the JS's
/// `data-mdone`/`data-upmark` handlers exactly — both are bare,
/// unconditional writes with no other side effect, and both persist
/// immediately, independent of whether [save] has ever been called for
/// that doc.
final applicationDocumentsControllerProvider = NotifierProvider<
    ApplicationDocumentsController, Map<String, ApplicationDocumentState>>(
  ApplicationDocumentsController.new,
);

class ApplicationDocumentsController
    extends Notifier<Map<String, ApplicationDocumentState>> {
  @override
  Map<String, ApplicationDocumentState> build() {
    final repository = ref.read(studentApplicationDocumentsRepositoryProvider);
    return {
      for (final doc in materialDocs)
        if (doc.kind == MaterialDocKind.text || doc.kind == MaterialDocKind.upload)
          doc.key: repository.load(doc.key),
    };
  }

  StudentApplicationDocumentsRepository get _repository =>
      ref.read(studentApplicationDocumentsRepositoryProvider);

  /// Current state for [docKey] — a fresh blank record if somehow not
  /// present in [state] (defensive; every valid `MaterialDoc.key` of
  /// kind text/upload is already seeded in [build]).
  ApplicationDocumentState docFor(String docKey) =>
      state[docKey] ?? ApplicationDocumentState(docKey: docKey);

  /// Mirrors the JS's `data-content` handler
  /// (`D.content=D.content||{};D.content[myAY]=ct.value;`) — LOCAL ONLY,
  /// not persisted. The essay screen calls this on every keystroke;
  /// [save] is what actually writes it to Hive. Merges into the existing
  /// `content` map rather than replacing it, so editing one AY tab's
  /// draft never touches another tab's.
  void updateContent(String docKey, String ay, String text) {
    final current = docFor(docKey);
    _updateLocal(
      docKey,
      ApplicationDocumentState(
        docKey: docKey,
        content: {...current.content, ay: text},
        status: current.status,
        note: current.note,
        submitted: current.submitted,
      ),
    );
  }

  /// Mirrors the JS's `data-uplink` handler (`D.note=ul.value`) — same
  /// local-only, batched-until-[save] treatment as [updateContent]. A
  /// single value across every AY tab, matching [ApplicationDocumentState.note]'s
  /// own shape.
  void updateNote(String docKey, String note) {
    final current = docFor(docKey);
    _updateLocal(
      docKey,
      ApplicationDocumentState(
        docKey: docKey,
        content: current.content,
        status: current.status,
        note: note,
        submitted: current.submitted,
      ),
    );
  }

  /// Persists [docKey]'s CURRENT in-memory state (content + note) to
  /// Hive — the only place typed content/link actually reaches disk.
  /// Mirrors `saveBtnHTML()`'s role for Activities Report: a real,
  /// meaningful write for this screen, not a cosmetic no-op.
  Future<void> save(String docKey) async {
    await _repository.save(docFor(docKey));
  }

  /// Mirrors the JS's `data-mdone` handler exactly:
  /// `D.status=D.status||{};D.status[myAY]="Final";` — fully
  /// unconditional. No non-empty check, no criteria check, nothing else.
  /// Immediate, independent write — does NOT require [save] to have been
  /// called first, and does not touch `content`/`note`/`submitted`.
  Future<void> markReady(String docKey, String ay) async {
    final current = docFor(docKey);
    await _persist(
      docKey,
      ApplicationDocumentState(
        docKey: docKey,
        content: current.content,
        status: {...current.status, ay: DocumentStatus.finalStatus},
        note: current.note,
        submitted: current.submitted,
      ),
    );
  }

  /// Mirrors the JS's `data-upmark` handler exactly: `D.submitted=
  /// !D.submitted;` — a bare toggle, no other side effect (confirmed
  /// against the JS: it doesn't touch `note`, doesn't touch `status`).
  /// Immediate, independent write, same as [markReady]. Recommendation
  /// Letters-specific in practice (the only upload-kind doc today), but
  /// not restricted to it here — mirrors the JS, which never gates this
  /// handler by doc kind either.
  Future<void> toggleSubmitted(String docKey) async {
    final current = docFor(docKey);
    await _persist(
      docKey,
      ApplicationDocumentState(
        docKey: docKey,
        content: current.content,
        status: current.status,
        note: current.note,
        submitted: !current.submitted,
      ),
    );
  }

  void _updateLocal(String docKey, ApplicationDocumentState updated) {
    state = {...state, docKey: updated};
  }

  Future<void> _persist(String docKey, ApplicationDocumentState updated) async {
    await _repository.save(updated);
    state = {...state, docKey: updated};
  }
}
