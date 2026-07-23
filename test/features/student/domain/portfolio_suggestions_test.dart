import 'package:flutter_test/flutter_test.dart';

import 'package:runata_pathway/features/student/domain/majors_catalog.dart';
import 'package:runata_pathway/features/student/domain/portfolio_suggestions.dart';

void main() {
  test('every field value in majorCatalog has a matching suggestion — a typo '
      'here would silently drop the suggestion banner for real majors',
      () {
    final catalogFields = majorCatalog.map((m) => m.field).toSet();

    for (final field in catalogFields) {
      expect(
        portfolioFieldSuggestions.containsKey(field),
        isTrue,
        reason: 'majors_catalog.dart has field "$field" but '
            'portfolioFieldSuggestions has no entry for it',
      );
    }
  });

  test('portfolioFieldSuggestions has no stray keys that don\'t match any '
      'real field', () {
    final catalogFields = majorCatalog.map((m) => m.field).toSet();

    for (final key in portfolioFieldSuggestions.keys) {
      expect(
        catalogFields.contains(key),
        isTrue,
        reason: 'portfolioFieldSuggestions has key "$key" that no major in '
            'majorCatalog actually uses',
      );
    }
  });

  test('portfolioSuitabilityTable has all 5 rows from the original site',
      () {
    expect(portfolioSuitabilityTable, hasLength(5));
  });
}
