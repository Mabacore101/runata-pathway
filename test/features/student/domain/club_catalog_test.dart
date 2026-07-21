import 'package:flutter_test/flutter_test.dart';
import 'package:runata_pathway/features/student/domain/club_catalog.dart';

void main() {
  group('requiredClubFor', () {
    test(
        'maps catalog majors to their club, verbatim from the JS MAJOR_CLUB table',
        () {
      expect(requiredClubFor('Computer Science'), 'Coding & ICT Club');
      expect(requiredClubFor('Biology'), 'Science Research Club');
      expect(requiredClubFor('Graphic Design'), 'Art & Design Studio');
    });

    test('returns null for a major with no mapping', () {
      expect(requiredClubFor('Not A Real Major'), isNull);
    });
  });

  group('sessionBandForGrade / sessionDaysFor', () {
    test('grade 10 gets the 2-day band', () {
      expect(sessionBandForGrade('10'), ClubSessionBand.grade10);
      expect(sessionDaysFor(ClubSessionBand.grade10), ['Monday', 'Tuesday']);
    });

    test('grades 11 and 12 both get the 3-day band', () {
      expect(sessionBandForGrade('11'), ClubSessionBand.grade1112);
      expect(sessionBandForGrade('12'), ClubSessionBand.grade1112);
      expect(sessionDaysFor(ClubSessionBand.grade1112),
          ['Tuesday', 'Wednesday', 'Friday']);
    });
  });

  group('daysLabel — real clash-detection logic (zero cross-student dependency)', () {
    test('a club with an always-available teacher runs every session day', () {
      // Coding & ICT Club -> ict track -> Mr Eric, available every day.
      expect(
          daysLabel('Coding & ICT Club', sessionDaysFor(ClubSessionBand.grade10)),
          'Mon, Tue');
      expect(
          daysLabel(
              'Coding & ICT Club', sessionDaysFor(ClubSessionBand.grade1112)),
          'Tue, Wed, Fri');
    });

    test('a club with a partially-available teacher only shows real days', () {
      // Art & Design Studio -> art track -> Ms Audrey, Mon & Fri only.
      expect(
          daysLabel(
              'Art & Design Studio', sessionDaysFor(ClubSessionBand.grade10)),
          'Mon'); // Tuesday isn't one of Ms Audrey's days
      expect(
          daysLabel(
              'Art & Design Studio', sessionDaysFor(ClubSessionBand.grade1112)),
          'Fri'); // only Friday overlaps
    });

    test("a club that can't run on any of the student's days shows 'n/a'", () {
      expect(daysLabel('Nonexistent Club', ['Monday']), 'n/a');
    });
  });
}
