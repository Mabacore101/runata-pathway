import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_profile_repository.dart';
import '../domain/parent_guardian_entry.dart';
import '../domain/student_profile.dart';

/// Everything the Profile screen needs to render, plus the one piece of
/// transient feedback that outlives a single build: the birth-date
/// warning. Text-field CONTENTS live in the screen's own
/// `TextEditingController`s, seeded once from [profile] when the screen
/// mounts — this state only tracks what's actually been persisted, plus
/// save-in-flight/result flags.
class ProfileControllerState {
  const ProfileControllerState({
    required this.profile,
    this.isSaving = false,
    this.justSaved = false,
    this.dateOfBirthWarning,
  });

  final StudentProfile profile;
  final bool isSaving;
  final bool justSaved;

  /// Non-null only right after a save attempt where the typed date of
  /// birth didn't parse — planning.md §6's decided fix: warn visibly
  /// instead of the original site's silent no-op. Null the rest of the
  /// time, including right after a fully successful save.
  final String? dateOfBirthWarning;

  ProfileControllerState copyWith({
    StudentProfile? profile,
    bool? isSaving,
    bool? justSaved,
    String? dateOfBirthWarning,
    bool clearWarning = false,
  }) {
    return ProfileControllerState(
      profile: profile ?? this.profile,
      isSaving: isSaving ?? this.isSaving,
      justSaved: justSaved ?? this.justSaved,
      dateOfBirthWarning:
          clearWarning ? null : (dateOfBirthWarning ?? this.dateOfBirthWarning),
    );
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileControllerState>(
  ProfileController.new,
);

class ProfileController extends Notifier<ProfileControllerState> {
  @override
  ProfileControllerState build() {
    final existing = ref.read(studentProfileRepositoryProvider).load();
    return ProfileControllerState(profile: existing);
  }

  StudentProfileRepository get _repository =>
      ref.read(studentProfileRepositoryProvider);

  /// Persists every field. [rawDateOfBirth] is the free-typed text from
  /// the date field (expected format dd/MM/yyyy — also what a successful
  /// calendar-picker selection fills in), parsed HERE in one tested place
  /// rather than in the widget layer.
  ///
  /// [parents] is passed in already-built from the screen's per-block
  /// controllers (see `ProfileScreen`) rather than as another wall of
  /// named string params — Parent/Guardian is a repeatable list now (see
  /// `ParentGuardianEntry`), so there's no fixed number of parent fields
  /// to name individually. Blank entries are NOT dropped here: the
  /// original site never removes a parent block on save either, only via
  /// its explicit delete (✕) button — that stays a UI-only action, not
  /// something save() infers from "this block happens to be empty right
  /// now".
  ///
  /// Per the flow spec's diamond, with planning.md §6's decided fix
  /// applied on top: an unparseable, non-blank date does NOT get saved
  /// and does NOT block the rest of the form — every other field saves
  /// normally, exactly like the original site — but the student now sees
  /// a clear warning instead of the change silently vanishing. A blank
  /// date field is treated as "student cleared it" and saves as null,
  /// same as any other optional field.
  Future<void> save({
    required String rawDateOfBirth,
    String? phoneNumber,
    String? address,
    required List<ParentGuardianEntry> parents,
    String? siblings,
    String? allergies,
    String? regularMedicine,
    String? hospital,
    String? transportation,
    String? emergencyContact,
  }) async {
    state = state.copyWith(isSaving: true, justSaved: false, clearWarning: true);

    final trimmedDob = rawDateOfBirth.trim();
    DateTime? dateOfBirth;
    String? warning;

    if (trimmedDob.isEmpty) {
      dateOfBirth = null;
    } else {
      final parsed = parseDateOfBirth(trimmedDob);
      if (parsed == null) {
        warning = "That date of birth doesn't look valid (expected "
            "DD/MM/YYYY), so it wasn't saved — every other field below "
            "was. Fix the date and save again to include it.";
        dateOfBirth = state.profile.dateOfBirth; // leave prior value as-is
      } else {
        dateOfBirth = parsed;
      }
    }

    final updated = StudentProfile(
      dateOfBirth: dateOfBirth,
      phoneNumber: _blankToNull(phoneNumber),
      address: _blankToNull(address),
      parents: parents.isEmpty ? [ParentGuardianEntry()] : parents,
      siblings: _blankToNull(siblings),
      allergies: _blankToNull(allergies),
      regularMedicine: _blankToNull(regularMedicine),
      hospital: _blankToNull(hospital),
      transportation: _blankToNull(transportation),
      emergencyContact: _blankToNull(emergencyContact),
    );

    await _repository.save(updated);

    state = state.copyWith(
      profile: updated,
      isSaving: false,
      justSaved: warning == null,
      dateOfBirthWarning: warning,
      clearWarning: warning == null,
    );
  }

  static String? _blankToNull(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Strict dd/MM/yyyy parse that rejects anything Dart's `DateTime`
/// constructor would otherwise silently "roll over". Dart normalizes an
/// out-of-range day/month instead of throwing — e.g. `DateTime(2026, 2,
/// 30)` quietly becomes March 2nd — which would defeat the entire point
/// of warning on an invalid date if used directly. Exposed top-level
/// (not private to [ProfileController]) so it's directly unit-testable
/// without going through the Notifier/save() flow.
DateTime? parseDateOfBirth(String raw) {
  final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw.trim());
  if (match == null) return null;

  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);

  if (month < 1 || month > 12) return null;
  if (year < 1900 || year > DateTime.now().year) return null;
  if (day < 1 || day > _daysInMonth(year, month)) return null;

  return DateTime(year, month, day);
}

int _daysInMonth(int year, int month) {
  final firstOfNextMonth =
      month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return firstOfNextMonth.subtract(const Duration(days: 1)).day;
}