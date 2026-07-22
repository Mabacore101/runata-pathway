import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_portfolio_repository.dart';
import '../domain/student_portfolio.dart';

/// Day 5 item 1 scope: read-only exposure of the persisted portfolio,
/// just enough for the Hub's live "# Works" counter.
///
/// The real works-list add/edit/delete + maker-statement autosave logic
/// (behavioral spec: "autosaved on change" throughout, no deferred Save
/// the way Profile/Tests have) lands in item 3, as methods added to this
/// same controller — this shape doesn't change, it only grows.
final portfolioControllerProvider =
    NotifierProvider<PortfolioController, StudentPortfolio>(
  PortfolioController.new,
);

class PortfolioController extends Notifier<StudentPortfolio> {
  @override
  StudentPortfolio build() =>
      ref.read(studentPortfolioRepositoryProvider).load();
}
