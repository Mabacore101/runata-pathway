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
- [ ] Day 4 — My Clubs
- [ ] Day 5 — Application Materials (part 1)
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

| Student ID | Password |
|---|---|
| `2627001` | `2627001` |
| `2627002` | `2627002` |

(Password defaults to the Student ID, mirroring the original site's own
convention for first-time sign-in.)

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
Cascade behavior between the three tabs (e.g. deleting a major cleaning up
its shortlisted universities) is covered at the controller level.

## Known bugs carried over from the original site

The live site has a handful of quirks. Default stance is **replicate for
now, track as a backlog item** rather than silently fixing — avoids
undocumented scope creep against the behavioral spec. Confirm/revisit before
the relevant day's work:

- My Grades — manually-typed scores above 100 aren't clamped, corrupting
  the average calculation (upper bound only — see deviation below for the
  lower bound)
- My Clubs → Application Materials — "auto-fill from clubs" doesn't work
- Application Materials (essay sections) — "Mark as Ready" only checks for
  non-empty text, not actual criteria

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
      domain/       — Hive models (Profile, Tests, Grades, curriculum data, Target Universities)
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