import 'package:hive_ce/hive_ce.dart';

import 'parent_guardian_entry.dart';

part 'student_profile.g.dart';

/// Student's Profile — Pathway form 1.
///
/// Every field is optional (per the QA'd behavioral spec: "Required: No,
/// across every field"). `dateOfBirth` is the one field with a UI-level
/// validation decision attached (planning.md §6): the field itself stays
/// optional, but if a value IS entered and it's invalid, the form shows a
/// visible warning instead of silently discarding it the way the original
/// site does. That validation lives in `ProfileController`, not here —
/// this model only needs to hold `null` (nothing entered) vs. a real
/// `DateTime` (something valid was picked/typed).
///
/// `parents` was reshaped from 4 flat fields (parentName/Phone/Email/
/// AvailableTime) to a `List<ParentGuardianEntry>` after reading the
/// actual site JS (`day2-trimmed-source.md`) — Parent/Guardian is
/// genuinely repeatable there (an "+ Add another parent/guardian"
/// button), which neither the field/datatype doc nor the behavioral spec
/// had mentioned. Always has at least one entry (seeded blank by
/// default), matching the JS's `prof()` factory.
@HiveType(typeId: 0)
class StudentProfile {
  StudentProfile({
    this.dateOfBirth,
    this.phoneNumber,
    this.address,
    List<ParentGuardianEntry>? parents,
    this.siblings,
    this.allergies,
    this.regularMedicine,
    this.hospital,
    this.transportation,
    this.emergencyContact,
  }) : parents = parents ?? [ParentGuardianEntry()];

  // General Information
  @HiveField(0)
  DateTime? dateOfBirth;

  @HiveField(1)
  String? phoneNumber;

  @HiveField(2)
  String? address;

  // Fields 3, 4, 5, 6 are PERMANENTLY RETIRED — they used to be the flat
  // parentName/parentPhone/parentEmail/parentAvailableTime fields before
  // Parent/Guardian became a repeatable list. Never reassign these
  // indices to something new: Hive persists by field index, and this app
  // has already had at least one dev build write real Hive bytes tagged
  // with these indices as plain Strings. Re-using an old index for a
  // differently-typed field risks a cast crash reading old data; an
  // unused index just gets silently ignored on read, which is safe.

  /// See [ParentGuardianEntry] — deliberately given a fresh field index
  /// (13, not one of the retired 3-6) for the same reason: any Hive data
  /// already written under the old flat fields has nothing at index 13,
  /// so it reads back as absent/null there rather than crashing on a type
  /// mismatch.
  @HiveField(13)
  List<ParentGuardianEntry> parents;

  // Siblings
  @HiveField(7)
  String? siblings;

  // Medical Information
  @HiveField(8)
  String? allergies;

  @HiveField(9)
  String? regularMedicine;

  @HiveField(10)
  String? hospital;

  // Transportation
  @HiveField(11)
  String? transportation;

  // Emergency Contact
  @HiveField(12)
  String? emergencyContact;

  /// True once at least one field has ever been filled in — drives the
  /// binary Empty/Has-Data status used by the Homepage checkmark and Nav
  /// Grid subtitle (per the spec's "Status model" note: binary only, no
  /// in-progress tri-state exists anywhere despite partial-save being
  /// allowed). Mirrors the JS `profFilled()`: base fields OR any single
  /// parent entry having any data.
  bool get hasAnyData =>
      dateOfBirth != null ||
      _hasText(phoneNumber) ||
      _hasText(address) ||
      parents.any((p) => p.hasAnyData) ||
      _hasText(siblings) ||
      _hasText(allergies) ||
      _hasText(regularMedicine) ||
      _hasText(hospital) ||
      _hasText(transportation) ||
      _hasText(emergencyContact);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}