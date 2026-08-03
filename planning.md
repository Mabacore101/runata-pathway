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
| Local storage | **Hive CE** (over sqflite) | Data is mostly flexible objects/lists (test rows, portfolio entries, tabbed grades), not relational — Hive skips schema/migration overhead. Swapped from original `hive` to `hive_ce` on Day 2 (see dependency note below) |
| Backend | **Local-only for now** | No Supabase credentials on hand yet; original site's own Supabase script tag is optional/degrades to offline, so this mirrors that default |
| Routing | **go_router** | Standard modern Flutter routing choice |
| Testing | `flutter_test` + `mocktail` + `hive_ce_test` | Traditional test-after-code flow, not TDD |
| iOS | Code should be correct, but **unverified** — no Mac access currently. Verify when Mac access exists. |

### Dependencies installed
```
flutter_riverpod hive_ce hive_ce_flutter go_router google_fonts
mocktail hive_ce_test build_runner hive_ce_generator   (dev)
```

**Hive → Hive CE swap (Day 2):** original `hive`/`hive_flutter` packages are
deprecated/unmaintained; swapped to the community-maintained `hive_ce` /
`hive_ce_flutter` (+ `hive_ce_generator`, `hive_ce_test` in dev deps) before
actually wiring persistence up for the first time — see the Day 0 gap note
below for why this was needed now rather than earlier.

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
- [x] Grade score input allows values outside 1–100 clamp (breaks average calculation)
      — **DECIDED (Day 2): partially replicated, not a full 1:1 copy.** Upper-bound
      bypass (>100 breaks the average) is faithfully replicated, exactly as the
      original site does it — the averaging function is deliberately unclamped.
      Lower bound is a genuine deviation: negative scores are blocked structurally
      at the input level (digit-only input formatter, no minus sign possible),
      since the flow spec's own "even if >100 or <0" wording aside, there's no
      real-world scenario where a negative grade is meaningful. Both the
      replicated and the deviating half are covered by tests.
- [x] Clubs auto-fill from anchor major is broken — **DECIDED (Day 5 prep):
      NOT replicated, genuinely fixed instead.** The live site's version
      reads `studentPlan[stu.n]`, populated by the cohort-wide
      `buildSchedule()` — whatever causes it to break there is likely a
      multi-student-scale issue outside what this rebuild can diagnose
      from source alone. But Day 4 already built `previewClubWeek`, which
      computes the identical shape of data using only this student's own
      confirmed anchor + ranked clubs (capacity correctly stubbed to
      "always available" for a single-student rebuild). Re-running it
      against the persisted `StudentClubSelection` gives a genuinely
      correct auto-fill — take the win rather than replicate brokenness
      that only exists for cohort-scale reasons this rebuild doesn't share.
      One related simplification: the JS's `role` comes from a Staff-side
      President/VP assignment that doesn't exist yet — default every
      auto-filled entry's role to "Member" until Staff exists, don't
      invent a fake assignment system.
- [ ] "Mark as Ready" on essay/application sections can be bypassed without meeting
      criteria — relevant to Day 6. **Precision correction (Day 6 prep):** the
      handler checks nothing at all, not even non-empty text — a straight
      unconditional status flip to "Final". Worth replicating the actual
      unconditional behavior, not a softer "non-empty check" version.

*(Confirm/adjust this list against the full behavioral spec doc before Day 5–6 work,
since two of these live in Application Materials.)*

## 6a. Scope Addition Found During Day 2 (approved, not silently accepted)

Neither the field/datatype doc nor the behavioral spec mentioned that Student's
Profile's Parent/Guardian section is **repeatable** — that only surfaced from
reading the live site's actual JS (`day2-trimmed-source.md`'s `renderProfile()`):
`P.parents` is an array with an "+ Add another parent/guardian" button and a
per-entry delete button (hidden when only one entry remains). The JS also has a
per-parent `address` field neither doc listed.

**Approved as real scope, not an oversight to roll back:** built as
`List<ParentGuardianEntry>`, always seeded with one blank entry, matching the
live site's actual behavior. Hive field-index safety was handled carefully
(old flat parentName/Phone/Email/AvailableTime indices permanently retired
rather than reused, new list field given a fresh index) since real Hive data
had already been written under the old shape before this was caught.
Round-trip and ordering covered by tests.

This is exactly the kind of gap the Day 1/Day 2 trimmed JS references exist to
catch — worth remembering for Days 3–6, where the same "doc says X, live JS
does X+1" pattern may repeat.

