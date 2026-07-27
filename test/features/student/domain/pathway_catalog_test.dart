import 'package:flutter_test/flutter_test.dart';

import 'package:runata_pathway/features/student/domain/pathway_catalog.dart';

void main() {
  group('pathwayDocs', () {
    test('has exactly Germany and China, in that order, matching '
        'PATHWAY_FALLBACK verbatim', () {
      expect(pathwayDocs, hasLength(2));
      expect(pathwayDocs[0].id, 'germany');
      expect(pathwayDocs[0].title, 'Germany Pathway');
      expect(pathwayDocs[1].id, 'china');
      expect(pathwayDocs[1].title, 'China Pathway');
    });

    test('both entries have a non-null url', () {
      for (final doc in pathwayDocs) {
        expect(doc.url, isNotNull, reason: '${doc.id} should have a url');
        expect(doc.url, isNotEmpty);
      }
    });

    test('both entries have a non-empty intro', () {
      for (final doc in pathwayDocs) {
        expect(doc.intro, isNotEmpty, reason: '${doc.id} should have an intro');
      }
    });
  });

  group('flagAssetFor', () {
    test('matches Germany case-insensitively', () {
      expect(flagAssetFor('Germany Pathway'), 'assets/images/germany.png');
      expect(flagAssetFor('GERMANY PATHWAY'), 'assets/images/germany.png');
      expect(flagAssetFor('germany pathway'), 'assets/images/germany.png');
    });

    test('matches China case-insensitively', () {
      expect(flagAssetFor('China Pathway'), 'assets/images/china.png');
      expect(flagAssetFor('CHINA PATHWAY'), 'assets/images/china.png');
    });

    test('returns null for an unrecognized country, so the screen falls '
        'back to the 🌏 emoji', () {
      expect(flagAssetFor('France Pathway'), isNull);
      expect(flagAssetFor(''), isNull);
    });
  });

  group('truncatedIntro', () {
    test('returns the full intro unchanged when at or under the limit', () {
      final intro = 'A' * 90;
      expect(truncatedIntro(intro), intro);
      expect(truncatedIntro('Short intro.'), 'Short intro.');
    });

    test('truncates to exactly 90 characters plus an ellipsis when over '
        'the limit', () {
      final intro = 'A' * 91;
      final result = truncatedIntro(intro);
      expect(result, '${'A' * 90}…');
    });

    test('falls back to "Open to read more" for an empty intro', () {
      expect(truncatedIntro(''), 'Open to read more');
    });

    test('the real Germany/China intros are both long enough to actually '
        'exercise truncation on the list cards', () {
      for (final doc in pathwayDocs) {
        expect(doc.intro.length, greaterThan(90));
        expect(truncatedIntro(doc.intro), endsWith('…'));
      }
    });
  });
}
