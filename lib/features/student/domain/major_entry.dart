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
/// `{m:..., country:"United States", top:false, anchor:false}`) and has
/// no editing UI anywhere in the trimmed source's `majorPickerHTML()` or
/// click-handler block — it exists on the data shape (and is read later
/// by Find Universities' anchor auto-fill: `if(am&&am.country...)`) but
/// isn't student-editable today. Kept here for shape parity; only add a
/// picker if a later day's source reveals one.
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
