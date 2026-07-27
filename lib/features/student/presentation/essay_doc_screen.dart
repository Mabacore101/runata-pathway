import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/fit_chip.dart';
import '../application/application_documents_controller.dart';
import '../application/materials_context.dart';
import '../domain/application_materials_catalog.dart';
import '../domain/document_rubric.dart';

/// Application Materials' shared essay/upload template (Day 6 items 1–3)
/// — one widget for all 6 text/upload-kind docs (5 essays +
/// Recommendation Letters), branching internally on [MaterialDoc.kind],
/// mirroring the JS's single `renderMatDoc(k)` function handling all of
/// them via a `kind` branch rather than 6 near-identical screens.
///
/// **Does not own AY-tab state.** Tracing `renderMatDoc()` shows it reads
/// a globally-selected `myAY` but never renders its own AY-tab switcher —
/// only the Hub screen (`renderMaterials()`) does that. So [ay] is passed
/// in from whichever AY tab was selected on the Hub when this screen was
/// opened (wiring for that lands in the Hub-routing step), not managed
/// here.
///
/// **The feedback checklist is stale-until-refreshed, matching the JS,
/// not live on every keystroke.** `data-content` mutates `D.content[ay]`
/// on every keystroke without ever calling `renderStudent()` — so the
/// checklist only reflects the current draft once something else forces
/// a recompute (`data-check`, `data-mdone`, or reopening the screen).
/// Typing here only updates [ApplicationDocumentsController]'s local
/// state via `onChanged`; the score is computed once on open and then
/// only recomputed by "Check feedback" and "Mark as ready" — nothing
/// else refreshes what's shown.
class EssayDocScreen extends ConsumerStatefulWidget {
  const EssayDocScreen({
    super.key,
    required this.docKey,
    required this.ay,
    required this.onBack,
  });

  final String docKey;
  final String ay;
  final VoidCallback onBack;

  @override
  ConsumerState<EssayDocScreen> createState() => _EssayDocScreenState();
}

class _EssayDocScreenState extends ConsumerState<EssayDocScreen> {
  late final TextEditingController _contentController;
  late final TextEditingController _linkController;
  DocScore? _score;

