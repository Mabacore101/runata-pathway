# Runata Pathway (Flutter)

A native iOS/Android rebuild of **Runata Pathway**, a school "Club &
University Pathway" portal for Runata Global School. The original is a
single-page web app with three roles — Student, Parent, Staff — all sharing
one HTML file with visibility toggled by JS state. This rebuild replaces
that with a real Flutter app and proper structural separation between roles.

## Status

🚧 In active development. **Student role is the only committed scope** for
the initial build; Parent and Staff are stretch goals pending behavioral QA
on those roles.

- [x] Day 0 — Foundation (dependencies, folder skeleton, data models, routing skeleton)
- [x] Day 1 — Choose Role, Student Login, Homepage, sign-out
- [x] Day 2 — Student's Profile, My Tests, My Grades
- [x] Day 3 — Target Universities
- [x] Day 4 — My Clubs
- [x] Day 5 — Application Materials (part 1)
- [ ] Day 6 — Application Materials (part 2) + remaining pieces
- [ ] Day 7 — Integration, polish, device pass

## Roles

The sign-in menu shows 5 buttons (Student / Parent / Teacher / School
Counsellor / Coordinator), but these map to only **3 architectural roles**.
Teacher, Counsellor, and Coordinator are permission variants of one **Staff**
role — they share a login flow in the original site and differ only in
what they can see once inside. Folder structure reflects this:

```
lib/features/
  student/
  parent/
  staff/
```

## Tech stack

| Concern | Choice |
|---|---|
| State management | Riverpod (`flutter_riverpod`) |
| Routing | go_router, with a redirect guard for the signed-in/out student area |
| Local storage | Hive CE (`hive_ce` / `hive_ce_flutter`) — flexible objects/lists (profile, tests, grades), not relational. Swapped in from the original `hive`/`hive_flutter` packages during Day 2 after finding those unmaintained and incompatible with a current `build_runner` |
| Code generation | `build_runner` + `hive_ce_generator` — generates Hive TypeAdapters (`*.g.dart`) and the adapter registrar (`lib/hive_registrar.g.dart`); both are checked into version control per Hive CE's own convention, not hand-edited |
| Backend | Local-only for now — no Supabase project connected yet |
| Testing | `flutter_test` + `mocktail` + `hive_ce_test` |

## Getting started

```bash
flutter pub get
flutter run
```

Requires a connected device or emulator with USB debugging enabled. iOS is
written to be correct but hasn't been verified on a physical device yet (no
Mac access during initial development).

Generated Hive files are already checked in, so a fresh clone doesn't need
anything beyond the above. If you add or change a `@HiveType` model
(anything under `lib/features/*/domain/`), regenerate them:

```bash
dart run build_runner build
```

### Test login

There's no live backend yet, so sign-in checks against a small seeded
roster in `LocalStudentAuthRepository` rather than a real account system:

| Student ID | Password | Grade |
|---|---|---|
| `2627001` | `2627001` | 10 |
| `2627002` | `2627002` | 12 |

(Password defaults to the Student ID, mirroring the original site's own
convention for first-time sign-in.) The two seed accounts deliberately span
both My Clubs session-day bands (Grade 10: 2 days/week; Grades 11/12: 3
days/week) so both grade-dependent pick counts are reachable by signing in
during dev, not just unit-testable in isolation. See "Known limitations"
below for a real caveat when switching between them on one device.

## Running tests

```bash
flutter test
```

Covers: sign-in success/failure paths, the single generic-error-bucket
guarantee (wrong password and unknown Student ID surface the *same*
message — the login form never says which part was wrong), sign-out, and
route guards in both directions — including auth state changing with no
navigation call attached (e.g. a restored session), which is why the router
has a `refreshListenable` wired to auth state rather than relying only on
explicit navigation to trigger its guard.

Day 2 adds: Student's Profile (Hive round-trips, birth-date parsing and the
visible-warning validation, the repeatable Parent/Guardian list), My Tests
(add/delete/save, the test-type duplicate-block guard), and My Grades
(semester average calculation — including the score clamp-bypass bug case —
progress/feedback trend logic, and the score field's input-filtering/clamp
behavior).

