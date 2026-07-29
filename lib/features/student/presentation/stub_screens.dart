import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';

/// Day 1 stubs — reachable via real navigation, no real content yet.
/// Pathway/Nav Grid content ships once the forms they summarize/link to
/// actually exist. Dashboard's own stub is gone — `AppRoutes.
/// studentDashboard` now routes to the real `DashboardScreen`.

class StudentPathwayStubScreen extends StatelessWidget {
  const StudentPathwayStubScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
        title: 'Pathway',
        // TEMPORARY — Day 2/3 scaffolding only, not the real Pathway hub UI.
        // Pathway is the flow spec's "direct list" door into the 6 forms,
        // so it's the one stub getting a preview link as each form ships
        // this week — without this there'd be no way to reach the new
        // screens from a real signed-in navigation path today. Remove
        // this whole `extraActions` block once the real Pathway hub list
        // is built — planning.md's Day 6 slot for Dashboard/Nav Grid is
        // the natural place to also replace this with the actual hub.
        extraActions: [
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentProfile),
            child: const Text('Preview: Student\'s Profile'),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentTests),
            child: const Text('Preview: My Tests'),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentGrades),
            child: const Text('Preview: My Grades'),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentTargetUniversities),
            child: const Text('Preview: Target Universities'),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentClubs),
            child: const Text('Preview: My Clubs'),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentMaterials),
            child: const Text('Preview: Application Materials'),
          ),
        ],
      );
}

class StudentNavGridStubScreen extends StatelessWidget {
  const StudentNavGridStubScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
        title: 'Navigation Grid',
        // TEMPORARY — same interim-preview pattern as
        // StudentPathwayStubScreen's own extraActions (see that class's
        // comment). Counsellor's Corner is Nav-Grid-scoped, not a
        // Pathway form, so it doesn't belong on that stub — but Nav Grid
        // itself isn't built yet either, so this is the only reachable
        // path to it today. Remove once the real Nav Grid tile grid
        // exists.
        extraActions: [
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentCounsellorCorner),
            child: const Text('Preview: Counsellor\'s Corner'),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.studentCountryPathways),
            child: const Text('Preview: Pathways'),
          ),
        ],
      );
}

class _StubScaffold extends StatelessWidget {
  const _StubScaffold({required this.title, this.extraActions = const []});
  final String title;
  final List<Widget> extraActions;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$title — coming in a later day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (extraActions.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...extraActions,
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.studentHome),
                child: const Text('← Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}