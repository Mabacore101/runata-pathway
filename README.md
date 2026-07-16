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
- [ ] Day 2 — Student's Profile, My Tests
- [ ] Day 3 — Target Universities
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
| Local storage | Hive (flexible objects/lists — profile, tests, grades — not relational) |
| Backend | Local-only for now — no Supabase project connected yet |
| Testing | `flutter_test` + `mocktail` + `hive_test` |

## Getting started

```bash
flutter pub get
flutter run
```

Requires a connected device or emulator with USB debugging enabled. iOS is
written to be correct but hasn't been verified on a physical device yet (no
Mac access during initial development).

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

## Known bugs carried over from the original site

The live site has a handful of quirks. Default stance is **replicate for
now, track as a backlog item** rather than silently fixing — avoids
undocumented scope creep against the behavioral spec. Confirm/revisit before
the relevant day's work:

- Student's Profile — invalid birth date silently fails to save (no error shown)
- My Grades — manually-typed scores can exceed the 0–100 range, corrupting the average calculation
- My Clubs → Application Materials — "auto-fill from clubs" doesn't work
- Application Materials (essay sections) — "Mark as Ready" only checks for non-empty text, not actual criteria

## Project structure

```
lib/
  core/
    theme/      — design tokens + ThemeData, mined from the original CSS
    routing/    — go_router config and route guards
  features/
    auth/       — Choose Role, Login, session state (shared entry point above all roles)
    student/    — Student-role screens
    parent/     — (not yet built)
    staff/      — (not yet built)
  main.dart
test/
  features/auth/
  core/routing/
```