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

  group('neededPicksFor / scheduledSlotsFor — the Day 4 item 1 correction, '
      'now feeding item 2\'s gate', () {
    test('Grade 10 needs 2 total picks, only 1 of which schedules', () {
      expect(neededPicksFor(ClubSessionBand.grade10), 2);
      expect(scheduledSlotsFor(ClubSessionBand.grade10), 1);
    });

    test('Grades 11/12 need 3 total picks, 2 of which schedule', () {
      expect(neededPicksFor(ClubSessionBand.grade1112), 3);
      expect(scheduledSlotsFor(ClubSessionBand.grade1112), 2);
    });
  });

  group('addableClubsFor', () {
    test('excludes the required club even if it could otherwise run', () {
      final pool = addableClubsFor(
        requiredClub: 'Coding & ICT Club',
        sessionDays: sessionDaysFor(ClubSessionBand.grade10),
        alreadyRanked: const [],
      );

      expect(pool.contains('Coding & ICT Club'), isFalse);
    });

    test('excludes clubs already in the ranking', () {
      final pool = addableClubsFor(
        requiredClub: 'Coding & ICT Club',
        sessionDays: sessionDaysFor(ClubSessionBand.grade10),
        alreadyRanked: const ['Sports Club', 'Music Club'],
      );

      expect(pool.contains('Sports Club'), isFalse);
      expect(pool.contains('Music Club'), isFalse);
    });

    test('excludes a club that cannot run on any of the given session days',
        () {
      // Art & Design Studio only runs Mon/Fri — Grade 10's session days
      // are Mon/Tue, so it CAN appear; but on a hypothetical single-day
      // Wednesday-only band it shouldn't.
      final pool = addableClubsFor(
        requiredClub: null,
        sessionDays: const ['Wednesday'],
        alreadyRanked: const [],
      );

      expect(pool.contains('Art & Design Studio'), isFalse);
    });

    test('result is sorted alphabetically, matching the JS pool\'s own sort',
        () {
      final pool = addableClubsFor(
        requiredClub: null,
        sessionDays: sessionDaysFor(ClubSessionBand.grade1112),
        alreadyRanked: const [],
      );

      final sorted = [...pool]..sort();
      expect(pool, sorted);
    });
  });

  group('dayIndex / allSchoolDays', () {
    test('matches calendar order: Monday, Tuesday, Wednesday, Friday', () {
      expect(allSchoolDays, ['Monday', 'Tuesday', 'Wednesday', 'Friday']);
      expect(dayIndex('Monday'), 0);
      expect(dayIndex('Tuesday'), 1);
      expect(dayIndex('Wednesday'), 2);
      expect(dayIndex('Friday'), 3);
    });

    test('an unknown day sorts last rather than throwing', () {
      expect(dayIndex('Someday'), allSchoolDays.length);
    });
  });
}