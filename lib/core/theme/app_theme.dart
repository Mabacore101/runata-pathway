import 'package:flutter/material.dart';

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
}

/// Font family tokens from the CSS `--disp` / `--body` / `--mono` vars.
///
/// NOT WIRED TO REAL FONT FILES YET. The locked dependency list in
/// PLANNING.md is `flutter_riverpod hive hive_flutter go_router` — no font
/// package (e.g. google_fonts) and no bundled .ttf assets. Referencing these
/// family names below will silently fall back to the platform default font
/// until one of the following happens (flagging this rather than quietly
/// adding a new dependency myself):
///   1. Add `google_fonts` as a dependency, or
///   2. Download the .ttf files and register them under `flutter: fonts:`
///      in pubspec.yaml.
class AppFonts {
  AppFonts._();
  static const display = 'Bricolage Grotesque'; // --disp
  static const body = 'Inter'; // --body
  static const mono = 'IBM Plex Mono'; // --mono
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

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: AppFonts.body,
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w700,
        fontSize: 22,
        color: AppColors.ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 14,
        color: AppColors.ink,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13,
        color: AppColors.muted,
      ),
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
        disabledBackgroundColor: AppColors.muted.withOpacity(0.35),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
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
