/// Application Materials — Pathway form 6 — catalog data. Pulled
/// directly from the original site's `DOCS` array (day1-trimmed-
/// reference.md, line 813), same reasoning Day 2/3/4 deferred their own
/// data tables (`CURRICULUM`, `MAJORS`, `club_catalog.dart`'s tables)
/// until actually needed — this is data, not behavior.
library;

/// Mirrors the JS's per-doc-type branch in `renderMaterials()`
/// (`docKind()`): each kind gets a different detail screen shape and a
/// different way of computing its status chip.
enum MaterialDocKind { report, builder, text, upload }

class MaterialDoc {
  const MaterialDoc({
    required this.key,
    required this.name,
    required this.kind,
    this.availableToday = false,
  });

  final String key;
  final String name;
  final MaterialDocKind kind;

  /// True only for the 2 rows Day 5 actually builds (Student Activities
  /// Report, Portfolio). The other 6 stay visibly present but inert —
  /// same "visibly disabled, not hidden" pattern as Day 1's Parent/Staff
  /// role buttons — until Day 6 lands their real screens. Flip this to
  /// `true` for each doc as its Day 6 screen ships; nothing else on the
  /// Hub needs to change when that happens.
  final bool availableToday;

  /// Matches the JS's per-kind `sub` text in `renderMaterials()` exactly.
  String get subtitle {
    switch (kind) {
      case MaterialDocKind.report:
        return 'Runata report format · you fill it in';
      case MaterialDocKind.builder:
        return 'Your works + maker statement';
      case MaterialDocKind.text:
        return 'Write & get feedback';
      case MaterialDocKind.upload:
        return 'Upload / link';
    }
  }
}

/// The 8 rows shown on the Hub — order and names match the JS's `DOCS`
/// array verbatim.
const materialDocs = <MaterialDoc>[
  MaterialDoc(
    key: 'activities',
    name: 'Student Activities Report',
    kind: MaterialDocKind.report,
    availableToday: true,
  ),
  MaterialDoc(
    key: 'portfolio',
    name: 'Portfolio',
    kind: MaterialDocKind.builder,
    availableToday: true,
  ),
  MaterialDoc(
    key: 'personal',
    name: 'Personal Statement (UCAS)',
    kind: MaterialDocKind.text,
  ),
  MaterialDoc(
    key: 'commonapp',
    name: 'Common App Essay',
    kind: MaterialDocKind.text,
  ),
  MaterialDoc(
    key: 'studyplan',
    name: 'Study Plan',
    kind: MaterialDocKind.text,
  ),
  MaterialDoc(
    key: 'sop',
    name: 'Statement of Purpose / Motivation Letter',
    kind: MaterialDocKind.text,
  ),
  MaterialDoc(
    key: 'cv',
    name: 'CV / Resume',
    kind: MaterialDocKind.text,
  ),
  MaterialDoc(
    key: 'recletter',
    name: 'Recommendation Letters',
    kind: MaterialDocKind.upload,
  ),
];

/// The 3 grade-level tabs (JS: `AYS` — confusingly named for "academic
/// year" but genuinely Gr 10/11/12, not academic years; see
/// day5-trimmed-source.md's "Read this first" note: "planning.md's '3
/// grade-level tabs' description was already right; this is just a
/// naming-collision note, not a correction"). Order matches the JS
/// exactly: g10, g11, g12.
///
/// **These tabs don't actually scope Activities Report or Portfolio.**
/// Tracing the JS, `actStarted(stu.n)` and `portfolioWorks[stu.n]` are
/// keyed only by student name, never by the AY tab — that only matters
/// once Day 6's essay docs exist (`docState(...).content[ay]`, genuinely
/// per-year drafts). So the tabs need to render and default correctly
/// today, but switching between them doesn't change what either of
/// today's 2 real docs show. See planning.md for the same note.
const academicYearTabs = <({String id, String label})>[
  (id: 'g10', label: 'Gr 10'),
  (id: 'g11', label: 'Gr 11'),
  (id: 'g12', label: 'Gr 12'),
];

/// Default AY tab index for a signed-in student's own grade — the
/// equivalent of the JS's `studentAY(s)`, DELIBERATELY simplified.
///
/// The JS's version (`if(!s)return"g11";if(s.key!=="1112")return"g10";
/// return s.g==="12"?"g12":"g11";`) branches on `s.key`, a Staff-only
/// "selected class" concept (`selCls.key`) that has no equivalent in
/// this Student-only rebuild — same simplification `club_catalog.dart`'s
/// `sessionBandForGrade` already made for My Clubs' session-day band.
/// This rebuild has a real `StudentSession.grade` ('10'/'11'/'12')
/// instead, so grade alone decides the default tab directly — no
/// Staff-side key to reconstruct or fake.
int defaultAcademicYearIndexForGrade(String? grade) {
  switch (grade) {
    case '12':
      return 2;
    case '11':
      return 1;
    default:
      return 0;
  }
}