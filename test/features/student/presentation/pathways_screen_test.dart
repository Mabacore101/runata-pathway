import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:runata_pathway/core/routing/app_router.dart';
import 'package:runata_pathway/features/student/domain/pathway_catalog.dart';
import 'package:runata_pathway/features/student/presentation/pathways_screen.dart';

class _StubDestination extends StatelessWidget {
  const _StubDestination(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(label)));
}

void main() {
  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: AppRoutes.studentCountryPathways,
      routes: [
        GoRoute(
          path: AppRoutes.studentCountryPathways,
          builder: (context, state) => const PathwaysScreen(),
        ),
        GoRoute(
          path: AppRoutes.studentHome,
          builder: (context, state) => const _StubDestination('Home stub'),
        ),
      ],
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp.router(routerConfig: buildTestRouter()));
    await tester.pumpAndSettle();
  }

  group('list view', () {
    testWidgets('shows the header, description, and both country cards '
        'with truncated intros', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Runata\'s Signature Country Pathways'), findsOneWidget);
      expect(find.text('Germany Pathway'), findsOneWidget);
      expect(find.text('China Pathway'), findsOneWidget);

      // The card's intro is the truncated version, not the full text.
      expect(find.text(truncatedIntro(pathwayDocs[0].intro)), findsOneWidget);
      expect(find.text(pathwayDocs[0].intro), findsNothing);
    });

    testWidgets('"← Back to home" navigates to the real home route',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('pathways_back_to_home')));
      await tester.pumpAndSettle();

      expect(find.text('Home stub'), findsOneWidget);
    });
  });

  group('opening a pathway', () {
    testWidgets('tapping a card shows the FULL intro, not the truncated '
        'version, and hides the row list', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('pathway_tile_germany')));
      await tester.pumpAndSettle();

      expect(find.text(pathwayDocs[0].intro), findsOneWidget);
      expect(find.text('China Pathway'), findsNothing); // list is gone
    });

    testWidgets('shows the "Open the document" button since both built-in '
        'pathways have a url', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('pathway_tile_china')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pathway_open_document')), findsOneWidget);
      expect(find.text('No document link yet.'), findsNothing);
    });

    testWidgets('"← Back to pathways" returns to the LIST, not Home',
        (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('pathway_tile_germany')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pathway_back_to_list')));
      await tester.pumpAndSettle();

      // Back on the list — both cards visible again, not the Home stub.
      expect(find.text('Germany Pathway'), findsOneWidget);
      expect(find.text('China Pathway'), findsOneWidget);
      expect(find.text('Home stub'), findsNothing);
    });

    testWidgets('opening Germany then China shows each one\'s own intro, '
        'not a leftover from the other', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('pathway_tile_germany')));
      await tester.pumpAndSettle();
      expect(find.text(pathwayDocs[0].intro), findsOneWidget);

      await tester.tap(find.byKey(const Key('pathway_back_to_list')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pathway_tile_china')));
      await tester.pumpAndSettle();
      expect(find.text(pathwayDocs[1].intro), findsOneWidget);
      expect(find.text(pathwayDocs[0].intro), findsNothing);
    });
  });
}
