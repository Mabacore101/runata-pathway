import 'package:hive_ce/hive_ce.dart';

part 'parent_guardian_entry.g.dart';

/// One Parent/Guardian block within Student's Profile.
///
/// Neither the field/datatype doc nor the behavioral spec mentioned that
/// this section is repeatable — that only showed up in the actual site
/// JS (`day2-trimmed-source.md`'s `renderProfile()`): `P.parents` is an
/// array, seeded with exactly one blank entry by default, with an
/// "+ Add another parent/guardian" button and a per-entry delete button
/// (shown only once there's more than one entry — the first/only entry
/// can never be removed down to zero). The JS also has an `address` field
/// per parent that the field/datatype doc never listed at all.
@HiveType(typeId: 6)
class ParentGuardianEntry {
  ParentGuardianEntry({
    this.name,
    this.phone,
    this.email,
    this.availableTime,
    this.address,
  });

  @HiveField(0)
  String? name;

  @HiveField(1)
  String? phone;

  @HiveField(2)
  String? email;

  @HiveField(3)
  String? availableTime;

  @HiveField(4)
  String? address;

  /// Mirrors the JS `profFilled()`'s per-parent check: any single
  /// non-blank field counts as "this entry has data".
  bool get hasAnyData => [name, phone, email, availableTime, address]
      .any((v) => v != null && v.trim().isNotEmpty);
}
