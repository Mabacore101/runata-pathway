import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/clubs_controller.dart';
import '../application/university_targets_controller.dart';
import '../domain/document_rubric.dart';

/// Mirrors the JS's `matCtx()`:
/// `const am=submissions[stu.n]&&submissions[stu.n].anchorMajor;
/// const tg=uni[stu.n]&&uni[stu.n].targets&&uni[stu.n].targets[0];
/// return{major:am||(tg?tg.major:"your major"),country:tg?tg.country:
/// "your target country",hasAnchor:!!am,hasTarget:!!tg};`
///
/// [major] prioritizes My Clubs' submitted anchor major over Find
/// Universities' first target — matching the JS's `am||...` fallback
/// order exactly. [country] only ever comes from the first target (the
/// JS has no clubs-derived country to fall back to). The "first target"
/// is read as written — the first one ever added overall, not filtered
/// to one matching the anchor major — same as the JS, which never
/// filters `uni[stu.n].targets` by major before indexing `[0]`.
class MaterialsContext {
  const MaterialsContext({
    required this.major,
    required this.country,
    required this.hasAnchor,
    required this.hasTarget,
  });

  final String? major;
  final String? country;
  final bool hasAnchor;
  final bool hasTarget;

  /// For [scoreDoc] — `null` when neither an anchor major nor a target
  /// exists. Deliberately NOT the JS's literal "your major"/"your target
  /// country" placeholder strings: the JS reuses that one fallback for
  /// both this screen's display line AND `scoreDoc`'s RUBRIC matching,
  /// which means an unset anchor/target makes the JS's version of
  /// `scoreDoc` search essay text for the literal word "your" (the first
  /// word of "your major") — a coincidental side effect of sharing one
  /// placeholder for two purposes, not an intentional check. Kept out of
  /// scoring here; the placeholder text still surfaces via
  /// [majorDisplayLabel]/[countryDisplayLabel] below, just never reaches
  /// RUBRIC matching.
  DocumentScoringContext get forScoring =>
      DocumentScoringContext(major: major, country: country);

  /// Feeds the essay screen's "tailored to X" line — mirrors the JS's
  /// `majLabel` EXACTLY, including which part is bolded: only the major
  /// name itself is wrapped in `<b>`, not the whole label. The caller is
  /// expected to render this through the same inline-bold parser
  /// `DOC_INFO` uses, not display it as plain text. Display-only; this
  /// placeholder text is never fed into [forScoring].
  String get majorDisplayLabel => hasAnchor
      ? 'your anchor major — <b>$major</b> (the main major you chose)'
      : '<b>${major ?? "your major"}</b>';

  /// Feeds the essay screen's "for applications to Y" line — mirrors the
  /// JS's `ctLabel` exactly, including that the fallback branch is NOT
  /// bolded at all (only the real country name is, when a target exists).
  String get countryDisplayLabel =>
      hasTarget ? '<b>$country</b>' : 'your target country (add one in Target universities)';
}

final materialsContextProvider = Provider<MaterialsContext>((ref) {
  final submission = ref.watch(clubSubmissionProvider);
  final anchorMajor = submission?.anchorMajor;

  final targets = ref.watch(universityTargetsControllerProvider);
  final firstTarget = targets.isNotEmpty ? targets.first : null;

  return MaterialsContext(
    major: anchorMajor ?? firstTarget?.major,
    country: firstTarget?.country,
    hasAnchor: anchorMajor != null,
    hasTarget: firstTarget != null,
  );
});
