import 'package:hive_ce/hive_ce.dart';

part 'community_service_entry.g.dart';

/// Section C's repeatable row — extends the A/D/E/F template
/// (`ActivityEntry`) with a per-entry eligibility pair: `months` (spinner,
/// 0→∞ per the field/datatype doc: "Range from 0 to infinity because I
/// can input arbitrarily long numbers... uses a spinner") and `proof`
/// (a per-entry proof-letter checkbox — the behavioral spec confirms this
/// is independent per entry, "not one shared status for the whole
/// section").
///
/// `isEligible` mirrors the JS's `months>=4&&proof` exactly
/// (day5-trimmed-source.md's "Read this first" confirms this is an exact
/// match against the field/datatype doc, not a new finding) — "min 4
/// months" is purely descriptive/advisory in the original site, never
/// enforced as a submit gate, so this stays a display-only computed flag
/// here too, not a validator that blocks anything.
@HiveType(typeId: 14)
class CommunityServiceEntry {
  CommunityServiceEntry({
    this.activity,
    this.role,
    this.months = 0,
    this.proof = false,
  });

  @HiveField(0)
  String? activity;

  @HiveField(1)
  String? role;

  @HiveField(2)
  int months;

  @HiveField(3)
  bool proof;

  bool get isEligible => months >= 4 && proof;
}
