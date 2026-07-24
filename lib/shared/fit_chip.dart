import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Matches the JS's `.fitb`/`.fit-met`/`.fit-track`/`.fit-work`/
/// `.fit-none` CSS classes exactly — the same `scoreDoc` ratio-to-label
/// mapping computed in two separate places in the original JS
/// (`renderMaterials()`'s per-row chip and `renderMatDoc()`'s feedback
/// head), so this widget is shared by [ApplicationMaterialsScreen]'s Hub
/// row status and [EssayDocScreen]'s feedback panel head, rather than
/// each screen keeping its own copy of the same 4-color switch.
enum FitTone { met, track, work, none }

class FitChip extends StatelessWidget {
  const FitChip({super.key, required this.label, required this.tone});

  final String label;
  final FitTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      FitTone.met => (AppColors.greenSoft, AppColors.green),
      FitTone.track => (AppColors.tealSoft, AppColors.tealDeep),
      FitTone.work => (AppColors.amberSoft, AppColors.amber),
      FitTone.none => (AppColors.surface2, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        border: tone == FitTone.none ? Border.all(color: AppColors.line) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppFonts.mono(fontSize: 9, weight: FontWeight.w600, color: fg, letterSpacing: 0.4),
      ),
    );
  }
}
