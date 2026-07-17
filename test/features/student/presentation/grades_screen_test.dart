import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runata_pathway/features/student/presentation/grades_screen.dart';

/// Runs a formatter against a single new input string starting from an
/// empty field — enough to test character-filtering behavior without
/// needing to simulate a real edit sequence.
String _format(String input) {
  return gradeScoreInputFormatter
      .formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: input, selection: TextSelection.collapsed(offset: input.length)),
      )
      .text;
}

void main() {
  group('gradeScoreInputFormatter', () {
    test('allows plain digits through unchanged', () {
      expect(_format('88'), '88');
      expect(_format('0'), '0');
    });

    test(
        'strips a minus sign entirely — a negative score cannot be typed '
        'at all (deliberate deviation from the spec\'s literal "<0 '
        'accepted" wording — see grades_screen.dart\'s _GradeScoreField '
        'doc comment)', () {
      expect(_format('-5'), '5');
      expect(_format('-'), '');
    });

    test(
        'does NOT restrict the upper bound — a value over 100 passes '
        'straight through unfiltered, since that half of the clamp-bypass '
        'bug is still knowingly kept', () {
      expect(_format('137'), '137');
      expect(_format('9999'), '9999');
    });

    test('strips letters, symbols, and decimal points', () {
      expect(_format('8a8'), '88');
      expect(_format('88.5'), '885'); // decimal point stripped, not just digits kept apart
      expect(_format('abc'), '');
      expect(_format('88%'), '88');
    });
  });

  group('clampedSpinnerStep', () {
    test('increments within range normally', () {
      expect(clampedSpinnerStep('50', 1), 51.0);
      expect(clampedSpinnerStep('50', 10), 60.0);
    });

    test('decrements within range normally', () {
      expect(clampedSpinnerStep('50', -1), 49.0);
    });

    test('cannot go below 0', () {
      expect(clampedSpinnerStep('0', -1), 0.0);
      expect(clampedSpinnerStep('2', -10), 0.0);
    });

    test('cannot exceed 100', () {
      expect(clampedSpinnerStep('95', 10), 100.0);
      expect(clampedSpinnerStep('100', 1), 100.0);
    });

    test(
        'a single tap from an already out-of-range value (only reachable '
        'by manually typing >100 first) snaps straight to the clamp, not '
        'a small step off the bogus base — matches the spec\'s "cannot '
        'exceed" wording applying to the RESULT, not an increment from an '
        'already-invalid starting point', () {
      expect(clampedSpinnerStep('137', -1), 100.0); // not 136
      expect(clampedSpinnerStep('137', 1), 100.0); // stays clamped, not 138
    });

    test('blank or unparseable text is treated as starting from 0', () {
      expect(clampedSpinnerStep('', 1), 1.0);
      expect(clampedSpinnerStep('not a number', 1), 1.0);
    });
  });
}
