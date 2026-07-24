import 'package:hive_ce/hive_ce.dart';

part 'application_document_state.g.dart';

/// Status label for one Application Materials essay/upload doc, within
/// one grade-level (AY) tab. Mirrors the JS's `MATSTAT` array exactly —
/// order matters: [notStarted] is the implicit default whenever an AY tab
/// has no entry in [ApplicationDocumentState.status] at all (see
/// [ApplicationDocumentState.statusFor]), same as the JS's status object
/// starting empty (`{}`) with every unset tab reading as "Not started" by
/// omission rather than an explicit stored value.
///
/// Named `finalStatus`, not `final` — `final` is a reserved word in Dart.
/// The JS's actual string value is still exactly `"Final"` (see
/// [DocumentStatusLabel.label]); only the Dart identifier differs.
///
/// Field indices below are fixed once shipped, same rule as every other
/// Hive enum in this app (see [TestStatus]'s doc comment) — a new status
/// must always be appended at the end with the next free index. Never
/// reorder or renumber existing entries.
@HiveType(typeId: 18)
enum DocumentStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  draft,
  @HiveField(2)
  inReview,
  @HiveField(3)
  finalStatus,
}

/// Display label matching the JS's `MATSTAT` strings verbatim. Kept as an
/// extension rather than a field on the enum itself — display strings
/// (and eventually colors, e.g. `statCls`'s ns/dr/rv/fn) stay out of
/// Hive-persisted fields, same separation every other enum in this app
/// follows.
extension DocumentStatusLabel on DocumentStatus {
  String get label => switch (this) {
        DocumentStatus.notStarted => 'Not started',
        DocumentStatus.draft => 'Draft',
        DocumentStatus.inReview => 'In review',
        DocumentStatus.finalStatus => 'Final',
      };
}

/// One Application Materials doc's full state — one of the 5 shared-
/// template essays (Personal Statement, Common App Essay, Study Plan,
/// Statement of Purpose, CV/Resume) or Recommendation Letters
/// (upload-kind, same template). Mirrors the JS's `docState(name, key)`
/// shape exactly: `{status:{}, content:{}, note:"", submitted:false}`.
///
/// **Storage shape — flat, id-keyed box, NOT a single owning record.**
/// Unlike `StudentActivitiesReport`/`StudentPortfolio` (Day 5's
/// single-record-with-embedded-lists pattern), each of the 6 docs this
/// model covers is read/written completely independently of the other
/// 5 — saving the Personal Statement should never touch the CV record.
/// So this follows `TestEntry`/`UniversityTarget`'s flat pattern instead:
/// one Hive record per doc, keyed by [docKey] in the box (see
/// `application_materials_catalog.dart`'s `MaterialDoc.key` for the 6
/// valid values — `personal`/`commonapp`/`studyplan`/`sop`/`cv`/
/// `recletter`).
///
/// **`content`/`status` are keyed by AY tab id** (`g10`/`g11`/`g12`, see
/// `academicYearTabs`) — genuinely per-year drafts, unlike Activities
/// Report/Portfolio, whose AY tabs render but don't scope their data
/// (see `application_materials_catalog.dart`'s doc comment on
/// `academicYearTabs` for why those two are the exception).
/// **`note`/`submitted` are NOT tab-keyed** — a single link/filename and
/// a single upload-toggle apply across every AY tab, matching the JS's
/// `D.note`/`D.submitted` being flat fields on the same object, never
/// touched by any AY-keyed branch.
@HiveType(typeId: 19)
class ApplicationDocumentState {
  ApplicationDocumentState({
    required this.docKey,
    Map<String, String>? content,
    Map<String, DocumentStatus>? status,
    this.note,
    this.submitted = false,
  })  : content = content ?? {},
        status = status ?? {};

  /// One of `MaterialDoc.key`'s 6 text/upload-kind values. Stored on the
  /// record itself (not just implied by the box key) for the same
  /// self-describing-row reason `TestEntry.id`/`UniversityTarget.id` are
  /// — readable in isolation, no separate box-key lookup needed to know
  /// which doc a loaded record belongs to.
  @HiveField(0)
  String docKey;

  /// Draft text per AY tab. A tab absent from the map (never written to)
  /// reads as `''` via [contentFor] — same as the JS's
  /// `D.content[ay]||""`.
  @HiveField(1)
  Map<String, String> content;

  /// Status label per AY tab. A tab absent from the map reads as
  /// [DocumentStatus.notStarted] via [statusFor] — same as the JS's
  /// status object starting empty, with every unset tab implicitly
  /// meaning "Not started".
  @HiveField(2)
  Map<String, DocumentStatus> status;

  /// Optional Google Docs/Drive/PDF link (text-kind docs) or the
  /// link-or-filename field (Recommendation Letters, upload-kind). A
  /// single value across every AY tab — matches the JS's `D.note`
  /// exactly.
  @HiveField(3)
  String? note;

  /// Recommendation Letters' "Mark uploaded / undo" toggle (`data-upmark`
  /// in the JS — a bare `D.submitted=!D.submitted`, confirmed no other
  /// side effect: it doesn't touch `note`, doesn't touch `status`).
  /// Unused by the 5 text-kind docs, which track readiness entirely
  /// through [status] instead. Kept on this shared model rather than a
  /// separate upload-only model since every other field here is already
  /// shared across both kinds via the same `docState()`/`renderMatDoc()`
  /// shape in the original JS.
  @HiveField(4)
  bool submitted;

  /// `D.content[ay]||""` equivalent.
  String contentFor(String ay) => content[ay] ?? '';

  /// `D.status[ay]` equivalent — defaults to [DocumentStatus.notStarted]
  /// when the tab has never been touched.
  DocumentStatus statusFor(String ay) => status[ay] ?? DocumentStatus.notStarted;

  /// Mirrors the JS's per-doc "started" check inside `matStartedCount`
  /// exactly:
  /// ```js
  /// const txt=D.content&&D.content[ay]&&D.content[ay].trim();
  /// const st=D.status&&D.status[ay]&&D.status[ay]!=="Not started";
  /// const up=docKind(d.k)==="upload"&&D.note&&D.note.trim();
  /// if(txt||st||D.submitted||up)c++;
  /// ```
  /// [isUpload] should be `true` only for Recommendation Letters — the
  /// only kind [contentFor]/[statusFor] never gets meaningfully written
  /// to, so its "started" signal comes from [note] instead. Read-only,
  /// always re-derived from current state — no separate cached "started"
  /// flag to remember to keep in sync, same philosophy as
  /// `StudentActivitiesReport.hasAnyData`. Not wired to any screen yet —
  /// this exists now so the Hub's status chip and Dashboard's materials
  /// count (both later steps) have something correct to call without
  /// this model needing to change shape when that wiring lands.
  bool startedFor(String ay, {required bool isUpload}) {
    final hasText = contentFor(ay).trim().isNotEmpty;
    final hasStatus = statusFor(ay) != DocumentStatus.notStarted;
    final hasUploadNote = isUpload && (note ?? '').trim().isNotEmpty;
    return hasText || hasStatus || submitted || hasUploadNote;
  }
}
