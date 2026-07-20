import 'package:flutter/material.dart';

import 'explore_majors_screen.dart';
import 'find_universities_screen.dart';
import 'my_shortlist_screen.dart';

/// Target Universities — hosts Explore Majors / Find Universities / My
/// Shortlist as TABS in one screen, mirroring the original site's single
/// `renderUniPath()` function rather than 3 separate pages
/// (day3-trimmed-source.md). All 3 tabs are real now.
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Target Universities'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Explore Majors'),
              Tab(text: 'Find Universities'),
              Tab(text: 'My Shortlist'),
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
                  FindUniversitiesScreen(
                    onGoToExploreMajors: () => tabController.animateTo(0),
                    onReviewShortlist: () => tabController.animateTo(2),
                  ),
                  MyShortlistScreen(
                    onGoToFindUniversities: () => tabController.animateTo(1),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}