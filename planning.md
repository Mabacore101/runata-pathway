# Runata Pathway — Flutter Rebuild — Planning Doc

Living reference doc for this project. Paste this into the repo root. Any coding chat
picking this project up should read this first before touching code.

---

## 1. Project Context

- Native Flutter rebuild (iOS + Android) of an existing web app: **Runata Pathway**, a school portal.
- Original web app has 3 role surfaces: **Student**, **Parent**, **Staff**.
- Original source was a single >3000-line HTML file with all roles' markup coexisting,
  visibility toggled by JS state. **This pattern is NOT being replicated.** The new app
  has real, structural role separation.
- Sources used for spec: manual QA behavioral spec (Student only), raw page source
  (all 3 roles present, reference only), field/datatype doc, draw.io flowchart JSON.

## 2. Role Architecture Decision

The sign-in menu shows 5 buttons, but they map to only **3 architectural roles**:

```html
<button data-role="student">
<button data-role="parent">
<button data-role="staff" data-staff="teacher">
<button data-role="staff" data-staff="counsellor">
<button data-role="staff" data-staff="coordinator">
```

Teacher / Counsellor / Coordinator all share `data-role="staff"` — they differ only by
`data-staff`, funnel into the **same** staff login modal, and the original source has a
single `<div id="teacher">` container serving all three. This means they are permission
variants of **one Staff role**, not three separate roles.

**Folder structure reflects 3 roles, not 5.** If Staff QA later reveals real structural
divergence between teacher/counsellor/coordinator, that becomes sub-folders *inside*
`staff/` at that point — not a reason to pre-build 5 top-level folders now.

## 3. Current Spec Coverage Status

| Role | Behavioral spec status |
|---|---|
| Student | ✅ Fully mapped via manual QA |
| Parent | ❌ Not mapped yet |
| Staff (teacher/counsellor/coordinator) | ❌ Not mapped yet |

**Scope commitment:** Student role is the committed 7-day target. Parent/Staff are
stretch goals contingent on someone doing QA discovery on those roles in parallel —
not something extra dev hours alone can produce.

## 4. Locked Technical Decisions

| Decision | Choice | Why |
|---|---|---|
| State management | **Riverpod** | Better testability than Provider, less ceremony than Bloc for a form-heavy app |
| Local storage | **Hive** (over sqflite) | Data is mostly flexible objects/lists (test rows, portfolio entries, tabbed grades), not relational — Hive skips schema/migration overhead |
| Backend | **Local-only for now** | No Supabase credentials on hand yet; original site's own Supabase script tag is optional/degrades to offline, so this mirrors that default |
| Routing | **go_router** | Standard modern Flutter routing choice |
| Testing | `flutter_test` + `mocktail` + `hive_test` | Traditional test-after-code flow, not TDD |
| iOS | Code should be correct, but **unverified** — no Mac access currently. Verify when Mac access exists. |

### Dependencies installed
```
flutter_riverpod hive hive_flutter go_router google_fonts
mocktail hive_test build_runner   (dev)
```

**Riverpod version note (found Day 1):** installed `flutter_riverpod` is on
3.x, where `StateNotifier`/`StateNotifierProvider` moved to a `legacy.dart`
import. Use the modern `Notifier`/`NotifierProvider` API for all controllers
going forward (see `auth_controller.dart` for the pattern) — don't mix in
the legacy import just because older tutorials/snippets use it.

**Font tokens — ✅ RESOLVED & VERIFIED (Day 1).** Added `google_fonts` (these
are the exact same 3 families the original site pulls from
fonts.googleapis.com, so this wraps the same source rather than manually
bundling files from scratch). `AppFonts` in `core/theme/app_theme.dart` now
exposes `display()`/`body()`/`mono()` TextStyle factories backed by
`GoogleFonts.bricolageGrotesque()` / `.inter()` / `.ibmPlexMono()`, wired
into `buildStudentTheme()`'s `textTheme`. Runtime HTTP fetching is disabled
(`GoogleFonts.config.allowRuntimeFetching = false` in `main.dart`) so
release builds don't depend on the network to render text correctly — this
requires the actual `.ttf` files bundled under `assets/google_fonts/`
(weights: Bricolage Grotesque 600/700/800, Inter 400/500/600/700, IBM Plex
Mono 400/600/700 — matches every `--disp`/`--mono` usage found in the
trimmed CSS reference). **Verified working:** app builds and runs cleanly
with `allowRuntimeFetching = false`, fonts render correctly on-device (not
falling back to system font), full test suite green. Parent/Staff work
later should reuse `AppFonts` rather than reference `GoogleFonts.*`
directly, so any future font swap only touches one file.

