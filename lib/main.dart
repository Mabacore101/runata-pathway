import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// NOTE: provided as an integration reference for Day 1's new pieces
/// (router + theme + auth). If Day 0 already created a main.dart in your
/// project, merge this in rather than overwriting it wholesale — in
/// particular, preserve any Hive.initFlutter()/adapter registration you
/// already added there, since that needs to run before runApp() too.
void main() {
  // Release builds must not depend on fetching fonts over the network —
  // require the bundled .ttf assets (see README for the exact files/
  // weights needed) to actually be present. If a weight is requested that
  // isn't bundled, this fails loudly in debug rather than silently
  // fetching over HTTP or silently falling back to the system font.
  GoogleFonts.config.allowRuntimeFetching = false;

  LicenseRegistry.addLicense(() async* {
    // Filenames are deliberately prefixed (OFL-<Family>.txt) rather than
    // each being a plain OFL.txt in a subfolder — keeps every font asset
    // flat in one folder, sidestepping needing to separately declare each
    // family's subfolder under pubspec.yaml's assets list.
    const licenseFiles = {
      'Bricolage Grotesque': 'assets/google_fonts/OFL-BricolageGrotesque.txt',
      'Inter': 'assets/google_fonts/OFL-Inter.txt',
      'IBM Plex Mono': 'assets/google_fonts/OFL-IBMPlexMono.txt',
    };
    for (final entry in licenseFiles.entries) {
      final license = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], license);
    }
  });

  runApp(const ProviderScope(child: RunataPathwayApp()));
}

class RunataPathwayApp extends ConsumerWidget {
  const RunataPathwayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Runata Pathway',
      debugShowCheckedModeBanner: false,
      theme: buildStudentTheme(),
      routerConfig: router,
    );
  }
}