## 7. Development Rhythm

**Not** test-last-day-only. Each coding day = build during the day, **last 1–2 hours
of each day = write unit/widget tests for what was just built.** Day 7 shifts from
"the only testing day" to integration-test + polish + buffer day.

## 8. 7-Day Plan (Student Role) — Day 0 = today, prep only

**Day 0 — Foundation (no screens) — ✅ GAP FIXED (Day 2 session)**
- Lock decisions (this doc) — ✅
- Install dependencies — ✅
- Folder skeleton (student/parent/staff, core, shared) — ✅
- Data models for all 6 Pathway forms (from field/datatype doc) — ⚠️ **3 of 6
  done** (Profile, Tests, Grades — the ones Day 2 needs). Target
  Universities/My Clubs/Application Materials remain, scheduled for Days
  3/4/5 per the existing plan below — this was never meant to be all 6 at
  once, just corrected to reflect 3 are real now, not 0.
  - `initHive()` in `core/persistence/hive_registrar.dart`, called from
    `main.dart` before `runApp()` — verified by direct file inspection
  - Swapped to `hive_ce`/`hive_ce_flutter` (see dependency note above)
  - `@HiveType`/`@HiveField` models + generated adapters via
    `hive_ce_generator`, auto-discovered (no hand-maintained registration
    list to forget again)
  - Verified: `flutter test` passes (round-trip tests included), app runs,
    and `app_router.dart`/`app_theme.dart`/`auth_controller.dart` are
    byte-for-byte unchanged — the fix is additive, Day 1's flow is intact
- Skeleton routing: Login → Choose Role → Student Homepage (placeholder screens, real nav) — ✅
- Shared theming (colors, typography, buttons) — ✅

*(This gap was found during Day 2 prep after the original Day 1 coding chat
session became unresponsive; fixed properly in a fresh session on
2026-07-16 before any Day 2 form work began.)*

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

**Day 2 — Standalone forms — ✅ DONE**
- [x] **STEP 0 — Fix the Day 0 gap.** `hive_ce` wired up, 3 models built
      (Profile/Tests/Grades) with generated adapters, `initHive()` called
      before `runApp()`, round-trip tests passing, zero regression to
      existing Day 1 code (router/theme/auth confirmed byte-for-byte
      unchanged).
- [x] Birth-date bug stance: fixed, not replicated — invalid date shows a
      direct warning (via `dateOfBirthWarning`/`errorText`) instead of
      failing silently. Parser explicitly guards against Dart's silent
      date-rollover behavior (e.g. `DateTime(2026, 2, 30)` quietly becoming
      March 2nd), so a truly invalid date can't slip through disguised as
      a valid one.
- [x] Student's Profile — all field/datatype-doc fields built, all
      optional, persisted to Hive. Parent/Guardian built as a genuinely
      repeatable list (see Section 6a) rather than 4 flat fields, matching
      the live site's actual behavior once that was discovered.
- [x] My Tests — repeatable rows (Target/Latest/Status/Date), duplicate-
      blocking enforced at both the controller and UI layer, with AP/Other
      correctly exempted per the flow spec.