## 4a. Auth Architecture (added Day 1)

- **Choose Role + Login live in `features/auth/`, not nested under
  `features/student/`.** They sit above all 3 roles (Parent/Staff will use
  the same Choose Role screen and a similar login shape later), so they
  didn't belong inside the student folder even though only Student is wired
  up today.
- **Choose Role shows all 5 original buttons** (Student / Parent / Teacher /
  Counsellor / Coordinator) for visual parity with the live site — only
  Student is enabled, the other 4 are visibly present with a "Coming soon"
  tag rather than hidden. Matches the "visibly disabled" instruction in the
  Day 1 scope more literally than collapsing straight to 3 buttons.
- **Login form is Student ID + password, single generic error bucket** —
  matches the QA'd behavioral spec's documented flow, not the "class + name
  autocomplete" offline-demo code path also present in the reference
  source. Validated against a small local mock roster
  (`LocalStudentAuthRepository`) since there's no backend yet — same
  password-defaults-to-Student-ID convention as the reference site.
- **Router guard uses `refreshListenable`, not just `redirect`.** The
  `redirect` guard alone only re-runs on an explicit navigation call.
  `refreshListenable` bridges auth-state changes into a fresh redirect
  check even with no navigation attached — matters once session persistence
  exists (a restored session could become valid before any screen
  navigates). Worth reusing this same pattern once Parent/Staff auth exists.

## 5. Folder Structure

```
lib/
  core/       -- app-wide config, theming, routing setup
  shared/     -- shared widgets used across roles
  features/
    auth/     -- Choose Role, Login, session state (sits above all 3 roles)
    student/
    parent/
    staff/
test/
  features/
    auth/
  core/
    routing/
```

## 6. Known Bugs From Original Site (Student Spec) — Stance Needed

These exist in the current live site's behavior. Default stance below unless overridden:
**replicate for now, track as a fix-later backlog item** rather than silently fixing
(avoids undocumented scope creep vs. the spec).

- [x] Silent birth-date field failure — **DECIDED: NOT replicated, fixed instead.**
      Unlike the other three bugs on this list, this one is being fixed rather than
      carried over: an invalid date now shows a direct, visible warning to the
      student instead of silently failing to save. Deviation from the doc's default
      "replicate for now" stance — noted here explicitly so it isn't mistaken for
      an inconsistency later.
- [ ] Grade score input allows values outside 1–100 clamp (breaks average calculation) —
      relevant to Day 2's My Grades. Replicate: spinner enforces range, direct text
      entry bypasses it (matches original site behavior).
- [ ] Clubs auto-fill from anchor major is broken — relevant to Day 4.
- [ ] "Mark as Ready" on essay/application sections can be bypassed without meeting
      criteria — relevant to Day 6.

*(Confirm/adjust this list against the full behavioral spec doc before Day 5–6 work,
since two of these live in Application Materials.)*

## 7. Development Rhythm

**Not** test-last-day-only. Each coding day = build during the day, **last 1–2 hours
of each day = write unit/widget tests for what was just built.** Day 7 shifts from
"the only testing day" to integration-test + polish + buffer day.

## 8. 7-Day Plan (Student Role) — Day 0 = today, prep only

**Day 0 — Foundation (no screens) — ✅ DONE**
- Lock decisions (this doc)
- Install dependencies
- Folder skeleton (student/parent/staff, core, shared)
- Data models for all 6 Pathway forms (from field/datatype doc)
- Skeleton routing: Login → Choose Role → Student Homepage (placeholder screens, real nav)
- Shared theming (colors, typography, buttons)

**Day 1 — Login + Homepage + shell — ✅ DONE**
- Choose Role screen (Student functional; Parent/Staff visibly disabled/"coming soon")
- Student Login Form, generic single-bucket error (no field-specific error, per spec)
- Student Homepage, all 3 entry points wired (Dashboard / Pathway / Nav Grid) — confirmed
  navigating to reachable stub screens
- Sign out flow
- Tests: login repository + controller + router redirect guard (both directions)
- Font tokens resolved & verified (see section 4 above)