Day 3 adds: Target Universities, built as three tabs on one screen
(Explore Majors / Find Universities / My Shortlist) rather than three
separate pages, matching the original site's single-function-with-tabs
structure. Explore Majors covers add/remove/Top-3/anchor rules (max 6
majors, max 3 Top, exactly 1 anchor, anchor only settable on an
already-Top major) and the per-major country picker. Find Universities
covers the field-matching filter, the per-major shortlist cap and
duplicate guard, and the IELTS fit-status chip — which reads the
student's *actual* My Tests IELTS score rather than a separate stored
value. My Shortlist covers anchor-first sort order, ANCHOR/YOURS tagging,
delete, and notes persisting on focus-loss rather than per keystroke.

A dedicated cascade pass — deliberately built and tested last, on top of
an already-verified Explore Majors/Find Universities/My Shortlist, so any
cascade bug would be unambiguous — covers all four cross-tab interactions:
deleting a major cleans up its shortlisted universities everywhere (a
real bug found via manual QA, not planned upfront — see deviation below);
un-Top-marking a major (not deleting it) deliberately does *not* cascade;
changing the anchor mid-session updates Find Universities' default
major/country and re-sorts My Shortlist, both confirmed end-to-end rather
than just reasoned about; and changing a major's country leaves its
existing shortlist untouched under the old country, with the per-major
cap still correctly global across countries afterward.

Day 4 adds: My Clubs. Required-club display, derived live from the anchor
major (never cached — an in-screen "choose your anchor first" prompt
covers the not-set case, not a router redirect). Rank Other Clubs' pick
count, add/remove/reorder, and the "Generate my week" gate. The
Preview/Confirm week-scheduling algorithm — real, per-student
clash-detection in full (a student can't be scheduled into two clubs on
the same day), with cross-student capacity isolated behind one injectable
seam rather than implemented, since no backend exists yet to check a
club's seat count against other students' committed schedules. Full
submit + re-entry: real Hive persistence, a read-only "Your Current
Schedule" summary on return visits, and "Make Changes" pre-filling prior
picks — covered by a dedicated full round-trip test (submit → success
card → leave → re-enter → Make Changes → prior picks intact, in order),
not just the individual pieces in isolation.

A dedicated cascade pass, same reasoning as Day 3's: changing the anchor
major elsewhere in the app now reactively strips a ranked club the
instant it becomes the new required club — without needing to leave and
re-enter My Clubs — with a matching guard so an already-open preview
can't be submitted if that cascade shrinks it below the needed count.
A staleness banner on "Your Current Schedule" flags when the frozen
submission has drifted from the live anchor, compared by resolved club
rather than raw major name so two majors that happen to share a club
(e.g. Accounting/Economics, both → Business & Finance Club) don't
trigger a false positive.

Day 5 adds: the Application Materials hub (grade-level tabs over all 8
Pathway document rows, 2 of which route to real content today, the
other 6 visibly present but inert pending Day 6), Student Activities
Report, and Portfolio. Activities Report covers sections A/C/D/E/F as
repeatable rows (add/delete immediate, field edits batched via Save —
confirmed against the actual JS handlers, not assumed) and Section B's
live wiring to Day 4's week-preview algorithm against the student's
submitted club selection — recomputed on every visit, not cached, so
resubmitting clubs elsewhere in the app reflects here without a
restart. Portfolio covers the works list and maker statement, both
autosave-on-change per the behavioral spec's explicit note for this
screen specifically, the major-based suggestion banner, and the
suitability table + explainer (previously dead code in the original
site, surfaced properly here — see deviation below).

## Known bugs carried over from the original site

The live site has a handful of quirks. Default stance is **replicate for
now, track as a backlog item** rather than silently fixing — avoids
undocumented scope creep against the behavioral spec. Confirm/revisit before
the relevant day's work:

- My Grades — manually-typed scores above 100 aren't clamped, corrupting
  the average calculation (upper bound only — see deviation below for the
  lower bound)
- Application Materials (essay sections) — "Mark as Ready" only checks for
  non-empty text, not actual criteria

## Known limitations of this rebuild

Not bugs carried over from the original, and not deviations either —
architectural simplifications made along the way, worth revisiting rather
than fixed now:

- **One global Hive record per data type, not per-student.** Every box
  (Profile, Grades, Majors, University Targets, Clubs, Activities Report,
  Portfolio) is opened once at app startup under a single fixed key —
  nothing in the storage layer is keyed by `studentId`. Reasonable under
  the real single-device-per-student
  assumption the original site also makes (a student never signs in as
  someone else on their own phone), but it means switching between the
  two seeded test accounts on ONE dev device doesn't give a clean slate —
  signing out and back in as the other account still reads the first
  account's data. To manually verify per-account differences (e.g. My
  Clubs' grade bands), clear app storage between account switches rather
  than just signing out and back in. A real fix means keying every
  box/record by `studentId`, touching every repository built so far — a
  foundational change, not a My Clubs–scoped one.

