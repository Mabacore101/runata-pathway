/// Application Materials' shared scoring engine — ports the JS's `RUBRIC`
/// + `scoreDoc()`, plus the `wc`/`paras`/`esc` primitives they depend on,
/// verbatim from `day6-trimmed-source.md`. Every regex, word-count bound,
/// and paragraph-count threshold below is copied unchanged, including one
/// label/logic mismatch in `personal`'s length criterion — see that
/// entry's own comment. `DOC_INFO`/`MATSTAT` are ported here too, since
/// they're small, static, and used by the same screens.
///
/// The JS's `has(t,re)=>re.test(t)` has no equivalent wrapper here —
/// Dart's `RegExp.hasMatch(String)` already does exactly that, just with
/// the receiver/argument order flipped, so every criterion below calls
/// `.hasMatch(t)` directly rather than going through an extra layer.
///
/// Pure functions/data only — no Hive, no Riverpod. [DocumentScoringContext]
/// is a plain data holder; populating it from `UniversityTargetsController`
/// + `clubSubmissionProvider` (the JS's `matCtx()` equivalent) is
/// screen/controller wiring for a later step, kept out of this file on
/// purpose so its tests can exercise every criterion against hand-built
/// contexts without needing a `ProviderContainer` at all.
library;

/// `wc=t=>(t.trim().match(/\S+/g)||[]).length` equivalent.
int wordCount(String text) => RegExp(r'\S+').allMatches(text.trim()).length;

/// `paras=t=>t.split(/\n\s*\n/).filter(x=>x.trim()).length` equivalent —
/// counts blank-line-separated blocks, ignoring any block that is itself
/// blank/whitespace-only.
int paragraphCount(String text) =>
    text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).length;

/// `esc=s=>(s||"").replace(/[.*+?^${}()|[\]\\]/g,"\\$&")` equivalent —
/// this is specifically the JS's REGEX-escape `esc` (a same-named but
/// differently-behaved HTML-escape `esc` exists elsewhere in the source;
/// this file only needs the regex one, since it's the one `RUBRIC`'s
/// major/country checks actually call). Needed because
/// [DocumentScoringContext.major]/[DocumentScoringContext.country] are
/// free text a student typed elsewhere in the app (Explore Majors / Find
/// Universities) — without escaping, a major/university name containing
/// regex metacharacters (e.g. "C++ (Hons.)") would either throw or
/// silently mismatch when dropped straight into a `RegExp`.
String escapeForRegex(String input) => input.replaceAllMapped(
      RegExp(r'[.*+?^${}()|\[\]\\]'),
      (m) => '\\${m[0]}',
    );

/// Read-only context `scoreDoc` checks certain criteria against — mirrors
/// the JS's `ctx` object (`{major, country}`), itself read from the
/// student's first Target Universities entry for their anchor major
/// (`uni[stu.n].targets[0]`).
class DocumentScoringContext {
  const DocumentScoringContext({this.major, this.country});

  final String? major;
  final String? country;

  static const empty = DocumentScoringContext();
}

/// One rubric line — mirrors one `{t, ok, tip}` entry in the JS's
/// `RUBRIC` arrays.
class RubricCriterion {
  const RubricCriterion({
    required this.title,
    required this.isMet,
    required this.tip,
  });

  final String title;
  final bool Function(String text, DocumentScoringContext ctx) isMet;
  final String tip;
}

/// One scored criterion — mirrors one entry of `scoreDoc`'s `res` array.
class ScoredCriterion {
  const ScoredCriterion({
    required this.title,
    required this.met,
    required this.tip,
  });

  final String title;
  final bool met;
  final String tip;
}

/// `scoreDoc`'s full return shape (`{res, met, total}`).
class DocScore {
  const DocScore({
    required this.results,
    required this.met,
    required this.total,
  });

  final List<ScoredCriterion> results;
  final int met;
  final int total;
}

/// `function scoreDoc(k,text,ctx){const cr=RUBRIC[k]||[];const t=text||"";
/// const res=cr.map(c=>({t:c.t,ok:!!c.ok(t,ctx),tip:c.tip}));
/// return{res,met:res.filter(r=>r.ok).length,total:cr.length};}` equivalent.
DocScore scoreDoc(String docKey, String? text, DocumentScoringContext ctx) {
  final criteria = documentRubric[docKey] ?? const <RubricCriterion>[];
  final t = text ?? '';
  final results = [
    for (final c in criteria)
      ScoredCriterion(title: c.title, met: c.isMet(t, ctx), tip: c.tip),
  ];
  return DocScore(
    results: results,
    met: results.where((r) => r.met).length,
    total: criteria.length,
  );
}

