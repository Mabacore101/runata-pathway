import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// NOTE: provided as an integration reference for Day 1's new pieces
/// (router + theme + auth). If Day 0 already created a main.dart in your
/// project, merge this in rather than overwriting it wholesale — in
/// particular, preserve any Hive.initFlutter()/adapter registration you
/// already added there, since that needs to run before runApp() too.
void main() {
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
