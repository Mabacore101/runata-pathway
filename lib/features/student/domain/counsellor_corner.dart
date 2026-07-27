import 'package:hive_ce/hive_ce.dart';

part 'counsellor_corner.g.dart';

/// Options for the 3 "who" dropdowns (`addressedBy`/`talksWith`/
/// `eduAdult`) — mirrors the JS's `cwho()` options array exactly,
/// including the leading `''` "not yet answered" option (shown as
/// "— select —" by the screen, not stored as a real answer — `'None'`
/// IS a real, meaningful answer here, distinct from `''`).
const familyAddresserOptions = ['', 'Father', 'Mother', 'Both', 'None', 'Other'];

/// Options for `hadTherapy` — mirrors the JS's inline Yes/No `<select>`
/// exactly, same leading `''` "not yet answered" convention as
/// [familyAddresserOptions].
const therapyOptions = ['', 'Yes', 'No'];

/// Counsellor's Corner — family + education background, shared with the
/// Academic Advisor/Coordinator. Mirrors the JS's `counsel[name]` object
/// exactly: one flat record of 24 String fields, all defaulting to `''`
/// — never `null` — matching `counsel[name]={...:"",...}`'s initializer.
/// No nested lists/maps, and — confirmed by tracing `cns()`/`ctext()`/
/// `cwho()`/`renderCounsel()` — no AY-tab scoping at all, unlike Day 6's
/// essay docs; this is one record per student, full stop.
///
/// **Storage — single-record box**, same pattern as [StudentProfile]/
/// [StudentClubSelection]: one [CounsellorCorner] per student under a
/// fixed key, not a flat/id-keyed collection — there's only ever one of
/// these per student, never a natural list of them.
///
/// **Genuinely autosaves on every change** — the JS's own on-screen copy
/// says so explicitly ("It saves automatically"), and tracing the actual
/// `data-cns` handlers confirms it: every field (textareas on `'input'`,
/// the 3 "who" dropdowns + the Yes/No dropdown on `'change'`) mutates
/// `counsel[name]` immediately. The 3 "who" dropdowns additionally force
/// a re-render (`/addressedBy|talksWith|eduAdult/.test(...)`) to reveal
/// or hide the "Other" field; `hadTherapy`'s Yes/No dropdown deliberately
/// does not, since nothing on screen conditionally depends on it. Same
/// "Save button is cosmetic" shape as `StudentPortfolio`, not the
/// deferred-until-Save shape `StudentActivitiesReport` uses.
@HiveType(typeId: 20)
class CounsellorCorner {
  CounsellorCorner({
    this.qualityTime = '',
    this.enjoyMost = '',
    this.enjoyLeast = '',
    this.routines = '',
    this.rules = '',
    this.consequence = '',
    this.addressedBy = '',
    this.addressedOther = '',
    this.flexible = '',
    this.disagreement = '',
    this.expressUpset = '',
    this.talksWith = '',
    this.talksOther = '',
    this.calmHow = '',
    this.eduAdult = '',
    this.eduAdultOther = '',
    this.famOther = '',
    this.prevSchools = '',
    this.achievements = '',
    this.neededSupport = '',
    this.hadTherapy = '',
    this.currentTherapy = '',
    this.recentHighlight = '',
    this.runataNotes = '',
  });

  // ---- Student's family background ----
  @HiveField(0)
  String qualityTime;
  @HiveField(1)
  String enjoyMost;
  @HiveField(2)
  String enjoyLeast;
  @HiveField(3)
  String routines;
  @HiveField(4)
  String rules;
  @HiveField(5)
  String consequence;

  /// One of [familyAddresserOptions] (`''` = not yet answered).
  @HiveField(6)
  String addressedBy;

  /// Only meaningful when [addressedBy] == `'Other'`.
  @HiveField(7)
  String addressedOther;

  @HiveField(8)
  String flexible;
  @HiveField(9)
  String disagreement;
  @HiveField(10)
  String expressUpset;

  /// One of [familyAddresserOptions] (`''` = not yet answered).
  @HiveField(11)
  String talksWith;

