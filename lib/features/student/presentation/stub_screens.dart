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
  Widget build(BuildContext context) => const _StubScaffold(title: 'Pathway');
}

class StudentNavGridStubScreen extends StatelessWidget {
  const StudentNavGridStubScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const _StubScaffold(title: 'Navigation Grid');
}

class _StubScaffold extends StatelessWidget {
  const _StubScaffold({required this.title});

  final String title;

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
