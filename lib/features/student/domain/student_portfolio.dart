import 'package:hive_ce/hive_ce.dart';

import 'portfolio_work_entry.dart';

part 'student_portfolio.g.dart';

/// Portfolio — Pathway form 6b. One owning record: the works list plus a
/// single maker/artist statement textarea. Same single-owning-record
/// shape as `StudentActivitiesReport`, just with one list instead of
/// five.
///
/// The Hub's live "# Works" counter (behavioral spec: "Status shown as
/// live '# Works' counter (1 → ∞), not the binary empty/filled pattern
/// used elsewhere") reads `works.length` directly — a raw count, NOT
/// filtered by whether each entry actually has data — matching the JS's
/// `portfolioWorks[n].works.length` exactly.
@HiveType(typeId: 17)
class StudentPortfolio {
  StudentPortfolio({List<PortfolioWorkEntry>? works, this.statement})
      : works = works ?? [];

  @HiveField(0)
  List<PortfolioWorkEntry> works;

  @HiveField(1)
  String? statement;
}
