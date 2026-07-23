/// Portfolio (Pathway form 6b) — catalog data. Pulled directly from the
/// original site's `PF_SUGGEST` object and `PF` table (day1-trimmed-
/// reference.md), same reasoning every other catalog file in this app
/// defers its data table until actually needed.
library;

/// Major-based suggestion banner content, keyed by [MajorCatalogEntry.
/// field] — every key here matches one of `majors_catalog.dart`'s field
/// values exactly (`Business`, `Sciences`, `Engineering`, `Computing &
/// Math`, `Design & Built Env`, `Arts & Media`, `Health`, `Law &
/// Politics`). Looked up via the submitted club selection's anchor major
/// → `catalogEntryFor(major)?.field` → this map — the JS's own
/// `fieldOf(am)` + `PF_SUGGEST[fld]` chain, ported directly rather than
/// re-derived, since `catalogEntryFor` already does exactly what
/// `fieldOf` did.
const portfolioFieldSuggestions = <String, String>{
  'Arts & Media':
      'Artworks, illustrations, designs, photos, showreels — show range and your process.',
  'Design & Built Env':
      'Design projects, models, drawings, CAD, sketches — include your process.',
  'Computing & Math':
      'Coding projects (GitHub), apps, data analyses, hackathon builds.',
  'Business':
      'Business plans, pitch decks, financial models, market research, mini-ventures.',
  'Sciences': 'Research projects, lab reports, science-fair work, experiments.',
  'Engineering': 'Prototypes, robotics, CAD, build logs, technical drawings.',
  'Health':
      'Research summaries, science projects, reflections from health volunteering.',
  'Law & Politics':
      'Essays, MUN position papers, debate cases, op-eds, writing samples.',
};

/// How strongly a portfolio matters for a given field of study — the
/// JS's `PF` table, shown in the "Do I need a portfolio?" explainer.
/// This content was dead code in the original site (`portfolioInfoHTML()`
/// was defined but never called from anywhere reachable) — day5-trimmed-
/// source.md's own note flags it as "genuinely load-bearing UX" worth
/// surfacing properly rather than a bug to replicate by leaving it
/// unreachable, same spirit as Section B's auto-fill fix.
enum PortfolioSuitabilityTone { required_, recommended, supporting }

class PortfolioSuitabilityRow {
  const PortfolioSuitabilityRow({
    required this.fields,
    required this.status,
    required this.examples,
    required this.tone,
  });

  final String fields;
  final String status;
  final String examples;
  final PortfolioSuitabilityTone tone;
}

const portfolioSuitabilityTable = <PortfolioSuitabilityRow>[
  PortfolioSuitabilityRow(
    fields: 'Art · DKV / Graphic Design · Music · Architecture · Film',
    status: 'Required — graded',
    examples: 'Artworks, designs, models, recordings, sketches + your process',
    tone: PortfolioSuitabilityTone.required_,
  ),
  PortfolioSuitabilityRow(
    fields: 'Computer Science · Data Science',
    status: 'Recommended',
    examples: 'GitHub projects, apps, hackathon builds, code samples',
    tone: PortfolioSuitabilityTone.recommended,
  ),
  PortfolioSuitabilityRow(
    fields: 'Business · Accounting · Management · Economics',
    status: 'Supporting',
    examples: 'Business plans, pitch decks, financial models, market research',
    tone: PortfolioSuitabilityTone.supporting,
  ),
  PortfolioSuitabilityRow(
    fields: 'Science · Engineering',
    status: 'Supporting',
    examples: 'Research projects, science-fair work, prototypes, lab reports',
    tone: PortfolioSuitabilityTone.supporting,
  ),
  PortfolioSuitabilityRow(
    fields: 'Law · International Relations · Communications',
    status: 'Supporting',
    examples: 'Essays, MUN position papers, articles, op-eds, writing samples',
    tone: PortfolioSuitabilityTone.supporting,
  ),
];
