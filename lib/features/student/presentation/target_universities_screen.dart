import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'explore_majors_screen.dart';

/// Target Universities — hosts Explore Majors / Find Universities / My
/// Shortlist as TABS in one screen, mirroring the original site's single
/// `renderUniPath()` function rather than 3 separate pages
/// (day3-trimmed-source.md). Built incrementally: Explore Majors is real;
/// Find Universities is next up (currently a placeholder tab below); My
/// Shortlist comes after that.
///
/// Tab index is ephemeral UI state only (`DefaultTabController`) — not
/// persisted, and switching tabs doesn't touch any Riverpod state. Each
/// tab's actual DATA (majors list, shortlist, etc.) lives in its own
/// plain `NotifierProvider` (not autoDispose), so it survives regardless
/// of which tab happens to be visible.
class TargetUniversitiesScreen extends StatelessWidget {
  const TargetUniversitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Explore Majors, Find Universities — My Shortlist joins later
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Target Universities'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Explore Majors'),
              Tab(text: 'Find Universities'),
            ],
          ),
        ),
        body: SafeArea(
          child: Builder(
            // Needs a context BELOW DefaultTabController to resolve
            // DefaultTabController.of(context) — the outer build()'s own
            // context is still above it in the tree at this point.
            builder: (tabContext) {
              final tabController = DefaultTabController.of(tabContext);
              return TabBarView(
                children: [
                  ExploreMajorsScreen(
                    onContinue: () => tabController.animateTo(1),
                  ),
                  const _FindUniversitiesPlaceholder(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// TEMPORARY — replaced by the real Find Universities tab content next.
class _FindUniversitiesPlaceholder extends StatelessWidget {
  const _FindUniversitiesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Find Universities — coming next',
        style: AppFonts.body(color: AppColors.muted),
      ),
    );
  }
}
