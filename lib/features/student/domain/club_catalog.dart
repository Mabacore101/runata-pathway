/// Club/major schedule data — pulled directly from the original site's JS
/// (day1-trimmed-reference.md's full STUDENT UI section), not from either
/// doc: same reasoning Day 2/3 deferred CURRICULUM/UNI_CATALOG until
/// actually needed — these are data tables, not documented behavior.
///
/// Everything in this file is genuinely portable with ZERO cross-student
/// dependency (day4-trimmed-source.md's "Read this first" #2): it only
/// answers "which days does this club run, given its subject track and
/// which teachers are qualified/available" — never how many OTHER
/// students already hold a seat. Day 4 item 3's capacity stub sits on top
/// of this later; nothing here needs to change when that stub is
/// eventually replaced with real cohort data.
library;

/// A student's grade decides which days they have club sessions on at all
/// (`SESSION_DAYS` in the JS) — Grade 10 meets 2 days/week, Grades 11/12
/// meet 3. Simplified from the JS's `effKeyOf()`, which also consulted a
/// Staff-only "selected class" dropdown (`selCls`) that has no equivalent
/// in this Student-only rebuild — grade alone decides the band here.
enum ClubSessionBand { grade10, grade1112 }

ClubSessionBand sessionBandForGrade(String grade) {
  return (grade == '11' || grade == '12')
      ? ClubSessionBand.grade1112
      : ClubSessionBand.grade10;
}

const _sessionDaysGrade10 = ['Monday', 'Tuesday'];
const _sessionDaysGrade1112 = ['Tuesday', 'Wednesday', 'Friday'];

/// Equivalent of the JS's `sdaysFor`.
List<String> sessionDaysFor(ClubSessionBand band) {
  return band == ClubSessionBand.grade1112
      ? _sessionDaysGrade1112
      : _sessionDaysGrade10;
}

/// Anchor major → required club. Verbatim from the JS's `MAJOR_CLUB`
/// object — every major in `majorCatalog` has exactly one entry here.
const majorClub = <String, String>{
  'Accounting': 'Business & Finance Club',
  'Economics': 'Business & Finance Club',
  'Entrepreneurship': 'Entrepreneurship Club',
  'Data Science': 'Math & Quant Club',
  'Computer Science': 'Coding & ICT Club',
  'Mechanical Engineering': 'Robotics & Engineering Club',
  'Civil Engineering': 'Robotics & Engineering Club',
  'Medicine': 'Pre-Med & Health Club',
  'Pharmacy': 'Pre-Med & Health Club',
  'Law': 'Debate & MUN Club',
  'International Relations': 'Debate & MUN Club',
  'Architecture': 'Architecture & Built Env Club',
  'Graphic Design': 'Art & Design Studio',
  'Communications': 'Media & Journalism Club',
  'Biology': 'Science Research Club',
  'Physics': 'Science Research Club',
  'Psychology': 'Science Research Club',
};

/// Returns the required club for a major, or `null` if unmapped. Should
/// never be null in practice once an anchor is set (every major reachable
/// via Explore Majors comes from `majorCatalog`, and every entry there has
/// a `majorClub` mapping) — but callers should treat it as nullable rather
/// than assume that invariant holds forever.
String? requiredClubFor(String major) => majorClub[major];

/// Which subject-track teachers supervise each club (`CLUB_TRACK` in the
/// JS) — determines which days a club can actually run, via [teachersOn].
const clubTrack = <String, String>{
  'Science Research Club': 'science',
  'Environmental Club': 'science',
  'Pre-Med & Health Club': 'science',
  'Business & Finance Club': 'social',
  'Entrepreneurship Club': 'social',
  'Debate & MUN Club': 'social',
  'Media & Journalism Club': 'social',
  'Math & Quant Club': 'math',
  'Coding & ICT Club': 'ict',
  'Robotics & Engineering Club': 'eng',
  'Language & Literature Club': 'eng',
  'Art & Design Studio': 'art',
  'Architecture & Built Env Club': 'art',
  'Music Club': 'music',
  'Sports Club': 'sport',
};

class _Teacher {
  const _Teacher(this.name, this.days);
  final String name;
  final List<String> days;
}

const _allDays = ['Monday', 'Tuesday', 'Wednesday', 'Friday'];

/// Which teachers are qualified for each subject track, and which days
/// they're on campus (`TEACHERS` in the JS) — the static schedule table
/// clash-detection is built on.
const Map<String, List<_Teacher>> _teachers = {
  'science': [_Teacher('Ms Gabi', _allDays), _Teacher('Ms Hertin', _allDays)],
  'social': [
    _Teacher('Mr Ghatra', _allDays),
    _Teacher('Mr Yoel', ['Tuesday', 'Wednesday', 'Friday']),
    _Teacher('Ms Sunia', _allDays),
  ],
  'math': [_Teacher('Ms Erni', _allDays)],
  'ict': [_Teacher('Mr Eric', _allDays)],
  'eng': [_Teacher('Mr Buchman', _allDays), _Teacher('Mr Adri', ['Tuesday'])],
  'art': [_Teacher('Ms Audrey', ['Monday', 'Friday'])],
  'music': [_Teacher('Mr Hans', _allDays)],
  'sport': [_Teacher('Ms Aswin', _allDays)],
  'bahasa': [_Teacher('Ms Desy', ['Tuesday', 'Wednesday'])],
};

/// Teachers qualified for [track] who are on campus on [day].
List<String> teachersOn(String? track, String day) {
  if (track == null) return const [];
  final onTrack = _teachers[track] ?? const [];
  return [for (final t in onTrack) if (t.days.contains(day)) t.name];
}

/// Which of [sessionDays] a club actually runs on — a day only counts if
/// at least one teacher qualified for the club's track is available.
/// Fully real today, nothing stubbed (see file doc comment).
List<String> clubDays(String club, List<String> sessionDays) {
  final track = clubTrack[club];
  return sessionDays.where((day) => teachersOn(track, day).isNotEmpty).toList();
}

/// Short "Mon, Tue" style label, or "n/a" if the club can't run on any of
/// the student's session days.
String daysLabel(String club, List<String> sessionDays) {
  final days = clubDays(club, sessionDays);
  if (days.isEmpty) return 'n/a';
  return days.map((d) => d.substring(0, 3)).join(', ');
}