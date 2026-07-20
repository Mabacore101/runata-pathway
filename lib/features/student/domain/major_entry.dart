import 'package:hive_ce/hive_ce.dart';

part 'major_entry.g.dart';

/// One major a student has added to their Explore Majors list (Target
/// Universities, tab 1). Mirrors the JS's `s.majors[i]` shape exactly:
/// `{m, country, top, anchor}`.
///
/// `top` and `anchor` are stored per-entry, same as the source — this is
/// NOT the derived/cached value (that's `s.anchorMajor` in the JS, which
/// this port deliberately does not replicate as a stored field; see
/// `student_majors_settings.dart`'s doc comment). Each entry's own
/// `top`/`anchor` flags ARE real, persisted source-of-truth data, exactly
/// like the original.
///
/// `country` defaults to `'United States'` on add (`data-maddm` handler:
/// `{m:..., country:"United States", top:false, anchor:false}`) and is
/// read by Find Universities' anchor auto-fill (`if(am&&am.country...)`).
/// Now student-editable via a picker on Explore Majors — the trimmed
/// source's `majorPickerHTML()` excerpt didn't show that picker's markup,
/// but the same excerpt's own description text ("Add up to 6 majors with
/// a target country...") already promised it, so this closes a real gap
/// rather than adding something the original never intended.
@HiveType(typeId: 9)
class MajorEntry {
  MajorEntry({
    required this.major,
    this.country = 'United States',
    this.top = false,
    this.anchor = false,
  });

  @HiveField(0)
  String major;

  @HiveField(1)
  String country;

  @HiveField(2)
  bool top;

  @HiveField(3)
  bool anchor;
}