*Actual scope note:* Homepage is 3 clearly-separated entry-point cards, not
the reference site's fuller single-page layout (dashboard CTA + roadmap +
8-tile grid all at once) — most of that layout points at the 6 Pathway
forms, which don't exist until Day 2–6, so building the fuller version now
would mostly dead-end. Revisit once those forms exist.

**Day 2 — Standalone forms — 🔜 TODO (tomorrow)**
- [x] Birth-date bug stance decided (see Section 6): fixed, not replicated —
      invalid date shows a direct warning instead of failing silently
- [ ] Student's Profile — single form, all fields optional (per spec,
      nothing is required), with one exception to the "no validation"
      default:
      - General info: Date of birth (date picker) — field itself stays
        optional, but if a date IS entered and it's invalid, show a clear
        visible warning to the student rather than silently failing to
        save (this is the one deliberate fix vs. the original site, see
        Section 6)
      - Phone Number, Address
      - Parent/Guardian: Name, Phone, Email, Available time
      - Siblings (textarea)
      - Medical: Allergies, Regular medicine, Hospital (all textarea)
      - Transportation: how student gets to/from school
      - Emergency contact
      - Persist to Hive
- [ ] My Tests — repeatable rows:
      - Target (text), Latest (text), Status (dropdown: Planned/Registered/
        Taken, defaults to Planned), Date (text)
      - Duplicate-blocking logic for test types — confirm the exact dedup
        condition against the behavioral spec before implementing, don't
        assume
- [ ] My Grades:
      - 6 semester tabs
      - Fixed subject list + custom subjects addable by student
      - Score input: Number, spec range 1–100; replicate the clamp-bypass
        bug (spinner enforces range, direct text entry doesn't)
      - Average calculation must reflect the bug's actual impact (an
        out-of-range manually-typed score should visibly skew the average,
        not be silently clamped)
- [ ] Last 1–2 hrs: unit tests
      - Grade average calculation — include an explicit test case for the
        out-of-range/bug scenario, not just the happy path
      - Test-type duplicate-blocking rule

**Day 3 — Target Universities (heaviest single-form logic — full day)**
- Explore Majors (multi-select 1–6, mark-top 1–3, anchor gating)
- Find Universities (gated on Top-marked majors, shared shortlist cap)
- My Shortlist (empty state, edit notes, delete, ANCHOR/YOURS tags)
- Delete-a-major cascade logic — budget real time here, trickiest state in the app
- Last 1–2 hrs: unit tests for anchor-clear cascade, shortlist cap enforcement

**Day 4 — My Clubs (depends on Day 3 anchor major)**
- Anchor-derived locked required club
- Rank Other Clubs (2 picks)
- Generate My Week gating (2/2 ranked required)
- Submit flow + read-only re-entry state + Make Changes loop
- Last 1–2 hrs: unit tests for club ranking gate logic

**Day 5 — Application Materials, part 1**
- Hub shell (3 grade-level tabs × 8 sections)
- Student Activities Report (repeatable template; replicate broken auto-fill per bug stance)
- Portfolio (autosave-only, live "# Works" counter)
- Last 1–2 hrs: widget tests for form rendering/validation

**Day 6 — Application Materials part 2 + remaining pieces**
- 5 shared essay sections (same template, different criteria lists; "Mark as Ready" bypass bug stance)
- Recommendation Letters (mark uploaded / undo toggle)
- Counsellor's Corner (plain form)
- Pathways (external link, new tab)
- Dashboard + Nav Grid (these are "doors" into what's already built — should be fast)
- Last 1–2 hrs: widget tests for remaining forms

**Day 7 — Integration + polish + buffer**
- Integration test: full path login → Profile → Target Universities → My Clubs → submit → Homepage state updates
- Manual device pass on physical Android phone
- Fix whatever surfaces
- Final commit + push

**Real risk flag:** Days 3–4 (cascade logic) are the likely time sink, not the volume
of Day 5–6 sections (repetitive once one template is built).

## 9. Environment (for reference)

- Flutter 3.44.6, stable channel
- Android SDK 36, Build-Tools 28.0.3
- JDK: Temurin 21 (via `JAVA_HOME`)
- Testing device: physical Android phone via USB debugging (no Mac access — iOS unverified)
- Editor: VS Code + Flutter extension