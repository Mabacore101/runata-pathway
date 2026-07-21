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
          actions: [
            // Every action on all 3 tabs already persists immediately —
            // there's no deferred/unsaved state anywhere in this feature
            // for a "Save" to actually write. This button exists purely
            // as a reassurance affordance: tapping it doesn't change any
            // data, it just confirms out loud that whatever's on screen
            // is already safely stored, since "only back buttons, no
            // Save" read as untrustworthy even though nothing was
            // actually at risk of being lost.
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All changes saved ✓'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 4),
          ],
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