  MaterialDoc get _doc => materialDocs.firstWhere((d) => d.key == widget.docKey);
  bool get _isUpload => _doc.kind == MaterialDocKind.upload;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(applicationDocumentsControllerProvider.notifier);
    final current = notifier.docFor(widget.docKey);
    _contentController = TextEditingController(text: current.contentFor(widget.ay));
    _linkController = TextEditingController(text: current.note ?? '');
    // Computed directly, not via _recomputeScore()'s setState wrapper —
    // no build has happened yet for setState to "trigger a rebuild" for;
    // the value is already correct by the time the first build() runs.
    if (!_isUpload) {
      _score = _computeScore();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  DocScore _computeScore() {
    final ctx = ref.read(materialsContextProvider);
    return scoreDoc(widget.docKey, _contentController.text, ctx.forScoring);
  }

  /// Called from "Check feedback" and "Mark as ready" — the only two
  /// places (besides initial open) that recompute the checklist, matching
  /// the JS's stale-until-refreshed behavior (see this class's own doc
  /// comment).
  void _recomputeScore() {
    setState(() {
      _score = _computeScore();
    });
  }

  void _onContentChanged(String text) {
    ref
        .read(applicationDocumentsControllerProvider.notifier)
        .updateContent(widget.docKey, widget.ay, text);
  }

  void _onLinkChanged(String text) {
    ref.read(applicationDocumentsControllerProvider.notifier).updateNote(widget.docKey, text);
  }

  Future<void> _onSave() async {
    await ref.read(applicationDocumentsControllerProvider.notifier).save(widget.docKey);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_doc.name} saved.')),
    );
  }

  /// Mirrors the JS's `data-mdone` handler exactly — fully unconditional,
  /// no non-empty check, no criteria check. Also mirrors its side effect
  /// of calling `renderStudent()` afterward (which re-runs `scoreDoc` as
  /// part of a full re-render) by recomputing the score display here too
  /// — that recompute is a byproduct of "the whole screen redraws," not
  /// something [markReady] itself depends on or triggers on purpose.
  Future<void> _onMarkReady() async {
    await ref
        .read(applicationDocumentsControllerProvider.notifier)
        .markReady(widget.docKey, widget.ay);
    if (!mounted) return;
    if (!_isUpload) _recomputeScore();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as ready ✓')),
    );
  }

  Future<void> _onToggleSubmitted() async {
    await ref.read(applicationDocumentsControllerProvider.notifier).toggleSubmitted(widget.docKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_doc.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (docInfo[widget.docKey] != null) _DocInfoBanner(html: docInfo[widget.docKey]!),
            ...(_isUpload ? _buildUploadBody() : _buildTextBody()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('essay_doc_save'),
                    onPressed: _onSave,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('essay_doc_back'),
                    onPressed: widget.onBack,
                    child: const Text('← All documents'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTextBody() {
    final ctx = ref.watch(materialsContextProvider);
    final score = _score ?? const DocScore(results: [], met: 0, total: 0);
    final contentIsEmpty = _contentController.text.trim().isEmpty;
    final head = _headFor(contentIsEmpty, score);

    final tailoredToStyle = AppFonts.body(fontSize: 13, color: AppColors.muted);

    return [
      RichText(
        text: TextSpan(
          children: _parseInlineBoldSpans(
            'Feedback below is tailored to ${ctx.majorDisplayLabel}, for '
            'applications to ${ctx.countryDisplayLabel}.',
            tailoredToStyle,
          ),
        ),
      ),
      _SectionLabel('What a strong ${_doc.name} includes — read this first'),
      _FeedbackPanel(
        head: head,
        scoreText: contentIsEmpty
            ? 'checklist — your draft is scored against these'
            : '${score.met}/${score.total} criteria met · '
                '${wordCount(_contentController.text)} words',
        results: score.results,
      ),
      _SectionLabel('Your draft'),
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          'Google Docs / Drive / PDF link (optional)',
          style: AppFonts.mono(fontSize: 9, color: AppColors.muted),
        ),
      ),
      TextField(
        key: const Key('essay_doc_link'),
        controller: _linkController,
        onChanged: _onLinkChanged,
        decoration: const InputDecoration(hintText: 'Paste a shareable link…'),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Instant Plan A feedback reads the pasted text below; a link is '
          'saved for your coordinator (and for AI review when enabled).',
          style: AppFonts.body(fontSize: 11.5, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ),
      TextField(
        key: const Key('essay_doc_content'),
        controller: _contentController,
        onChanged: _onContentChanged,
        maxLines: 12,
        minLines: 8,
        decoration: InputDecoration(
          hintText: '…or paste your ${_doc.name} draft here for instant feedback',
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('essay_doc_check_feedback'),
              onPressed: _recomputeScore,
              child: const Text('Check feedback'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              key: const Key('essay_doc_mark_ready'),
              onPressed: _onMarkReady,
              child: const Text('Mark as ready'),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildUploadBody() {
    final docs = ref.watch(applicationDocumentsControllerProvider);
    final submitted = docs[widget.docKey]?.submitted ?? false;

    return [
      Text(
        'Add a link (Google Drive / PDF) or filename, then mark uploaded. '
        'Your advisor verifies it.',
        style: AppFonts.body(fontSize: 13, color: AppColors.muted),
      ),
      const SizedBox(height: 10),
      TextField(
        key: const Key('essay_doc_link'),
        controller: _linkController,
        onChanged: _onLinkChanged,
        decoration: const InputDecoration(hintText: 'Link or filename…'),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: submitted
            ? OutlinedButton(
                key: const Key('essay_doc_toggle_uploaded'),
                onPressed: _onToggleSubmitted,
                child: const Text('Uploaded ✓ · undo'),
              )
            : ElevatedButton(
                key: const Key('essay_doc_toggle_uploaded'),
                onPressed: _onToggleSubmitted,
                child: const Text('Mark uploaded'),
              ),
      ),
    ];
  }

  _HeadChip _headFor(bool contentIsEmpty, DocScore score) {
    if (contentIsEmpty) {
      return const _HeadChip(label: 'Start writing', tone: FitTone.none);
    }
    final ratio = score.total > 0 ? score.met / score.total : 0.0;
    if (ratio >= 0.8) return const _HeadChip(label: 'Looks strong', tone: FitTone.met);
    if (ratio >= 0.5) return const _HeadChip(label: 'Getting there', tone: FitTone.track);
    return const _HeadChip(label: 'Needs work', tone: FitTone.work);
  }
}

class _HeadChip {
  const _HeadChip({required this.label, required this.tone});
  final String label;
  final FitTone tone;
}

/// `.fbpanel` equivalent — the head chip + score text + criteria list.
class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({required this.head, required this.scoreText, required this.results});

  final _HeadChip head;
  final String scoreText;
  final List<ScoredCriterion> results;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FitChip(label: head.label, tone: head.tone),
              const SizedBox(width: 10),
              Expanded(
                child: Text(scoreText, style: AppFonts.body(fontSize: 12, color: AppColors.muted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < results.length; i++)
            _FeedbackItem(criterion: results[i], isFirst: i == 0),
        ],
      ),
    );
  }
}

/// `.fbitem` equivalent — one criteria row, ✓/! badge + title + tip
/// (tip only shown when not met, matching the JS's `x.ok?'':tip`).
class _FeedbackItem extends StatelessWidget {
  const _FeedbackItem({required this.criterion, required this.isFirst});
  final ScoredCriterion criterion;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isFirst ? null : const Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: criterion.met ? AppColors.greenSoft : AppColors.amberSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                criterion.met ? '✓' : '!',
                style: AppFonts.body(
                  fontSize: 11,
                  weight: FontWeight.w700,
                  color: criterion.met ? AppColors.green : AppColors.amber,
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criterion.title,
                  style: AppFonts.body(fontSize: 12.5, weight: FontWeight.w700, color: AppColors.ink),
                ),
                if (!criterion.met)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      criterion.tip,
                      style: AppFonts.body(fontSize: 11, color: AppColors.inkSoft),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `.poollab` equivalent — a small uppercase label with a trailing rule.
/// The label wraps rather than overflows for longer doc names (e.g.
/// "Statement of Purpose / Motivation Letter") — a plain `Text` inside a
/// `Row` has no width limit to wrap against on its own, so it needs the
/// `Flexible` wrapper to know it's allowed to break onto a second line
/// instead of overflowing past the row's edge.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AppFonts.mono(fontSize: 9, color: AppColors.muted, letterSpacing: 0.6),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: Container(height: 1, color: AppColors.line)),
        ],
      ),
    );
  }
}

