import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mined from the original web app's `:root` CSS custom
/// properties (see `day1-trimmed-reference.md`, SECTION 1).
///
/// These are 1:1 color values — CSS shadows / gradients / flex layouts are
/// NOT transpiled literally, per the project brief. Flutter equivalents
/// (BoxShadow, LinearGradient, Row/Column) are built from these tokens
/// where a widget actually needs them, not copied rule-for-rule.
class AppColors {
  AppColors._();

  // Base surfaces
  static const bg = Color(0xFFEBF0EE);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF4F8F7);
  static const line = Color(0xFFE2E8E6);

  // Ink / text
  static const ink = Color(0xFF15302D);
  static const inkSoft = Color(0xFF46615D);
  static const muted = Color(0xFF6C817D);

  // Brand — teal (primary action color across the student UI)
  static const teal = Color(0xFF00857D);
  static const tealDeep = Color(0xFF006B63);
  static const tealSoft = Color(0xFFDBEDEB);

  // Accent — orange (warnings / secondary emphasis in the source)
  static const orange = Color(0xFFFF8F1C);
  static const orangeDeep = Color(0xFFDF7B0C);
  static const orangeSoft = Color(0xFFFFE8D0);

  // Sidebar palette (dashboard-only; kept here since a later day needs it)
  static const sidebar = Color(0xFF023A36);
  static const sideLine = Color(0xFF0E4F49);
  static const sideSoft = Color(0xFF0B4641);
  static const sideText = Color(0xFFBCD6D2);
  static const sideMut = Color(0xFF6E938E);

  // Status colors
  static const green = Color(0xFF0E8C6B);
  static const greenSoft = Color(0xFFD9EDE7);
  static const amber = Color(0xFFB07A12);
  static const amberSoft = Color(0xFFF9EBD2);
  static const red = Color(0xFFC2492E);
  static const redSoft = Color(0xFFF9E4DE);

  // Dashboard category colors (`.b-teal`/`.b-purple`/`.b-orange`/
  // `.b-green`/`.b-pink`/`.b-blue` in the CSS) — used by the side menu,
  // the 6 Overview mini-stats, and each detail panel's own accent.
  // `.b-teal`/`.b-orange`'s accent hex values (`#00857D`/`#DF7B0C`)
  // already match [teal]/[orangeDeep] exactly, so those two categories
  // reuse the existing tokens rather than adding near-duplicates; their
  // background tints (`#E4F4F2`/`#FFEBD6`) are close enough to
  // [tealSoft]/[orangeSoft] to reuse too. The other 4 categories
  // (purple/green/pink/blue) have no existing equivalent — `.b-green`
  // specifically is a distinct "grades category" color (`#1FA971`),
  // NOT the same green as the status [green] above (`#0E8C6B`) used for
  // "done"/"met" indicators elsewhere in the app — kept separate rather
  // than reused, since conflating "this is the grades category" with
  // "this thing is done" would be a real semantic mixup, not just a
  // cosmetic one.
  static const dashPurple = Color(0xFF6B4EF0);
  static const dashPurpleSoft = Color(0xFFEDE9FE);
  static const dashGreen = Color(0xFF1FA971);
  static const dashGreenSoft = Color(0xFFDFF5EA);
  static const dashPink = Color(0xFFE0518D);
  static const dashPinkSoft = Color(0xFFFCE4EF);
  static const dashBlue = Color(0xFF2E86DE);
  static const dashBlueSoft = Color(0xFFE3F0FC);
}

/// Font family helpers backed by `google_fonts`, replacing the CSS
/// `--disp` / `--body` / `--mono` vars.
///
/// google_fonts was chosen over manually bundling .ttf files because these
/// are literally Google Fonts already — the original site's `<head>` pulls
/// the exact same 3 families from fonts.googleapis.com. See PLANNING.md §4a.
///
/// Weight ranges below come from grepping every `--disp`/`--mono` usage in
/// the trimmed CSS reference (Day 0), not guessed:
///   --disp (Bricolage Grotesque): 600 / 700 / 800 — headings, card titles,
///     dashboard stats (`.tpUni`, `.dbig`, `.sesshead .cn`)
///   --mono (IBM Plex Mono): 400 / 600 / 700 — badges, IDs, step numbers,
///     "coming soon" tags (`.mstatC`, `.badge`, `.soontag`, `.stp .n`)
///   --body (Inter): the page-wide default; every element without an
///     explicit font-family override uses this.
///
/// IMPORTANT — release builds must not depend on network font-fetching.
/// See main.dart for `GoogleFonts.config.allowRuntimeFetching = false` and
/// the required bundled asset files under `assets/google_fonts/`.
class AppFonts {
  AppFonts._();

  static TextStyle display({
    FontWeight weight = FontWeight.w700,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.bricolageGrotesque(
      fontWeight: weight,
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body({
    FontWeight weight = FontWeight.w400,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontWeight: weight,
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    FontWeight weight = FontWeight.w400,
    double? fontSize,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.ibmPlexMono(
      fontWeight: weight,
      fontSize: fontSize,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}

ThemeData buildStudentTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: Brightness.light,
    primary: AppColors.teal,
    onPrimary: Colors.white,
    secondary: AppColors.orange,
    error: AppColors.red,
    surface: AppColors.surface,
  );

  // Inter as the base for every default text style (matches the CSS's
  // page-wide `body{font-family:var(--body)}` rule), with the specific
  // heading slots swapped to Bricolage Grotesque below.
  final baseTextTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    // `.appbar` in the original CSS has no explicit background — it just
    // sits on the page's own `var(--bg)`, not a separate white/branded
    // bar (confirmed in day1-trimmed-reference.md). `surfaceTintColor` +
    // `scrolledUnderElevation: 0` stop Material 3 from tinting/raising it
    // once content scrolls underneath, which would otherwise introduce a
    // shaded bar that isn't in the source spec.
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: AppColors.ink,
      iconTheme: const IconThemeData(color: AppColors.ink),
      titleTextStyle: AppFonts.display(
        weight: FontWeight.w700,
        fontSize: 18,
        color: AppColors.ink,
      ),
      centerTitle: false,
    ),
    textTheme: baseTextTheme.copyWith(
      displaySmall: AppFonts.display(
        weight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.ink,
      ),
      bodyMedium: AppFonts.body(fontSize: 14, color: AppColors.ink, height: 1.5),
      bodySmall: AppFonts.body(fontSize: 13, color: AppColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.35),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppFonts.body(weight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}