/// `const RUBRIC={...}` equivalent — 5 text-kind docs only. Recommendation
/// Letters (`recletter`, upload-kind) has no entry here, same as the JS
/// (`RUBRIC[k]||[]` falls back to an empty list for it — [scoreDoc]
/// relies on that fallback rather than this map special-casing upload
/// kinds itself).
final Map<String, List<RubricCriterion>> documentRubric = {
  'personal': [
    RubricCriterion(
      title: 'Clear motivation for the subject',
      isMet: (t, c) => RegExp(
            r'passion|motivat|interest|fascinat|drawn|inspired|why i',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Open with why this subject genuinely excites you.',
    ),
    RubricCriterion(
      title: 'Specific examples or evidence',
      isMet: (t, c) => RegExp(
            r'project|competition|olympiad|internship|research|volunteer|for example|when i|built|led',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Add a concrete example — a project, competition, or experience.',
    ),
    RubricCriterion(
      title: 'Connects to the chosen course',
      isMet: (t, c) =>
          RegExp(r'course|programme|program|degree|field|study', caseSensitive: false)
              .hasMatch(t) ||
          (c.major != null &&
              c.major!.isNotEmpty &&
              RegExp(escapeForRegex(c.major!.split(' ').first), caseSensitive: false)
                  .hasMatch(t)),
      tip: 'Name the course/major and why it fits you.',
    ),
    RubricCriterion(
      title: 'Shows skills or achievements',
      isMet: (t, c) => RegExp(
            r'led|created|founded|won|achieved|developed|organi[sz]ed|managed|award',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Highlight 1–2 achievements using action verbs.',
    ),
    RubricCriterion(
      title: 'Right length (≈450–650 words)',
      // NOTE: label says 450–650, the JS's actual bound is 450–700 —
      // preserved verbatim. This mismatch exists in the source itself
      // (day6-trimmed-source.md line 266), not introduced by this port.
      isMet: (t, c) {
        final n = wordCount(t);
        return n >= 450 && n <= 700;
      },
      tip: 'Aim for ~500–650 words (UCAS limit ≈4000 characters).',
    ),
    RubricCriterion(
      title: 'Clear structure (3+ paragraphs)',
      isMet: (t, c) => paragraphCount(t) >= 3,
      tip: 'Use intro, body (evidence), and a forward-looking ending.',
    ),
  ],
  'commonapp': [
    RubricCriterion(
      title: 'Personal story or hook',
      isMet: (t, c) => RegExp(
            r'i remember|one day|growing up|the first time|when i',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Start with a vivid moment, not a summary.',
    ),
    RubricCriterion(
      title: 'Reflection and growth',
      isMet: (t, c) => RegExp(
            r'learned|reali[sz]ed|grew|changed|taught me|understood|now i',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Show what you learned or how you changed.',
    ),
    RubricCriterion(
      title: 'Specific, vivid detail',
      isMet: (t, c) =>
          RegExp(r'\d').hasMatch(t) ||
          RegExp(r'because|for instance|specifically|named|called', caseSensitive: false)
              .hasMatch(t),
      tip: 'Add concrete detail — names, numbers, places.',
    ),
    RubricCriterion(
      title: 'Right length (250–650 words)',
      isMet: (t, c) {
        final n = wordCount(t);
        return n >= 250 && n <= 650;
      },
      tip: 'Common App essays are 250–650 words.',
    ),
    RubricCriterion(
      title: 'Stays personal (not a CV)',
      isMet: (t, c) => paragraphCount(t) >= 3,
      tip: 'Tell one story in prose — avoid bullet lists.',
    ),
  ],
  'studyplan': [
    RubricCriterion(
      title: 'Academic background',
      isMet: (t, c) => RegExp(
            r'background|studied|high school|sma|gpa|grade|subjects',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Summarise your SMA background and key subjects.',
    ),
    RubricCriterion(
      title: 'Why this country / university',
      isMet: (t, c) =>
          (c.country != null &&
              c.country!.isNotEmpty &&
              RegExp(escapeForRegex(c.country!), caseSensitive: false).hasMatch(t)) ||
          RegExp(r'university|china|why|chosen', caseSensitive: false).hasMatch(t),
      tip: 'Explain why this country and university specifically.',
    ),
    RubricCriterion(
      title: 'Clear study objectives',
      isMet: (t, c) => RegExp(
            r'objective|aim|goal|plan to study|focus on|intend',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'State what you aim to learn and focus on.',
    ),
    RubricCriterion(
      title: 'Career plan after graduation',
      isMet: (t, c) => RegExp(
            r'career|after graduat|future|aspire|become|plan to work',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Describe your career goal after the degree.',
    ),
    RubricCriterion(
      title: 'Right length (≈400–800 words)',
      isMet: (t, c) {
        final n = wordCount(t);
        return n >= 400 && n <= 800;
      },
      tip: 'Study plans are usually ~500–800 words.',
    ),
  ],
  'sop': [
    RubricCriterion(
      title: 'Clear goals / purpose',
      isMet: (t, c) =>
          RegExp(r'goal|purpose|aim|aspire|objective', caseSensitive: false).hasMatch(t),
      tip: 'State your purpose and goals upfront.',
    ),
    RubricCriterion(
      title: 'Fit with the program',
      isMet: (t, c) =>
          RegExp(r'program|course|faculty|research|fit|because', caseSensitive: false)
              .hasMatch(t) ||
          (c.major != null &&
              c.major!.isNotEmpty &&
              RegExp(escapeForRegex(c.major!.split(' ').first), caseSensitive: false)
                  .hasMatch(t)),
      tip: 'Explain why this program fits your goals.',
    ),
    RubricCriterion(
      title: 'Relevant experience',
      isMet: (t, c) =>
          RegExp(r'experience|project|intern|research|work|volunteer', caseSensitive: false)
              .hasMatch(t),
      tip: 'Reference concrete, relevant experience.',
    ),
    RubricCriterion(
      title: 'Specific, not generic',
      isMet: (t, c) =>
          RegExp(r'\d').hasMatch(t) ||
          RegExp(r'specifically|for example|named', caseSensitive: false).hasMatch(t),
      tip: 'Replace generic claims with specific evidence.',
    ),
    RubricCriterion(
      title: 'Right length (≈400–800 words)',
      isMet: (t, c) {
        final n = wordCount(t);
        return n >= 400 && n <= 800;
      },
      tip: 'Aim for ~500–800 words.',
    ),
  ],
  'cv': [
    RubricCriterion(
      title: 'Education & contact',
      isMet: (t, c) =>
          RegExp(r'education|sma|school|email|@', caseSensitive: false).hasMatch(t),
      tip: 'Include education and contact details.',
    ),
    RubricCriterion(
      title: 'Activities / experience',
      isMet: (t, c) => RegExp(
            r'club|volunteer|intern|committee|project|experience|leader',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'List clubs, experience, and roles.',
    ),
    RubricCriterion(
      title: 'Skills section',
      isMet: (t, c) =>
          RegExp(r'skill|language|software|proficien|tools', caseSensitive: false)
              .hasMatch(t),
      tip: 'Add a short skills section.',
    ),
    RubricCriterion(
      title: 'Achievements / awards',
      isMet: (t, c) => RegExp(
            r'award|won|achieved|certificate|winner|honou?r|finalist',
            caseSensitive: false,
          ).hasMatch(t),
      tip: 'Include awards or measurable achievements.',
    ),
    RubricCriterion(
      title: 'Concise (≤ ~600 words)',
      isMet: (t, c) {
        final n = wordCount(t);
        return n > 0 && n <= 600;
      },
      tip: 'Keep it to 1–2 pages — be concise.',
    ),
  ],
};

/// `const DOC_INFO={...}` equivalent — explanatory copy shown at the top
/// of each doc's screen. Deliberately kept as raw strings containing
/// literal `<b>...</b>`/`&amp;` markup, matching the JS's `innerHTML`
/// usage exactly — how the screen layer renders that (a small HTML-subset
/// parser vs. manually splitting on `<b>` tags into `TextSpan`s) is a
/// decision for that later step, not resolved here.
const Map<String, String> docInfo = {
  'personal':
      "<b>What is this?</b> The <b>UCAS</b> personal statement is the main essay UK universities read. UCAS (Universities &amp; Colleges Admissions Service) is the UK's central system where you apply to several universities with one application. One statement (~500–650 words) explains why you want this subject and why you're a strong fit.",
  'commonapp':
      "<b>What is this?</b> The <b>Common App</b> essay is the main personal essay for US universities. The Common Application is a shared platform used by hundreds of US universities, so one essay (250–650 words) reaches all of them. Tell one meaningful story about yourself.",
  'studyplan':
      "<b>What is this?</b> A <b>study plan</b> explains your academic background, why you chose this country and university, what you'll study, and your future goals. It's commonly required in China and some other countries.",
  'sop':
      "<b>What is this?</b> A <b>Statement of Purpose</b> (also called a motivation letter) explains your goals, why this program fits you, and your relevant experience. Many universities worldwide ask for one.",
  'cv':
      "<b>What is this?</b> A <b>CV / resume</b> is a one–two page summary of your education, activities, skills and achievements — kept short and factual.",
  'recletter':
      "<b>What is this?</b> A <b>recommendation letter</b> is written about you by a teacher who knows you well. Ask early, then add the file or a link here for your advisor to verify.",
};

/// `const MATSTAT=[...]` — kept here as the canonical status ORDER
/// reference (matches [DocumentStatus]'s declared order 1:1), even though
/// [DocumentStatus.label] is what screens actually read for display text.
/// `statCls` (the ns/dr/rv/fn → color mapping) is NOT ported here — colors
/// belong at the UI/theme layer, a later step, not in this pure-logic
/// file (see [DocumentStatusLabel] in `application_document_state.dart`
/// for the same separation already applied to status labels).
const List<String> matStatusOrder = ['Not started', 'Draft', 'In review', 'Final'];
