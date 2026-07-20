import 'package:hive_ce/hive_ce.dart';

part 'university_target.g.dart';

/// One university a student has added to their shortlist for a specific
/// major, in a specific country. Mirrors one object in the JS's
/// `U.targets` array: `{major, country, uni, custom, note}`.
///
/// Follows the "flat, id-keyed list of independent rows" pattern
/// (day3-codebase-reference.md), same as [TestEntry] — NOT the
/// single-settings-record pattern [StudentMajorsSettings] uses. Each row
/// is its own Hive record, keyed by [id], rather than one record holding
/// a `List<UniversityTarget>` field. This matters here specifically
/// because rows get added/removed one at a time from several different
/// UI entry points (a catalog card's Add button, the custom-university
/// field, a "chosen" chip's ✕) — a flat box means each of those is a
/// single independent read/write, with no risk of two rapid adds
/// clobbering each other by both read-modify-writing the same list field.
///
/// `note` exists on the shape for parity with the JS, but isn't editable
/// from Find Universities — the notes textarea only appears in the JS's
/// My Shortlist tab (`uniTab==="shortlist"`), which is a later feature.
@HiveType(typeId: 11)
class UniversityTarget {
  UniversityTarget({
    required this.id,
    required this.major,
    required this.country,
    required this.university,
    this.custom = false,
    this.note,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  String major;

  @HiveField(2)
  String country;

  @HiveField(3)
  String university;

  /// True for a university the student typed in themselves (JS's
  /// `custom:true`), as opposed to one added from a curated catalog card.
  /// Drives the "yours" badge and the "no listed requirements — add
  /// requirements in Notes" fallback (My Shortlist, later).
  @HiveField(4)
  bool custom;

  @HiveField(5)
  String? note;
}

/// Always-fresh derived reads over a targets list — same "derive, don't
/// separately store and remember to clear" approach as
/// `MajorsDerived`/`majors_controller.dart`.
extension UniversityTargetsDerived on List<UniversityTarget> {
  int countForMajor(String major) => where((t) => t.major == major).length;

  List<UniversityTarget> forMajor(String major) =>
      where((t) => t.major == major).toList(growable: false);
}
