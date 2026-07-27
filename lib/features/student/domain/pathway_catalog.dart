/// Pathways — Runata's signature country guides. Pulled directly from
/// the JS's `PATHWAY_FALLBACK` array. Tracing `beLoadPathways()` shows it
/// always hits the `if(!SB){pathwayDocs=PATHWAY_FALLBACK.slice();return;}`
/// branch in this rebuild — there's no Supabase connection configured
/// (planning.md: "Backend: Local-only for now — no Supabase credentials
/// on hand yet") — so this is genuinely just these 2 static entries, not
/// a dynamic fetch. No Hive model, no repository, no controller: this is
/// read-only reference content prepared by the school, not user data, so
/// there's nothing here to persist.
///
/// **Flag icons use the real source images, not emoji.** The JS's
/// `COUNTRY_FLAGS` embeds actual PNG images (base64-encoded in the JS
/// itself) rather than Unicode flag characters — matched here via
/// `assets/images/germany.png`/`assets/images/china.png`, the same
/// source images, not a substitute.
library;

class PathwayDoc {
  const PathwayDoc({
    required this.id,
    required this.title,
    required this.intro,
    this.url,
  });

  final String id;
  final String title;
  final String intro;

  /// Nullable to mirror the JS's optional `url` field faithfully — every
  /// entry here happens to have one, but the screen still renders the
  /// JS's "No document link yet." fallback branch for a doc that
  /// doesn't, rather than assuming one always exists.
  final String? url;
}

/// `const PATHWAY_FALLBACK=[...]` equivalent — order and content match
/// the JS verbatim.
const pathwayDocs = <PathwayDoc>[
  PathwayDoc(
    id: 'germany',
    title: 'Germany Pathway',
    intro:
        'Studying in Germany offers world-class, often tuition-free public universities, strong engineering and sciences, and pathways in English and German. This guide walks you through requirements, timelines, and how Runata supports your application.',
    url: 'https://www.canva.com/design/DAHNAo6eJxo/mGhwrTTcvfHN-wHza1mYjw/view',
  ),
  PathwayDoc(
    id: 'china',
    title: 'China Pathway',
    intro:
        'China hosts globally ranked universities with growing English-taught programmes and generous scholarships. This guide introduces the application process, language options, and the support Runata provides along the way.',
    url: 'https://www.canva.com/design/DAHIBBYNRAI/KgPZR3JxeUr3DUWcLVSTSA/view',
  ),
];

/// `flagFor(title, cls)` equivalent, restricted to the asset-path lookup
/// (the actual `Image`/fallback-emoji rendering is the screen's job, not
/// this pure-data file's). Case-insensitive substring match against the
/// title, same as the JS's `t.toLowerCase().includes(k.toLowerCase())`.
/// Returns `null` (screen falls back to 🌏) when nothing matches, same
/// as the JS's `flagFor` returning `null` for an unrecognized country.
String? flagAssetFor(String title) {
  final t = title.toLowerCase();
  if (t.contains('germany')) return 'assets/images/germany.png';
  if (t.contains('china')) return 'assets/images/china.png';
  return null;
}

/// `d.intro.slice(0,90) + (d.intro.length>90 ? '…' : '')` equivalent,
/// used by the list view's cards (the detail view always shows the
/// FULL intro, untruncated).
String truncatedIntro(String intro, {int maxLength = 90}) {
  if (intro.isEmpty) return 'Open to read more';
  if (intro.length <= maxLength) return intro;
  return '${intro.substring(0, maxLength)}…';
}
