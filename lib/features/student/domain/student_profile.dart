import 'package:hive_ce/hive_ce.dart';

part 'student_profile.g.dart';

/// Student's Profile — Pathway form 1.
///
/// Every field is optional (per the QA'd behavioral spec: "Required: No,
/// across every field"). `dateOfBirth` is the one field with a UI-level
/// validation decision attached (planning.md §6): the field itself stays
/// optional, but if a value IS entered and it's invalid, the Day 2 form
/// must show a visible warning instead of silently discarding it the way
/// the original site does. That validation lives in the form/controller
/// layer (later in Day 2), not here — this model only needs to hold
/// `null` (nothing entered) vs. a real `DateTime` (something valid was
/// picked), since a real date-picker widget can't itself produce a
/// genuinely invalid `DateTime`.
@HiveType(typeId: 0)
class StudentProfile {
  StudentProfile({
    this.dateOfBirth,
    this.phoneNumber,
    this.address,
    this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.parentAvailableTime,
    this.siblings,
    this.allergies,
    this.regularMedicine,
    this.hospital,
    this.transportation,
    this.emergencyContact,
  });

  // General Information
  @HiveField(0)
  DateTime? dateOfBirth;

  @HiveField(1)
  String? phoneNumber;

  @HiveField(2)
  String? address;

  // Parent / Guardian
  @HiveField(3)
  String? parentName;

  @HiveField(4)
  String? parentPhone;

  @HiveField(5)
  String? parentEmail;

  @HiveField(6)
  String? parentAvailableTime;

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
  /// allowed).
  bool get hasAnyData =>
      dateOfBirth != null ||
      _hasText(phoneNumber) ||
      _hasText(address) ||
      _hasText(parentName) ||
      _hasText(parentPhone) ||
      _hasText(parentEmail) ||
      _hasText(parentAvailableTime) ||
      _hasText(siblings) ||
      _hasText(allergies) ||
      _hasText(regularMedicine) ||
      _hasText(hospital) ||
      _hasText(transportation) ||
      _hasText(emergencyContact);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
