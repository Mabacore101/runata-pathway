import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/pathway_catalog.dart';

/// Pathways — Runata's Signature Country Pathways. Mirrors the JS's
/// `renderPathways()`: a list of country guide cards, each opening a
/// detail view with the full introduction and an external link to the
/// full document.
///
/// **Plain `StatefulWidget`, not `ConsumerStatefulWidget`** — unlike
/// every other Day 6 screen, there's no Riverpod state at all here.
/// `pathwayDocs` is static, read-only reference content (see
/// `pathway_catalog.dart`'s own doc comment for why); the only state is
/// which pathway is currently open, purely ephemeral UI state, never
/// persisted.
///
/// **A real, top-level go_router route** (reached from Nav Grid, once
/// that's built), same as `CounsellorCornerScreen` — not an internally-
/// swapped sub-screen. The LIST view's back button goes to Home
/// (`context.go`); the DETAIL view's back button returns to the LIST
/// (internal state, no route change) — mirrors the JS's `data-pwback`
/// exactly, which always returns to the list (`pathwayOpen=null`), never
/// all the way to Home in one step.
class PathwaysScreen extends StatefulWidget {
  const PathwaysScreen({super.key});

  @override
  State<PathwaysScreen> createState() => _PathwaysScreenState();
}

class _PathwaysScreenState extends State<PathwaysScreen> {
  String? _openId;

  void _open(String id) => setState(() => _openId = id);
  void _closeToList() => setState(() => _openId = null);

  @override
  Widget build(BuildContext context) {
    if (_openId != null) {
      final doc = pathwayDocs.firstWhere((d) => d.id == _openId);
      return _PathwayDetailScreen(doc: doc, onBack: _closeToList);
    }
    return _PathwayListScreen(onOpen: _open);
  }
}

class _PathwayListScreen extends StatelessWidget {
  const _PathwayListScreen({required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pathways')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text('🌍', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Runata\'s Signature Country Pathways',
                    style: AppFonts.display(fontSize: 19, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Country guides prepared by the school. Tap one to read the '
              'introduction and open the full document.',
              style: AppFonts.body(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (pathwayDocs.isEmpty)
              Text(
                'No pathways published yet. Please check back soon.',
                style: AppFonts.body(fontSize: 13, color: AppColors.muted),
              )
            else
              for (final doc in pathwayDocs) ...[
                _PathwayCard(doc: doc, onTap: () => onOpen(doc.id)),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('pathways_back_to_home'),
                onPressed: () => context.go(AppRoutes.studentHome),
                child: const Text('← Back to home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathwayCard extends StatelessWidget {
  const _PathwayCard({required this.doc, required this.onTap});
  final PathwayDoc doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('pathway_tile_${doc.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _FlagIcon(title: doc.title, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.title,
                      style: AppFonts.body(
                        weight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      truncatedIntro(doc.intro),
                      style: AppFonts.body(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathwayDetailScreen extends StatelessWidget {
  const _PathwayDetailScreen({required this.doc, required this.onBack});
  final PathwayDoc doc;
  final VoidCallback onBack;

  Future<void> _openDocument() async {
    final url = doc.url;
    if (url == null || url.isEmpty) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = doc.url != null && doc.url!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _FlagIcon(title: doc.title, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    doc.title,
                    style: AppFonts.display(fontSize: 19, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              doc.intro.isEmpty ? 'No introduction provided yet.' : doc.intro,
              style: AppFonts.body(fontSize: 13.5, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 16),
            if (hasUrl) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('pathway_open_document'),
                  onPressed: _openDocument,
                  child: const Text('📄 Open the document'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Opens in a new tab. If it asks you to sign in, the document '
                'owner needs to set sharing to "Anyone with the link can '
                'view."',
                style: AppFonts.body(fontSize: 11.5, color: AppColors.muted),
              ),
            ] else
              Text(
                'No document link yet.',
                style: AppFonts.body(fontSize: 13, color: AppColors.muted),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                key: const Key('pathway_back_to_list'),
                onPressed: onBack,
                child: const Text('← Back to pathways'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `flagFor(title, cls)` equivalent — real flag images
/// (`assets/images/germany.png`/`china.png`), falling back to the 🌏
/// emoji both when the country isn't recognized AND when the asset
/// itself fails to load (`errorBuilder`), mirroring the JS's `onerror`
/// handler on its `<img>` tag.
class _FlagIcon extends StatelessWidget {
  const _FlagIcon({required this.title, required this.size});
  final String title;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = flagAssetFor(title);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: AppColors.tealSoft,
        alignment: Alignment.center,
        child: asset == null
            ? Text('🌏', style: TextStyle(fontSize: size * 0.55))
            : Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Text('🌏', style: TextStyle(fontSize: size * 0.55)),
              ),
      ),
    );
  }
}
