/// One curated university entry shown as a card on Find Universities.
/// Mirrors one object in the JS `UNIVERSITIES` map.
class UniversityEntry {
  const UniversityEntry({
    required this.name,
    required this.fields,
    this.type,
    this.ielts,
    required this.requirements,
  });

  final String name;

  /// Null means "matches every field" (JS's `f:"all"`). Non-null means
  /// only students targeting one of these fields (see
  /// `majors_catalog.dart`'s `MajorCatalogEntry.field`) should see this
  /// university for their major.
  final List<String>? fields;

  /// "Negeri"/"Swasta" — only ever present for Indonesian universities in
  /// the source data; null everywhere else (no badge shown).
  final String? type;

  /// Required IELTS band, if the university lists one. Null means no
  /// IELTS requirement is tracked for this entry (JS's `ielts:null`) —
  /// distinct from "requirement is 0", which never occurs in the data.
  final double? ielts;

  final List<String> requirements;

  bool matchesField(String field) => fields == null || fields!.contains(field);
}

/// The curated per-country catalog — mirrors the JS `UNIVERSITIES` object,
/// including its key order (`UNI_COUNTRIES` = `Object.keys(UNIVERSITIES)`,
/// which JS preserves in insertion order).
final Map<String, List<UniversityEntry>> universitiesByCountry = {
  'Indonesia': [
    const UniversityEntry(
      name: 'Universitas Indonesia (UI)',
      fields: null,
      type: 'Negeri',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor yang baik',
        'Jalur SNBP (seleksi nilai rapor) atau SNBT (UTBK)',
        'Jalur Mandiri (SIMAK UI)',
        'Kelas Internasional: IELTS + tes mandiri',
      ],
    ),
    const UniversityEntry(
      name: 'Universitas Gadjah Mada (UGM)',
      fields: null,
      type: 'Negeri',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'Jalur SNBP / SNBT (UTBK)',
        'Jalur Mandiri (UM UGM)',
        'Program internasional (IUP): IELTS',
      ],
    ),
    const UniversityEntry(
      name: 'Institut Teknologi Bandung (ITB)',
      fields: ['Sciences', 'Engineering', 'Computing & Math', 'Design & Built Env', 'Business'],
      type: 'Negeri',
      ielts: null,
      requirements: [
        'Ijazah SMA (IPA untuk sains/teknik) + nilai rapor',
        'SNBP / SNBT (UTBK)',
        'Seleksi Mandiri ITB',
        'Portofolio untuk program seni/desain (FSRD)',
      ],
    ),
    const UniversityEntry(
      name: 'Universitas Airlangga (Unair)',
      fields: ['Health', 'Sciences', 'Business', 'Law & Politics'],
      type: 'Negeri',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'SNBP / SNBT (UTBK)',
        'Jalur Mandiri Unair',
        'IELTS untuk kelas internasional',
      ],
    ),
    const UniversityEntry(
      name: 'BINUS University',
      fields: null,
      type: 'Swasta',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'Tes masuk mandiri / jalur rapor',
        'Program internasional bisa minta IELTS',
        'Beasiswa & early admission tersedia',
      ],
    ),
    const UniversityEntry(
      name: 'Universitas Pelita Harapan (UPH)',
      fields: null,
      type: 'Swasta',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'Tes masuk mandiri UPH',
        'Beberapa program internasional minta IELTS',
        'Beasiswa prestasi tersedia',
      ],
    ),
    const UniversityEntry(
      name: 'Prasetiya Mulya University',
      fields: ['Business', 'Computing & Math'],
      type: 'Swasta',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'Tes potensi & wawancara',
        'Fokus bisnis & STEM terapan',
        'Early admission tersedia',
      ],
    ),
    const UniversityEntry(
      name: 'Sampoerna University',
      fields: null,
      type: 'Swasta',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'Tes masuk (kurikulum AS, gelar ganda)',
        'Pengantar bahasa Inggris — EPT/IELTS membantu',
        'Beasiswa tersedia',
      ],
    ),
    const UniversityEntry(
      name: 'President University',
      fields: null,
      type: 'Swasta',
      ielts: null,
      requirements: [
        'Ijazah SMA + nilai rapor',
        'Tes masuk mandiri',
        'Pengantar bahasa Inggris',
        'Beasiswa & koneksi industri (kawasan Jababeka)',
      ],
    ),
  ],
  'Australia': [
    const UniversityEntry(
      name: 'University of Melbourne',
      fields: null,
      ielts: 6.5,
      requirements: [
        'SMA diploma with a strong overall average',
        'IELTS 6.5 (no band below 6.0)',
        'Entry via a Foundation Year (Trinity College)',
        'SAT not required',
      ],
    ),
    const UniversityEntry(
      name: 'Monash University',
      fields: null,
      ielts: 6.5,
      requirements: [
        'SMA diploma with a good average',
        'IELTS 6.5',
        'Monash College Foundation pathway',
        'SAT not required',
      ],
    ),
    const UniversityEntry(
      name: 'University of Queensland',
      fields: ['Sciences', 'Health', 'Engineering', 'Business', 'Computing & Math'],
      ielts: 6.5,
      requirements: [
        'SMA diploma with a good average',
        'IELTS 6.5',
        'Foundation Year pathway',
        'SAT not required',
      ],
    ),
    const UniversityEntry(
      name: 'RMIT University',
      fields: ['Design & Built Env', 'Arts & Media', 'Computing & Math', 'Business', 'Engineering'],
      ielts: 6.5,
      requirements: [
        'SMA diploma',
        'IELTS 6.5',
        'Diploma or Foundation pathway',
        'Portfolio for design programs',
      ],
    ),
  ],
  'United Kingdom': [
    const UniversityEntry(
      name: 'University of Manchester',
      fields: null,
      ielts: 6.5,
      requirements: [
        'SMA diploma + a Foundation Year (no A-Level needed)',
        'IELTS 6.5',
        'UCAS personal statement',
        'One academic reference',
      ],
    ),
    const UniversityEntry(
      name: 'University of Leeds',
      fields: null,
      ielts: 6.5,
      requirements: [
        'SMA diploma + International Foundation Year',
        'IELTS 6.5',
        'UCAS personal statement',
        'Academic reference',
      ],
    ),
    const UniversityEntry(
      name: 'University of the Arts London (UAL)',
      fields: ['Arts & Media', 'Design & Built Env'],
      ielts: 6.0,
      requirements: [
        'SMA diploma + Art & Design Foundation',
        'Creative portfolio (required)',
        'IELTS 6.0',
        'Statement of purpose',
      ],
    ),
    const UniversityEntry(
      name: 'Coventry University',
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma + International Year One',
        'IELTS 6.0',
        'Personal statement',
        'Academic reference',
      ],
    ),
  ],
  'United States': [
    const UniversityEntry(
      name: 'Arizona State University',
      fields: null,
      ielts: 6.5,
      requirements: [
        'High-school diploma + transcript (GPA ~3.0)',
        'IELTS 6.5 or TOEFL',
        'SAT optional (test-optional)',
        'Essays + activities list',
      ],
    ),
    const UniversityEntry(
      name: 'Purdue University',
      fields: ['Engineering', 'Computing & Math', 'Sciences', 'Business'],
      ielts: 6.5,
      requirements: [
        'High-school diploma + transcript (GPA ~3.2)',
        'IELTS 6.5 or TOEFL',
        'SAT optional',
        'Essays + recommendation letters',
      ],
    ),
    const UniversityEntry(
      name: 'University of Oregon',
      fields: null,
      ielts: 6.5,
      requirements: [
        'High-school diploma + transcript (GPA ~3.0)',
        'IELTS 6.5 or TOEFL',
        'SAT optional',
        'Personal essay',
      ],
    ),
    const UniversityEntry(
      name: 'Drexel University',
      fields: ['Engineering', 'Business', 'Health', 'Computing & Math', 'Design & Built Env'],
      ielts: 6.5,
      requirements: [
        'High-school diploma + transcript (GPA ~3.0)',
        'IELTS 6.5 or TOEFL',
        'SAT optional',
        'Essays; portfolio for design',
      ],
    ),
  ],
  'Singapore': [
    const UniversityEntry(
      name: 'James Cook University (Singapore)',
      fields: ['Business', 'Sciences', 'Health', 'Computing & Math'],
      ielts: 6.5,
      requirements: [
        'SMA diploma',
        'IELTS 6.5',
        'Direct or Foundation pathway',
        'Personal statement',
      ],
    ),
    const UniversityEntry(
      name: 'Singapore Institute of Management (SIM)',
      fields: ['Business', 'Computing & Math', 'Arts & Media'],
      ielts: 6.5,
      requirements: [
        'SMA diploma',
        'IELTS 6.5',
        'Diploma pathway available',
        'Transcript',
      ],
    ),
    const UniversityEntry(
      name: 'Curtin Singapore',
      fields: ['Business', 'Engineering', 'Computing & Math'],
      ielts: 6.5,
      requirements: [
        'SMA diploma',
        'IELTS 6.5',
        'Foundation or diploma pathway',
        'Transcript',
      ],
    ),
  ],
  'Netherlands': [
    const UniversityEntry(
      name: 'Hanze University of Applied Sciences',
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma',
        'IELTS 6.0',
        'Direct entry (applied sciences)',
        'Motivation letter',
      ],
    ),
    const UniversityEntry(
      name: 'The Hague University of Applied Sciences',
      fields: ['Business', 'Law & Politics', 'Computing & Math'],
      ielts: 6.0,
      requirements: [
        'SMA diploma',
        'IELTS 6.0',
        'Direct entry',
        'Motivation letter (some programs have a numerus fixus)',
      ],
    ),
    const UniversityEntry(
      name: 'Amsterdam University of Applied Sciences',
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma',
        'IELTS 6.0',
        'Direct entry',
        'Motivation letter',
      ],
    ),
  ],
  'China': [
    const UniversityEntry(
      name: 'Zhejiang University',
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma + transcript',
        'English-taught: IELTS 6.0',
        'Chinese-taught: HSK 4–5 (or CSCA)',
        'Study plan + passport copy',
      ],
    ),
    const UniversityEntry(
      name: 'Fudan University',
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma + transcript',
        'English-taught: IELTS 6.0',
        'Chinese-taught: HSK 4–5',
        'Study plan + recommendation',
      ],
    ),
    const UniversityEntry(
      name: 'Tongji University',
      fields: ['Engineering', 'Design & Built Env', 'Sciences', 'Business'],
      ielts: 6.0,
      requirements: [
        'SMA diploma + transcript',
        'English-taught: IELTS 6.0',
        'Chinese-taught: CSCA / HSK',
        'Study plan; portfolio for design',
      ],
    ),
  ],
  'Malaysia': [
    const UniversityEntry(
      name: "Taylor's University",
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma',
        'IELTS 6.0',
        'Direct or Foundation pathway',
        'Transcript',
      ],
    ),
    const UniversityEntry(
      name: 'Monash University Malaysia',
      fields: null,
      ielts: 6.5,
      requirements: [
        'SMA diploma with a good average',
        'IELTS 6.5',
        'Foundation pathway',
        'Transcript',
      ],
    ),
    const UniversityEntry(
      name: 'Sunway University',
      fields: null,
      ielts: 6.0,
      requirements: [
        'SMA diploma',
        'IELTS 6.0',
        'Direct or Foundation pathway',
        'Transcript',
      ],
    ),
  ],
};

