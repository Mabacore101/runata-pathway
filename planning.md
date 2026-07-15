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
flutter_riverpod hive hive_flutter go_router
mocktail hive_test build_runner   (dev)
```

## 5. Folder Structure

```
lib/
  core/       -- app-wide config, theming, routing setup
  shared/     -- shared widgets used across roles
  features/
    student/
    parent/
    staff/
test/
  features/
    student/
```

## 6. Known Bugs From Original Site (Student Spec) — Stance Needed

These exist in the current live site's behavior. Default stance below unless overridden:
**replicate for now, track as a fix-later backlog item** rather than silently fixing
(avoids undocumented scope creep vs. the spec).

- [ ] Silent birth-date field failure
- [ ] Grade score input allows values outside 1–100 clamp (breaks average calculation)
- [ ] Clubs auto-fill from anchor major is broken
- [ ] "Mark as Ready" on essay/application sections can be bypassed without meeting criteria

*(Confirm/adjust this list against the full behavioral spec doc before Day 5–6 work,
since these live in Application Materials / My Grades / My Clubs.)*

## 7. Development Rhythm

**Not** test-last-day-only. Each coding day = build during the day, **last 1–2 hours
of each day = write unit/widget tests for what was just built.** Day 7 shifts from
"the only testing day" to integration-test + polish + buffer day.

## 8. 7-Day Plan (Student Role) — Day 0 = today, prep only

**Day 0 — Foundation (no screens)**
- Lock decisions (this doc)
- Install dependencies
- Folder skeleton (student/parent/staff, core, shared)
- Data models for all 6 Pathway forms (from field/datatype doc)
- Skeleton routing: Login → Choose Role → Student Homepage (placeholder screens, real nav)
- Shared theming (colors, typography, buttons)

**Day 1 — Login + Homepage + shell**
- Choose Role screen (Student functional; Parent/Staff visibly disabled/"coming soon")
- Student Login Form, generic single-bucket error (no field-specific error, per spec)
- Student Homepage, all 3 entry points wired (Dashboard / Pathway / Nav Grid)
- Sign out flow
- Last 1–2 hrs: tests for login validation + routing

**Day 2 — Standalone forms**
- Student's Profile (decide birth-date bug stance concretely here)
- My Tests (test-type rows, duplicate-blocking logic)
- My Grades (6 semester tabs, fixed + custom subjects, score-clamp bug stance)
- Last 1–2 hrs: unit tests for grade average calc, test-type duplicate rules

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