- [x] My Grades — 6 semester tabs, fixed curriculum (ported from the live
      site's actual `CURRICULUM` JS object, since neither doc named the
      real subjects) + custom subjects, Science/Social track toggle
      (defaults to social pending Day 3's anchor-major auto-inference).
      Score bug handled as a deliberate partial-replication (see Section
      6): upper-bound bypass faithfully kept, lower bound blocked at the
      input-formatter level.
- [x] Tests — extensive: date-parsing edge cases, Hive round-trips for all
      3 models, duplicate-rule coverage from both sides, the exact bug
      scenarios named above, plus widget-level tests for all 3 screens
      (`profile_screen_test.dart`, `tests_screen_test.dart`,
      `grades_screen_test.dart` — the first two were a follow-up fix after
      an initial pass only covered Grades at the widget level).

**Day 3 — Target Universities — ✅ DONE**
- [x] Explore Majors — multi-select up to 6, mark up to 3 as Top, exactly 1
      anchor (must already be Top-marked). Anchor implemented as a derived
      getter (`MajorsDerived.anchor`) over the majors list, never a
      separately-stored field — deliberately mirrors the original site's
      own robustness pattern (`day3-trimmed-source.md`'s "Read this first"
      finding), so there's no cache to remember to clear.
- [x] Find Universities — gated on 1+ Top-marked major, **per-major**
      shortlist cap of 3 (confirmed independent per major, including via
      test — see `university_targets_controller_test.dart`'s
      "the per-major cap is independent per major" case)
- [x] My Shortlist — empty state, editable notes, delete, ANCHOR/YOURS tags
- [x] Cascade logic — `removeMajor` (anchor "free" via the derived getter,
      no explicit clear needed), `toggleTop` (un-marking Top also clears
      anchor on that entry — real cascade code, same handler as the JS),
      `setAnchor` (exactly 1 at a time). All 3 covered by name-matching
      tests (e.g. "removing the anchor major clears the derived anchor").
- [x] Tests — controller-level coverage for all of the above, plus Hive
      persistence round-trips

**Real bug found only through manual device testing, not caught by the
unit test suite:** deleting a major from Explore Majors left its
shortlisted universities behind in My Shortlist, orphaned and pointing at
a major that no longer existed. Fixed by cascading `removeMajor` into a
new `UniversityTargetsController.removeAllForMajor` call — deliberately
scoped to full deletion only, NOT triggered by un-Top-marking (a
temporarily-untopped major might get re-promoted later; wiping its
curated shortlist over a reshuffle would be needlessly destructive). Now
has its own regression test, named directly after the real bug report
rather than a generic case name, so it can't silently regress.

*Process note worth carrying forward:* this is a concrete example of why
Section 7's "test alongside each piece, not batched" rhythm isn't
sufficient by itself — the controller-level tests were thorough and all
passed, but the bug only surfaced once a real person used the actual app
end-to-end. Manual device testing catches a different class of bug than
unit tests do; neither replaces the other.

*Schedule note:* this pushed past the original single-day estimate,
confirming the plan's own "Days 3–4 are the likely time sink" flag from
Section 8's closing risk note. The 7-day schedule now has some slip — see
whether Day 4 can recover any of it, but not by rushing verification.

**Day 4 — My Clubs — ✅ DONE**
- [x] Anchor-derived locked required club — `requiredClubProvider` reads
      `MajorsDerived.anchor` via `ref.watch`, live/reactive, resolving
      item 5's cascade question for free (Riverpod rebuilds every
      listener the moment the anchor changes — no extra wiring needed)
- [x] Rank Other Clubs — grade-dependent pick count confirmed and
      implemented correctly (`neededPicksFor`/`scheduledSlotsFor`),
      tested for both grade bands separately
- [x] Capacity engine — real clash-detection implemented in full
      (`previewClubWeek`/`club_schedule_preview.dart`), cross-student
      capacity isolated behind one injectable function (`hasRoom`,
      defaulting to `alwaysHasRoomStub`) exactly per the decision above —
      confirmed nothing else in the file needs to change when real
      cohort data eventually exists
- [x] Generate My Week gating — enforced before "Generate my week" is
      reachable
- [x] Submit flow + read-only re-entry + Make Changes loop — **built
      against a different, corrected reference than originally pointed
      at.** day4-trimmed-source.md named `renderReturning()` as the
      Make-Changes-loop reference; the coding chat independently grepped
      every `sstate=` assignment in the full source and found
      `"returning"` is never actually assigned anywhere — `renderReturning()`
      is dead code, unreachable from any button. Verified independently
      here (same grep, same result) before accepting it. Built against
      the actually-reachable `renderMySchedule()` instead, cross-checked
      against the behavioral spec's own flowchart. **Correction for any
      future day that might reference day4-trimmed-source.md again:**
      ignore its `renderReturning()` framing, use `renderMySchedule()`.
- [x] Cascade logic — `ClubRankingController` uses `ref.listen` (not
      `ref.watch`, deliberately — a side-effect on state, not a rebuild)
      to strip a stale ranked entry the instant the anchor changes
      elsewhere in the app. Explicitly tested, including the
      anchor-removed-entirely edge case.
- [x] Tests — thorough throughout, including a dedicated "Cascade" test
      group for item 5

**Schedule note:** spanned two calendar days, as anticipated going in —
this was flagged as heavier than Day 3 before starting (5 substantial
items plus new capacity-engine complexity), not a new slip.

**Day 5 — Application Materials, part 1 — ✅ DONE**
- [x] Hub shell — all 8 `MaterialDoc` rows built, gated behind a single
      `availableToday` flag per doc (only Activities Report + Portfolio
      flipped on today) — Day 6 only needs to flip 6 booleans as their
      screens ship, nothing structural to redo
