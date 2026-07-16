import 'package:hive_ce/hive_ce.dart';

part 'test_entry.g.dart';

/// Test types shown as "+ [Test Type]" buttons on My Tests (Pathway form
/// 3). Order matches the behavioral spec's button order.
///
/// Field indices below are fixed once shipped — Hive persists enums by
/// their declared @HiveField index, not by name, so a new type must always
/// be appended at the END with the next free index. Never reorder or
/// renumber existing entries; doing so silently corrupts already-saved
/// rows on-device.
@HiveType(typeId: 2)
enum TestType {
  @HiveField(0)
  ielts,
  @HiveField(1)
  toefl,
  @HiveField(2)
  duolingo,
  @HiveField(3)
  sat,
  @HiveField(4)
  csca,
  @HiveField(5)
  hsk,
  @HiveField(6)
  ap,
  @HiveField(7)
  other,
}

/// AP and Other are the two types the flow spec explicitly exempts from
/// duplicate-blocking ("Is Test Type AP or Other? → Yes → New Test Row
/// Created, duplicates allowed, no check needed"). Every other [TestType]
/// blocks a second row of the same type ("Test Type Already Added? → Yes
/// → Button disabled — no duplicate rows"). Kept as one named set here
/// rather than an inline `== TestType.ap || == TestType.other` check
/// repeated at every call site, so the rule has exactly one place to
/// update if the spec is ever revised.
const Set<TestType> duplicateAllowedTestTypes = {TestType.ap, TestType.other};

/// Status dropdown on each My Tests row. Field/datatype doc: "Options:
/// Planned, Registered & Taken. Note: The default value is planed [sic]"
/// — [TestStatus.planned] must stay first/default.
@HiveType(typeId: 3)
enum TestStatus {
  @HiveField(0)
  planned,
  @HiveField(1)
  registered,
  @HiveField(2)
  taken,
}

/// One row on My Tests. `id` is a locally-generated identifier (no
/// backend exists yet to assign one) used for delete/edit targeting and,
/// combined with [type], for the "Test Type Already Added?" duplicate
/// check.
///
/// `target`, `latest`, and `date` are all `String?`/freeform text per the
/// field/datatype doc — `date` in particular is deliberately a plain
/// String, not a `DateTime`, unlike Student's Profile's real date-of-birth
/// picker.
@HiveType(typeId: 1)
class TestEntry {
  TestEntry({
    required this.id,
    required this.type,
    this.target,
    this.latest,
    this.status = TestStatus.planned,
    this.date,
  });

  @HiveField(0)
  String id;

  @HiveField(1)
  TestType type;

  @HiveField(2)
  String? target;

  @HiveField(3)
  String? latest;

  @HiveField(4)
  TestStatus status;

  @HiveField(5)
  String? date;
}