### Deliberate deviations from the original site (Day 2)

Two spots where Day 2 intentionally diverged from a literal 1:1
replication, both decided and documented in planning.md §6 rather than left
as silent differences:

- **Student's Profile — invalid birth date.** The original site fails
  silently (no error shown) on a forced/invalid value. This rebuild shows a
  direct, visible warning instead and doesn't save that field until it's
  corrected — every other field on the form still saves normally.
- **My Grades — negative scores.** The behavioral spec documents the
  clamp-bypass bug as accepting *any* out-of-range manual input, including
  negative values. This rebuild blocks negative input outright at the input
  level — there's no scenario where a negative grade is meaningful — while
  keeping the upper-bound bug (scores over 100 aren't clamped) faithfully
  replicated, since that's the specific case that corrupts the average
  calculation.

### Deliberate deviations from the original site (Day 3)

- **Deleting a major cascades to its shortlisted universities.** Found via
  manual QA, not planned upfront: removing a major from Explore Majors
  left its shortlisted universities orphaned in My Shortlist, pointing at
  a major that no longer exists — the JS's own `persistMajors()` doesn't
  touch `U.targets` either, so this is likely present in the original
  too, but it reads as a bug rather than a faithful quirk worth
  replicating, so this rebuild fixes it. Scoped narrowly: only *deleting*
  a major cascades — un-Top-marking one (while it stays in the list)
  deliberately does not, since the student might re-Top it later and
  losing a curated shortlist over a temporary reshuffle would be
  needlessly punishing.
- **Country picker on Explore Majors.** The trimmed JS reference's own
  description text already promised "Add up to 6 majors with a target
  country," but no picker markup appeared in the excerpt provided. Added
  a real per-major country dropdown to close that gap, rather than
  leaving `country` permanently stuck at its default.
- **Save buttons (AppBar + end of My Shortlist).** Every action across all
  three tabs already persists immediately — there's no deferred/unsaved
  state anywhere in this feature for a Save button to actually write.
  Added anyway, purely as a reassurance affordance: ending a review flow
  on "just some back buttons, no Save" read as untrustworthy even though
  nothing was ever at risk of being lost.
- **`fitStatus`'s 4th tier is inferred, not confirmed from source.** The
  IELTS gap > 0.5 ("Needs work") branch cuts off mid-function in the
  trimmed JS reference. The label/tier are filled in from the CSS, which
  already defines a `.fit-work` (amber) class, but this specific branch
  wasn't confirmed verbatim the way the other three were.
- **Custom-university autocomplete draws from `UNIVERSITIES` +
  `EXTRA_UNIS` combined**, since a `UNI_CATALOG` data source the JS
  references was never actually provided — best reconstruction available,
  not a confirmed 1:1 match.

### Deliberate deviations from the original site (Day 4)

- **Built against a different re-entry screen than the day's own kickoff
  notes pointed at.** Those notes named `renderReturning()` (the "Welcome
  back… do you want to make changes?" screen) as the reference. Grepping
  every `sstate=` assignment in the full JS source turned up nothing that
  ever sets it to `"returning"` — it's dead code, unreachable from any
  button or sign-in handler. The behavioral spec's own flowchart
  independently confirmed the actual reachable behavior instead: a
  read-only "Your Current Schedule" summary (`renderMySchedule()`, which
  *is* reachable) shown once a submission exists, with Back/Make Changes
  both converging into the same anchor gate. Built against that.
- **Rank Other Clubs' pick count is grade-dependent, not the flat 2**
  planning.md originally assumed — direct source inspection found Grade
  10 ranks 2 clubs total (1 scheduled + 1 backup) while Grades 11/12 rank
  3 (2 scheduled + 1 backup).
- **Cross-student club capacity is stubbed behind one isolated function,
  not implemented.** No backend exists yet to supply a real cohort of
  other students' committed schedules to check a seat count against.
  Real, per-student clash-detection (a student can't be scheduled into
  two clubs on the same day) is implemented in full regardless;
  `alwaysHasRoomStub` is the one seam a later day swaps for a real
  cohort-aware check — nothing else in the scheduling algorithm needs to
  change when that happens.
- **Reordering ranked clubs is arrow-buttons only, not drag-and-drop.**
  The original offers both as equivalent paths ("drag or use ▲▼"). A real
  drag gesture here would mean nesting a `ReorderableListView` inside
  this screen's own scrolling list — a genuine bounded-height risk for a
  second path to behavior the arrow buttons already fully cover.
  `ClubRankingController.reorder()` exists and is tested at the
  controller level if drag support gets added later.
- **"Your Current Schedule" is a frozen snapshot, not a live recompute.**
  Once submitted, the read-only summary always reflects exactly what was
  submitted — even if the anchor major changes afterward elsewhere in
  the app — until the student explicitly taps "Make Changes" and
  resubmits. Decided deliberately: a submission is meant to be something
  concrete a coordinator can rely on, not a value that silently drifts
  out from under a student's own confirmed choice. A staleness banner
  (informational only — no embedded "tap Make Changes" nudge, the button
  is already sitting right there) flags when the frozen submission's
  required club has drifted from the live one; compared by resolved
  club, not raw major name, so two majors that happen to map to the same
  club (Accounting/Economics both → Business & Finance Club) don't
  trigger a false positive.

### Deliberate deviations from the original site (Day 5)

- **My Clubs → Application Materials auto-fill: genuinely fixed, not
  replicated as broken.** Previously listed above as a known bug to
  carry over. Direct inspection of Day 4's own `previewClubWeek` showed
  the auto-fill is fixable rather than something worth reproducing
  as-broken — Section B now calls it live against the student's
  submitted club selection every time the screen builds, the same
  "always re-derive, never cache" philosophy already used for My Clubs'
  own required-club display.
- **Activities Report's save model corrected mid-build, not assumed.**
  Initially built against the same deferred-Save pattern as Student's
  Profile. Tracing the actual JS handlers showed every field here
  autosaves per keystroke in the original, with the on-screen "Save"
  button wired to a generic, screen-agnostic flush action — not
  specific to this form at all. Rebuilt against the closer real
  precedent instead: row add/delete persist immediately (matching My
  Tests), field edits batch into one `saveAll()` call.
- **Portfolio is genuinely autosave**, confirmed directly by the
  behavioral spec's own explicit note for this screen (unlike Activities
  Report above, this one didn't need correcting) — every field writes
  through on change; its "Save" button is deliberately cosmetic, same
  reassurance-only pattern as Target Universities'.
- **Portfolio-vs-Activities-Report explainer surfaced properly.** The
  original site's `portfolioInfoHTML()` — the two-cards-plus-suitability-
  table explanation of when a portfolio matters — was defined but never
  called from anywhere reachable in the JS; genuinely dead code, not
  just hard to find. Flagged as worth porting anyway since the copy
  itself is real UX guidance, so it's surfaced here as a collapsed,
  reachable section rather than left unreachable. Its closing line
  ("Builder coming soon…") was dropped since it's no longer true — the
  builder is what this rebuild just shipped.
- **Grade-tab default is grade-alone, not the original's Staff-side
  key.** The JS's `studentAY()` branches on a Staff-only "selected
  class" concept with no equivalent in this Student-only rebuild — same
  simplification family as `club_catalog.dart`'s `sessionBandForGrade`.
  The student's own session grade decides the default tab directly.
- **The 3 grade tabs don't scope Activities Report or Portfolio.**
  Tracing the JS, both docs are keyed only by student name, never by
  academic year — the tab only matters once Day 6's essay docs exist,
  which genuinely do keep a separate draft per year. Worth stating
  explicitly so switching tabs with no visible effect on either doc
  reads as expected, not broken.

## Project structure

```
lib/
  core/
    theme/        — design tokens + ThemeData, mined from the original CSS
    routing/      — go_router config and route guards
    persistence/  — Hive setup (initHive(), box name constants)
  features/
    auth/         — Choose Role, Login, session state (shared entry point above all roles)
    student/      — Student-role screens
      domain/       — Hive models (Profile, Tests, Grades, curriculum data, Target Universities, Clubs, Application Materials) + pure scheduling logic (club/day data tables, week-preview algorithm)
      data/         — repositories wrapping Hive boxes
      application/  — Riverpod controllers (business logic, validation)
      presentation/ — screens
    parent/       — (not yet built)
    staff/        — (not yet built)
  hive_registrar.g.dart — generated Hive adapter registrar (checked in, not hand-edited)
  main.dart
test/
  features/
    auth/
    student/
      domain/
      application/
      presentation/
  core/routing/
```