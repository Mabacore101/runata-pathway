import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';

/// Day 1 stubs — reachable via real navigation, no real content yet.
/// Dashboard/Pathway/Nav Grid content ships on later days in the 7-day
/// plan once the 6 Pathway forms they summarize/link to actually exist.
class StudentDashboardStubScreen extends StatelessWidget {
  const StudentDashboardStubScreen({super.key});
  @override
  Widget build(BuildContext context) => const _StubScaffold(title: 'Dashboard');
}

class StudentPathwayStubScreen extends StatelessWidget {
  const StudentPathwayStubScreen({super.key});
  @override
  Widget build(BuildContext context) => _StubScaffold(
        title: 'Pathway',
        // TEMPORARY — Day 2 scaffolding only, not the real Pathway hub UI.
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
        ],
      );
}

class StudentNavGridStubScreen extends StatelessWidget {
  const StudentNavGridStubScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Navigation Grid');
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