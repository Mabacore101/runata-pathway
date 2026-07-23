import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/student_portfolio_repository.dart';
import '../domain/portfolio_work_entry.dart';
import '../domain/student_portfolio.dart';

/// Day 5 item 3: full read/write controller.
///
/// **Everything here autosaves on change — there is no deferred-Save
/// split the way Activities Report has.** The behavioral spec calls
/// this out explicitly and specifically for Portfolio ("autosaved on
/// change… even if navigating away without clicking Save; this autosave
/// behavior is scoped to Portfolio specifically, not verified
/// elsewhere") — unlike Activities Report, where tracing the JS showed
/// the "Save" button was actually a generic, unrelated flush action, the
/// spec here draws a real, deliberate line specifically around this
/// screen. [updateAll] is called on every keystroke anywhere on the
/// Portfolio screen (a work's fields or the maker statement), not
/// batched — the on-screen "Save" button that ships with the screen is
/// genuinely cosmetic here, same reassurance-only pattern already used
/// for Target Universities' Save button.
final portfolioControllerProvider =
    NotifierProvider<PortfolioController, StudentPortfolio>(
  PortfolioController.new,
);

class PortfolioController extends Notifier<StudentPortfolio> {
  @override
  StudentPortfolio build() =>
      ref.read(studentPortfolioRepositoryProvider).load();

  StudentPortfolioRepository get _repository =>
      ref.read(studentPortfolioRepositoryProvider);

  /// Mirrors the JS's `data-pwadd` handler: appends a blank work, no cap,
  /// persisted immediately — same immediate-add shape as every other
  /// repeatable list in this app.
  Future<void> addWork() async {
    await _persist(
      StudentPortfolio(works: [...state.works, PortfolioWorkEntry()], statement: state.statement),
    );
  }

  /// Mirrors `data-pwdel`: splice the work out by index and persist
  /// immediately. Out-of-range indices are a no-op, same defensive
  /// posture as every other delete-by-index method in this app.
  Future<void> deleteWork(int index) async {
    if (index < 0 || index >= state.works.length) return;
    final works = [...state.works]..removeAt(index);
    await _persist(StudentPortfolio(works: works, statement: state.statement));
  }

  /// Persists the entire current portfolio — every work's fields plus
  /// the maker statement — in one write. Called on every change
  /// anywhere on the screen (see this file's doc comment for why that's
  /// correct here specifically). [updated] is built fresh from the
  /// screen's local `TextEditingController`s each time it's called; this
  /// only overwrites field VALUES, it doesn't add/remove works itself.
  Future<void> updateAll(StudentPortfolio updated) async {
    await _persist(updated);
  }

  Future<void> _persist(StudentPortfolio updated) async {
    await _repository.save(updated);
    state = updated;
  }
}