/// `.docinfo` equivalent — renders `DOC_INFO`'s markup, which is only
/// ever plain text plus `<b>...</b>` spans and a stray `&amp;` (confirmed
/// by inspecting every entry in `document_rubric.dart`). Deliberately not
/// a general HTML renderer — a full HTML package would be overkill for 6
/// known, fixed strings. `.docinfo b{color:var(--teal-deep)}` is the only
/// place bold text gets its own color — hence the explicit override here
/// (see [_parseInlineBoldSpans]'s `boldColor` param), which the "tailored
/// to X" line below does NOT use, since no such CSS rule exists for it.
class _DocInfoBanner extends StatelessWidget {
  const _DocInfoBanner({required this.html});
  final String html;

  @override
  Widget build(BuildContext context) {
    final base = AppFonts.body(fontSize: 12.5, color: AppColors.inkSoft, height: 1.55);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(12)),
      child: RichText(
        text: TextSpan(children: _parseInlineBoldSpans(html, base, boldColor: AppColors.tealDeep)),
      ),
    );
  }
}

/// Shared by [_DocInfoBanner] (DOC_INFO's markup) and the "tailored to X"
/// line (`MaterialsContext.majorDisplayLabel`/`countryDisplayLabel`) —
/// both are plain text with occasional `<b>...</b>` spans, nothing more
/// complex. [boldColor] defaults to the base style's own color (bold
/// weight only, no color change) — only DOC_INFO's bold text gets an
/// explicit color override, per its own CSS rule.
List<InlineSpan> _parseInlineBoldSpans(String html, TextStyle base, {Color? boldColor}) {
  final boldStyle = base.copyWith(fontWeight: FontWeight.w700, color: boldColor ?? base.color);
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'<b>(.*?)</b>', dotAll: true);
  var last = 0;
  for (final match in pattern.allMatches(html)) {
    if (match.start > last) {
      spans.add(TextSpan(text: _decodeEntities(html.substring(last, match.start)), style: base));
    }
    spans.add(TextSpan(text: _decodeEntities(match.group(1)!), style: boldStyle));
    last = match.end;
  }
  if (last < html.length) {
    spans.add(TextSpan(text: _decodeEntities(html.substring(last)), style: base));
  }
  return spans;
}

String _decodeEntities(String s) =>
    s.replaceAll('&amp;', '&').replaceAll('&#39;', "'").replaceAll('&quot;', '"');