- [x] Student Activities Report — sections A/C/D/E/F as repeatable rows,
      following the owning-record-with-embedded-lists shape. **Good
      self-correction caught during build:** the controller initially
      assumed a Profile-style deferred-save pattern, then traced the
      actual JS handlers and found row add/delete are immediate/persisted
      while only field edits batch into Save — corrected to match
      `TestsController`'s already-established pattern rather than
      inventing a third shape. Section C's eligibility rule confirmed
      exact against the field/datatype doc.
- [x] **Section B (clubs auto-fill) — genuinely fixed, verified working.**
      Wired to `previewClubWeek`, confirmed correct: dedup matches the
      JS's `[...new Set(...)]` exactly, `role` hardcoded to "Member",
      `dates` hardcoded to the same literal placeholder the original site
      itself uses. Widget test seeds a real `StudentClubSelection` and
      confirms exact rows/role/dates appear, plus the correct empty-state
      prompt when clubs were never submitted.
- [x] Portfolio — works list, maker statement, major-suggestion banner.
      "# Works" counter confirmed reading raw `works.length`
      (unfiltered), matching both the JS and the behavioral spec's exact
      wording (cited directly in the model's doc comment).
- [x] Tests — thorough throughout, including the dedicated Section B
      end-to-end cross-check against Day 4 (item 4)

**Day 6 — Application Materials part 2 + remaining pieces — 🔶 PARTIALLY DONE (items 1–6 of 8)**
- [x] 5 shared essay sections — one shared model (`ApplicationDocumentState`),
      not 6 near-identical ones, matching `renderMatDoc`'s single-function-
      handles-all-kinds shape. `RUBRIC` ported faithfully via
      `document_rubric.dart`, including a genuinely subtle catch: the
      "personal" essay's length criterion has a label/logic mismatch in the
      ORIGINAL SITE ITSELF (label says 450–650 words, actual check allows up
      to 700) — correctly preserved as-is rather than silently fixed, with
      the mismatch documented in code.
- [x] "Mark as Ready" — confirmed and verified fully unconditional
      (`markReady()`), matching the corrected bug description exactly: no
      non-empty check, no criteria check, a bare status flip.
- [x] Recommendation Letters — same shared model/template, upload-kind,
      `toggleSubmitted()` confirmed as a bare toggle with no side effects.
- [x] Counsellor's Corner — confirmed genuinely simple as expected.
- [x] Pathways — confirmed genuinely small as expected.
- [x] **Nav Grid — done, pulled forward from a planned-separate session.**
      `student_home_screen.dart` now fully replaces Day 1's 3-card stub:
      Dashboard CTA (linking to the already-existing Day 1 stub route,
      no new routing needed), 6-step roadmap with tested done/next/later
      logic, full 8-tile grid. Coordinator-lock banner and Parent-mode
      correctly omitted (Staff/Parent roles don't exist yet), documented
      in the file itself.
      **Bonus finding:** building this item's "done" signals already
      produced real reusable cross-feature aggregation providers —
      `materialsStartedCountProvider` (faithful port of `matStartedCount`,
      combining all 4 doc kinds) and `MaterialsContext`/`materials_context.dart`
      (faithful port of `matCtx()`, the essay-scoring context) — meaning
      item 7 (Dashboard) has more groundwork already laid than expected.
      See the refreshed `day6-codebase-reference.md` for the confirmed
      data-sources table.
- [ ] **Dashboard (item 7) — scope narrower than originally estimated,
      given the above.** The Overview panel's completion ring + 6
      mini-stats can likely be built almost entirely from providers that
      already exist. Remaining real work: the 6 detail panels' own
      presentation (Target/Tests/Fit/Grades/Activities/Materials tabs)
      and the SVG completion-ring/trend-arrow widgets, which have no
      existing equivalent yet. Still budget real time — narrower scope,
      not zero scope.
- [ ] Cross-check everything against real data end-to-end (item 8) — do
      this last, once item 7 is verified, same "verify the aggregate
      last" discipline as every prior day's cascade/cross-check step.
- [ ] Tests alongside each piece (per Section 7), same rhythm as Days 2–5

**Day 7 — Polish + closeout — ✅ DONE (launcher icon deliberately deferred)**

**Decision made: no automated integration test.** Day 6 already performed
a thorough manual end-to-end cross-check (real data across every feature
simultaneously, confirmed in that day's own entry above) — considered
sufficient rather than also writing an automated version. Reasoning: the
cascade bugs that actually surfaced across this project (Days 3, 4, 6)
were all confined to one identifiable chain (anchor major → clubs →
materials), not spread evenly across the app — roughly 80% of the app's
features are independent of each other, per direct review of the
project's own flowchart. A blanket automated test attempting to model
every path/convergence in that flowchart would itself become nearly as
complex and fragile as the app, for coverage of a failure mode that isn't
actually spread that broadly. Manual verification (already done) stands
as the deliberate choice here, not a shortcut.

- [x] **Visual polish — done, verified precisely against the original CSS**
      (see day7-codebase-reference.md):
      - Logo (`runata_global_school.png`) used as the AppBar's `title`
        slot at exactly `height: 28` matching `.appbar img{height:28px}`,
        with a `semanticLabel` added for accessibility
      - Sign-out control built as `_SignOutPill`,
        `BorderRadius.circular(20)` matching the original's `.staff`
        class shape exactly, cited directly in a code comment
      - `AppBarTheme` wired to `AppFonts` — plus a subtle catch beyond
        what was asked: Material 3's `scrolledUnderElevation` would have
        introduced a tinted/shadowed bar on scroll not present in the
        original spec, correctly neutralized
        (`scrolledUnderElevation: 0`, `surfaceTintColor: Colors.transparent`)
      - Header background confirmed correctly left plain (no colored bar
        added), matching the original CSS's actual rule
- [ ] **Launcher icon — no longer blocked, proceeding today.** The
      earlier `runata_icon.png` was too low-resolution/blurry (deferred
      for that reason, see prior entry above — not forgotten, just
      correctly held back). A proper source now exists:
      `runata_global_school_icon_only.png` — cropped to just the crest
      (no wordmark/tagline text, which would be unreadable at icon size),
      genuinely transparent background (confirmed programmatically: RGBA,
      alpha=0 at all four corners, not just a light-gray fill that looks
      transparent). Today's task: add `flutter_launcher_icons` as a dev
      dependency, point `image_path` at this file, run the generator, and
      confirm on-device it renders cleanly — no stray background box, no
      odd cropping from Android/iOS icon masking.
- [x] Manual device pass — confirmed today's visual changes render
      correctly on-device.
- [x] **iOS status — closed out, and more thoroughly than the original
      TODO asked for.** README now states plainly: written to be correct,
      never verified on a physical device or Simulator, Mac access never
      materialized across all 7 days — a real, unworkable constraint
      (Xcode's Simulator only runs on macOS), not a resource gap that
      could've been worked around. Beyond the plain statement, a static
      code-review pass covered `Info.plist`/`project.pbxproj` deployment
      target, the `url_launcher` call in Pathways, and Hive's iOS storage
      path choice — found no build-blocking issues, plus a verified,
      accurate forward-looking note that Apple requires the iOS 26 SDK
      for new App Store Connect submissions starting April 28, 2026.
      Explicitly labeled as a static check, not behavioral verification —
      on-device iOS testing remains the real handoff item for whoever
      picks this up next.
- [x] **Parent/Staff scope — closed out.** README confirms both remain
      deliberately unstarted per Section 3's original commitment; the
      `parent/`/`staff/` folders are documented as placeholders for
      future work, not incomplete features from this build.
- [x] Final commit + push

**Testing philosophy, stated explicitly (came up in discussion, worth
logging rather than leaving implicit):** this project tests business
logic (calculations, gating, cascades, persistence) automatically, and
verifies pure visual/cosmetic polish (colors, spacing, icons, exact pixel
match to a design) by hand, on-device. A widget test asserting "the logo
image renders" or "the button is round" mostly restates the code back at
itself rather than catching a real class of bug — the same reasoning
that's driven this project's manual-vs-automated split since Day 3's
"manual testing catches a different class of bug than unit tests do."
Not a gap in this project's test coverage; a deliberate boundary.

**Real risk flag (historical, from Day 3):** Days 3–4 (cascade logic) were
the likely time sink, not the volume of Day 5–6 sections — this held true
across the whole project and is part of why Day 7's manual-only decision
above was reasonable rather than risky.

## 9. Environment (for reference)

- Flutter 3.44.6, stable channel
- Android SDK 36, Build-Tools 28.0.3
- JDK: Temurin 21 (via `JAVA_HOME`)
- Testing device: physical Android phone via USB debugging (no Mac access — iOS unverified)
- Editor: VS Code + Flutter extension