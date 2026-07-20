import 'package:hive_ce/hive_ce.dart';

import 'major_entry.dart';

part 'student_majors_settings.g.dart';

/// Single settings record for Explore Majors — one per student, same
/// fixed-key-in-a-single-record-box pattern as [StudentGradesSettings].
///
/// Deliberately holds ONLY the list. The JS's `s.anchorMajor`/`s.top3`/
/// `s.ranked` are `persistMajors()`'s cached-but-always-recomputed
/// convenience fields — day3-trimmed-source.md flags this explicitly as
/// the design lesson to carry over: the original's robustness against
/// the delete-a-major cascade bug comes entirely from anchor state never
/// being independently stored, only ever derived by re-scanning
/// `s.majors`. Storing an equivalent `anchorMajor` field here would
/// reintroduce exactly the bug class that design avoids (a cache that
/// must be remembered to clear at every mutation site). So: no
/// `anchorMajor`/`top3`/`ranked` fields on this class — see
/// `majors_controller.dart`'s `MajorsDerived` extension for the
/// equivalent always-fresh getters instead.
@HiveType(typeId: 10)
class StudentMajorsSettings {
  StudentMajorsSettings({List<MajorEntry>? majors}) : majors = majors ?? [];

  @HiveField(0)
  List<MajorEntry> majors;
}