  /// Only meaningful when [talksWith] == `'Other'`.
  @HiveField(12)
  String talksOther;

  @HiveField(13)
  String calmHow;

  /// One of [familyAddresserOptions] (`''` = not yet answered).
  @HiveField(14)
  String eduAdult;

  /// Only meaningful when [eduAdult] == `'Other'`.
  @HiveField(15)
  String eduAdultOther;

  @HiveField(16)
  String famOther;

  // ---- Student's education background ----
  @HiveField(17)
  String prevSchools;
  @HiveField(18)
  String achievements;
  @HiveField(19)
  String neededSupport;

  /// One of [therapyOptions] (`''` = not yet answered).
  @HiveField(20)
  String hadTherapy;

  @HiveField(21)
  String currentTherapy;
  @HiveField(22)
  String recentHighlight;
  @HiveField(23)
  String runataNotes;

  /// `cnsFilled(name)` equivalent — true if ANY field has non-blank
  /// text. Not wired to anything yet this session (a future Dashboard/
  /// Nav-Grid "done" indicator would read this), but kept here now so
  /// that wiring doesn't require touching this model's shape later.
  bool get hasAnyData => [
        qualityTime, enjoyMost, enjoyLeast, routines, rules, consequence,
        addressedBy, addressedOther, flexible, disagreement, expressUpset,
        talksWith, talksOther, calmHow, eduAdult, eduAdultOther, famOther,
        prevSchools, achievements, neededSupport, hadTherapy, currentTherapy,
        recentHighlight, runataNotes,
      ].any((v) => v.trim().isNotEmpty);

  /// Standard `copyWith` — every field defaults to "keep the current
  /// value" via `?? this.field`, so a caller only ever needs to name the
  /// one field it's changing. Passing an explicit `''` still correctly
  /// clears a field (rather than being treated as "not provided"), since
  /// only an actual `null` (an un-passed argument) falls back to `this`.
  CounsellorCorner copyWith({
    String? qualityTime,
    String? enjoyMost,
    String? enjoyLeast,
    String? routines,
    String? rules,
    String? consequence,
    String? addressedBy,
    String? addressedOther,
    String? flexible,
    String? disagreement,
    String? expressUpset,
    String? talksWith,
    String? talksOther,
    String? calmHow,
    String? eduAdult,
    String? eduAdultOther,
    String? famOther,
    String? prevSchools,
    String? achievements,
    String? neededSupport,
    String? hadTherapy,
    String? currentTherapy,
    String? recentHighlight,
    String? runataNotes,
  }) {
    return CounsellorCorner(
      qualityTime: qualityTime ?? this.qualityTime,
      enjoyMost: enjoyMost ?? this.enjoyMost,
      enjoyLeast: enjoyLeast ?? this.enjoyLeast,
      routines: routines ?? this.routines,
      rules: rules ?? this.rules,
      consequence: consequence ?? this.consequence,
      addressedBy: addressedBy ?? this.addressedBy,
      addressedOther: addressedOther ?? this.addressedOther,
      flexible: flexible ?? this.flexible,
      disagreement: disagreement ?? this.disagreement,
      expressUpset: expressUpset ?? this.expressUpset,
      talksWith: talksWith ?? this.talksWith,
      talksOther: talksOther ?? this.talksOther,
      calmHow: calmHow ?? this.calmHow,
      eduAdult: eduAdult ?? this.eduAdult,
      eduAdultOther: eduAdultOther ?? this.eduAdultOther,
      famOther: famOther ?? this.famOther,
      prevSchools: prevSchools ?? this.prevSchools,
      achievements: achievements ?? this.achievements,
      neededSupport: neededSupport ?? this.neededSupport,
      hadTherapy: hadTherapy ?? this.hadTherapy,
      currentTherapy: currentTherapy ?? this.currentTherapy,
      recentHighlight: recentHighlight ?? this.recentHighlight,
      runataNotes: runataNotes ?? this.runataNotes,
    );
  }
}
