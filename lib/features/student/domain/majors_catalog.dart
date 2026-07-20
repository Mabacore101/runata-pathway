/// One entry in the majors catalog shown on Explore Majors' "browse what's
/// on offer" grid (mirrors the JS's `MAJORS.map(...)` catalog cards).
class MajorCatalogEntry {
  const MajorCatalogEntry({
    required this.major,
    required this.field,
    this.description = '',
    this.jobs = '',
  });

  final String major;
  final String field;
  final String description;
  final String jobs;
}

/// The real majors catalog — replaces the earlier 5-entry placeholder.
/// day3-trimmed-source.md deliberately omitted the actual `MAJORS` data
/// array (a data table, not logic, same reasoning Day 2 deferred the full
/// `CURRICULUM` object until it was actually needed); this is that real
/// content, supplied directly rather than pulled from source.
const majorCatalog = <MajorCatalogEntry>[
  MajorCatalogEntry(
    major: 'Accounting',
    field: 'Business',
    description:
        'Recording, analysing and reporting the finances of organisations.',
    jobs: 'Auditor, Tax consultant, Financial accountant, CFO',
  ),
  MajorCatalogEntry(
    major: 'Economics',
    field: 'Business',
    description:
        'How societies use resources — markets, policy and decision-making.',
    jobs: 'Economist, Policy analyst, Market analyst, Banker',
  ),
  MajorCatalogEntry(
    major: 'Entrepreneurship',
    field: 'Business',
    description: 'Building and running new ventures from idea to launch.',
    jobs: 'Founder, Product manager, Business developer, Consultant',
  ),
  MajorCatalogEntry(
    major: 'Data Science',
    field: 'Computing & Math',
    description:
        'Turning data into insight using statistics and programming.',
    jobs: 'Data scientist, ML engineer, Analyst, BI developer',
  ),
  MajorCatalogEntry(
    major: 'Computer Science',
    field: 'Computing & Math',
    description: 'Software, algorithms and the systems that run computers.',
    jobs: 'Software engineer, Cybersecurity, AI engineer, Architect',
  ),
  MajorCatalogEntry(
    major: 'Mechanical Engineering',
    field: 'Engineering',
    description: 'Designing machines, engines and mechanical systems.',
    jobs: 'Mechanical engineer, Automotive/Aerospace, Robotics, R&D',
  ),
  MajorCatalogEntry(
    major: 'Civil Engineering',
    field: 'Engineering',
    description:
        'Designing and building infrastructure — roads, bridges, buildings.',
    jobs: 'Civil/Structural engineer, Project manager, Planner',
  ),
  MajorCatalogEntry(
    major: 'Medicine',
    field: 'Health',
    description: 'Diagnosing and treating illness; the science of human health.',
    jobs: 'Doctor, Surgeon, Medical researcher, Public health',
  ),
  MajorCatalogEntry(
    major: 'Pharmacy',
    field: 'Health',
    description: 'Medicines — how they work, are made and used safely.',
    jobs: 'Pharmacist, Pharmacologist, Clinical research, Regulatory',
  ),
  MajorCatalogEntry(
    major: 'Law',
    field: 'Law & Politics',
    description: 'Legal systems, rights and how rules govern society.',
    jobs: 'Lawyer, Corporate counsel, Judge, Compliance officer',
  ),
  MajorCatalogEntry(
    major: 'International Relations',
    field: 'Law & Politics',
    description: 'Global politics, diplomacy and cross-border affairs.',
    jobs: 'Diplomat, Policy analyst, NGO/UN officer, Foreign service',
  ),
  MajorCatalogEntry(
    major: 'Architecture',
    field: 'Design & Built Env',
    description:
        'Designing buildings and spaces — form, function and structure.',
    jobs: 'Architect, Urban designer, Interior architect, Planner',
  ),
  MajorCatalogEntry(
    major: 'Graphic Design',
    field: 'Arts & Media',
    description: 'Visual communication through type, image and layout.',
    jobs: 'Graphic/UX designer, Art director, Brand designer, Illustrator',
  ),
  MajorCatalogEntry(
    major: 'Communications',
    field: 'Arts & Media',
    description: 'Media, messaging and how information moves in society.',
    jobs: 'PR specialist, Journalist, Content strategist, Producer',
  ),
  MajorCatalogEntry(
    major: 'Biology',
    field: 'Sciences',
    description:
        'Living organisms — from cells and genes to whole ecosystems.',
    jobs: 'Biologist, Biotech researcher, Healthcare, Conservation',
  ),
  MajorCatalogEntry(
    major: 'Physics',
    field: 'Sciences',
    description: 'Matter, energy and the fundamental laws of the universe.',
    jobs: 'Physicist, Engineer, Quant analyst, Research scientist',
  ),
  MajorCatalogEntry(
    major: 'Psychology',
    field: 'Sciences',
    description: 'The mind and behaviour — how people think, feel and act.',
    jobs: 'Psychologist, Counsellor, UX/HR researcher, Clinician',
  ),
];

MajorCatalogEntry? catalogEntryFor(String major) {
  for (final entry in majorCatalog) {
    if (entry.major == major) return entry;
  }
  return null;
}