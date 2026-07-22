import 'package:hive_ce/hive_ce.dart';

part 'portfolio_work_entry.g.dart';

/// One work in the Portfolio's "My works" list — field/datatype doc
/// Section 5b, all optional, all unvalidated per the behavioral spec
/// ("Title: text, Type: text, Brief: textarea, Link: text — all
/// unvalidated"). `role` ("Your Role") and `year` round out the fields
/// the field/datatype doc lists for this section.
@HiveType(typeId: 16)
class PortfolioWorkEntry {
  PortfolioWorkEntry({
    this.title,
    this.type,
    this.year,
    this.role,
    this.brief,
    this.link,
  });

  @HiveField(0)
  String? title;

  @HiveField(1)
  String? type;

  @HiveField(2)
  String? year;

  @HiveField(3)
  String? role;

  @HiveField(4)
  String? brief;

  @HiveField(5)
  String? link;
}