/// Country list in the same order as `universitiesByCountry`'s keys
/// (mirrors JS's `UNI_COUNTRIES = Object.keys(UNIVERSITIES)`).
final List<String> uniCountries = universitiesByCountry.keys.toList();

/// One (name, country) pair from the JS `EXTRA_UNIS` bundled name list —
/// used only for the "add your own university" autocomplete, not shown as
/// a full card (no requirements/IELTS data for these).
class ExtraUniversity {
  const ExtraUniversity(this.name, this.country);
  final String name;
  final String country;
}

/// Starter set, same as the JS comment notes: "to load the full ~10k
/// worldwide list, replace EXTRA_UNIS with the open Hipolabs dataset."
const List<ExtraUniversity> extraUniversities = [
  ExtraUniversity('Institut Pertanian Bogor (IPB University)', 'Indonesia'),
  ExtraUniversity('Universitas Diponegoro (Undip)', 'Indonesia'),
  ExtraUniversity('Universitas Padjadjaran (Unpad)', 'Indonesia'),
  ExtraUniversity('Institut Teknologi Sepuluh Nopember (ITS)', 'Indonesia'),
  ExtraUniversity('Universitas Brawijaya', 'Indonesia'),
  ExtraUniversity('Universitas Sebelas Maret (UNS)', 'Indonesia'),
  ExtraUniversity('Universitas Hasanuddin (Unhas)', 'Indonesia'),
  ExtraUniversity('Universitas Udayana', 'Indonesia'),
  ExtraUniversity('Universitas Sumatera Utara (USU)', 'Indonesia'),
  ExtraUniversity('Universitas Negeri Jakarta (UNJ)', 'Indonesia'),
  ExtraUniversity('Universitas Negeri Yogyakarta (UNY)', 'Indonesia'),
  ExtraUniversity('Universitas Andalas', 'Indonesia'),
  ExtraUniversity('Universitas Jember', 'Indonesia'),
  ExtraUniversity('Universitas Negeri Semarang (UNNES)', 'Indonesia'),
  ExtraUniversity('UPN Veteran Jakarta', 'Indonesia'),
  ExtraUniversity('Universitas Katolik Parahyangan (Unpar)', 'Indonesia'),
  ExtraUniversity('Universitas Kristen Petra', 'Indonesia'),
  ExtraUniversity('Universitas Atma Jaya', 'Indonesia'),
  ExtraUniversity('Universitas Trisakti', 'Indonesia'),
  ExtraUniversity('Universitas Tarumanagara (Untar)', 'Indonesia'),
  ExtraUniversity('Telkom University', 'Indonesia'),
  ExtraUniversity('Universitas Multimedia Nusantara (UMN)', 'Indonesia'),
  ExtraUniversity('Universitas Ciputra', 'Indonesia'),
  ExtraUniversity('Universitas Gunadarma', 'Indonesia'),
  ExtraUniversity('Universitas Islam Indonesia (UII)', 'Indonesia'),
  ExtraUniversity('Universitas Surabaya (Ubaya)', 'Indonesia'),
  ExtraUniversity('Universitas Kristen Maranatha', 'Indonesia'),
  ExtraUniversity('Swiss German University', 'Indonesia'),
  ExtraUniversity('University of Sydney', 'Australia'),
  ExtraUniversity('UNSW Sydney', 'Australia'),
  ExtraUniversity('Australian National University (ANU)', 'Australia'),
  ExtraUniversity('University of Adelaide', 'Australia'),
  ExtraUniversity('University of Western Australia (UWA)', 'Australia'),
  ExtraUniversity('University of Technology Sydney (UTS)', 'Australia'),
  ExtraUniversity('Deakin University', 'Australia'),
  ExtraUniversity('Griffith University', 'Australia'),
  ExtraUniversity('Macquarie University', 'Australia'),
  ExtraUniversity('Queensland University of Technology (QUT)', 'Australia'),
  ExtraUniversity('University College London (UCL)', 'United Kingdom'),
  ExtraUniversity("King's College London", 'United Kingdom'),
  ExtraUniversity('University of Edinburgh', 'United Kingdom'),
  ExtraUniversity('University of Birmingham', 'United Kingdom'),
  ExtraUniversity('University of Sheffield', 'United Kingdom'),
  ExtraUniversity('University of Nottingham', 'United Kingdom'),
  ExtraUniversity('University of Glasgow', 'United Kingdom'),
  ExtraUniversity('University of Liverpool', 'United Kingdom'),
  ExtraUniversity('University of Southampton', 'United Kingdom'),
  ExtraUniversity('Newcastle University', 'United Kingdom'),
  ExtraUniversity('University of Sussex', 'United Kingdom'),
  ExtraUniversity('University of Reading', 'United Kingdom'),
  ExtraUniversity('University of Washington', 'United States'),
  ExtraUniversity('Pennsylvania State University', 'United States'),
  ExtraUniversity('Michigan State University', 'United States'),
  ExtraUniversity('University of Illinois Chicago', 'United States'),
  ExtraUniversity('San Jose State University', 'United States'),
  ExtraUniversity('University of Texas at Dallas', 'United States'),
  ExtraUniversity('Northeastern University', 'United States'),
  ExtraUniversity('University of South Florida', 'United States'),
  ExtraUniversity('National University of Singapore (NUS)', 'Singapore'),
  ExtraUniversity('Nanyang Technological University (NTU)', 'Singapore'),
  ExtraUniversity('Singapore Management University (SMU)', 'Singapore'),
  ExtraUniversity('Singapore University of Technology and Design (SUTD)', 'Singapore'),
  ExtraUniversity('University of Amsterdam', 'Netherlands'),
  ExtraUniversity('Erasmus University Rotterdam', 'Netherlands'),
  ExtraUniversity('University of Groningen', 'Netherlands'),
  ExtraUniversity('Tilburg University', 'Netherlands'),
  ExtraUniversity('Leiden University', 'Netherlands'),
  ExtraUniversity('Radboud University', 'Netherlands'),
  ExtraUniversity('Maastricht University', 'Netherlands'),
  ExtraUniversity('Tsinghua University', 'China'),
  ExtraUniversity('Peking University', 'China'),
  ExtraUniversity('Shanghai Jiao Tong University', 'China'),
  ExtraUniversity('Nanjing University', 'China'),
  ExtraUniversity('Wuhan University', 'China'),
  ExtraUniversity('Sun Yat-sen University', 'China'),
  ExtraUniversity('University of Malaya (UM)', 'Malaysia'),
  ExtraUniversity('Universiti Kebangsaan Malaysia (UKM)', 'Malaysia'),
  ExtraUniversity('Universiti Putra Malaysia (UPM)', 'Malaysia'),
  ExtraUniversity('UCSI University', 'Malaysia'),
  ExtraUniversity('INTI International University', 'Malaysia'),
  ExtraUniversity('Asia Pacific University (APU)', 'Malaysia'),
  ExtraUniversity('Multimedia University (MMU)', 'Malaysia'),
  ExtraUniversity('HELP University', 'Malaysia'),
];

/// Finds the curated catalog entry for [name] in [country], if any.
///
/// A shortlist row ([UniversityTarget]) only stores the university's NAME
/// and country — not a live reference to its catalog entry — so My
/// Shortlist needs this to show real requirements/IELTS for a
/// previously-added target. Returns null for a custom (student-typed)
/// university that isn't in the curated catalog at all.
UniversityEntry? findUniversityEntry(String country, String name) {
  for (final u in universitiesByCountry[country] ?? const []) {
    if (u.name == name) return u;
  }
  return null;
}

/// Every known university name for [country] — the curated cards PLUS the
/// extra autocomplete-only names, deduped and sorted. Mirrors JS's
/// `catalogFor(country)`, which draws from a combined name catalog for the
/// "add your own university" `<datalist>`. The source's `UNI_CATALOG`
/// itself wasn't provided — only `UNIVERSITIES` and `EXTRA_UNIS` — so this
/// combines both of those rather than guessing at a third data source.
List<String> catalogFor(String country) {
  final names = <String>{
    for (final u in universitiesByCountry[country] ?? const []) u.name,
    for (final e in extraUniversities)
      if (e.country == country) e.name,
  };
  final sorted = names.toList()..sort();
  return sorted;
}