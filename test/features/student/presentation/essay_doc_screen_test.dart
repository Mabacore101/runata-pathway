import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/data/student_application_documents_repository.dart';
import 'package:runata_pathway/features/student/data/student_clubs_repository.dart';
import 'package:runata_pathway/features/student/data/student_university_targets_repository.dart';
import 'package:runata_pathway/features/student/domain/application_document_state.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';
import 'package:runata_pathway/features/student/domain/university_target.dart';
import 'package:runata_pathway/features/student/presentation/essay_doc_screen.dart';

class _FakeApplicationDocumentsRepository extends StudentApplicationDocumentsRepository {
  _FakeApplicationDocumentsRepository(super.box, [Map<String, ApplicationDocumentState>? initial])
      : _docs = {...?initial};

  final Map<String, ApplicationDocumentState> _docs;
  final List<ApplicationDocumentState> saved = [];

  @override
  ApplicationDocumentState load(String docKey) =>
      _docs[docKey] ?? ApplicationDocumentState(docKey: docKey);

  @override
  Future<void> save(ApplicationDocumentState doc) async {
    _docs[doc.docKey] = doc;
    saved.add(doc);
  }
}

class _FakeClubsRepository extends StudentClubsRepository {
  _FakeClubsRepository(super.box, [StudentClubSelection? initial]) : _selection = initial;

  StudentClubSelection? _selection;

  @override
  StudentClubSelection? loadSelection() => _selection;

  @override
  Future<void> saveSelection(StudentClubSelection selection) async {
    _selection = selection;
  }
}

class _FakeUniversityTargetsRepository extends StudentUniversityTargetsRepository {
  _FakeUniversityTargetsRepository(super.box, [List<UniversityTarget>? initial])
      : _targets = [...?initial];

  final List<UniversityTarget> _targets;

  @override
  List<UniversityTarget> loadAll() => _targets;

  @override
  Future<void> upsert(UniversityTarget target) async {
    _targets.removeWhere((t) => t.id == target.id);
    _targets.add(target);
  }

  @override
  Future<void> delete(String id) async {
    _targets.removeWhere((t) => t.id == id);
  }
}

// Same sample essay verified word-for-word in document_rubric_test.dart —
// 458 words, meets all 6 of "personal"'s criteria.
const _fullMarksPersonalEssay =
    'Ever since I built my first robot out of spare Lego pieces at age nine, I have been fascinated by how machines can be taught to solve problems on their own. That early curiosity turned into a genuine passion for computer science, one that has only grown stronger through every project I have taken on since, and it now shapes almost every choice I make about how I spend my free time outside of school.\n'
    '\n'
    'In my final two years of school, I led a team of four students in a regional robotics competition, where we designed and programmed an autonomous sorting arm from scratch. When I hit a wall debugging our sensor calibration two days before the deadline, I spent an entire weekend rewriting our control loop, testing each change against the same three obstacle courses over and over until the timing finally felt right. The arm worked exactly as intended on the day of the competition, and we went on to win second place out of eighteen teams from across the region. More importantly than the result itself, I discovered how much I genuinely enjoy the slow, sometimes frustrating process of taking a rough sketch on paper and turning it into something that actually functions reliably in the real world.\n'
    '\n'
    'Outside of competitions, I also founded a small coding club at school to teach younger students the basics of Python, an experience that taught me as much about patient communication as it did about programming itself. Explaining a loop or a conditional statement to a twelve-year-old who has never touched a keyboard before forces you to understand the idea far more deeply than any exam ever could, and watching students who started the term afraid of the terminal end it by building their own simple games was one of the most rewarding things I have done. Running the club for a full academic year also meant learning how to plan sessions, manage a modest budget for equipment, and keep a group of very different personalities engaged week after week.\n'
    '\n'
    'I have come to realise that the course I want to study is not just about writing code, but about understanding the systems that code controls and the people those systems ultimately serve. That is exactly what a Computer Science degree at university would let me explore in far greater depth, moving from the small, self-contained projects I have built so far toward genuinely complex, collaborative systems. Studying this field would let me combine the analytical rigour I developed through the robotics competition with the creative problem solving I have always been drawn to since childhood, and I am ready to bring that same persistence and curiosity to a university programme that challenges me every single day.';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(DocumentStatusAdapter());
    registerAdapterIfNeeded(ApplicationDocumentStateAdapter());
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
    registerAdapterIfNeeded(UniversityTargetAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeApplicationDocumentsRepository docsRepository;
  bool backTapped = false;

  Future<void> pumpScreen(
    WidgetTester tester,
    String boxPrefix, {
    String docKey = 'personal',
    String ay = 'g11',
    Map<String, ApplicationDocumentState>? initialDocs,
    StudentClubSelection? initialClubSelection,
    List<UniversityTarget>? initialTargets,
  }) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    backTapped = false;

    final docsBox = await tester.runAsync(
      () => Hive.openBox<ApplicationDocumentState>('$boxPrefix-docs'),
    );
    final clubsBox = await tester.runAsync(
      () => Hive.openBox<StudentClubSelection>('$boxPrefix-clubs'),
    );
    final targetsBox = await tester.runAsync(
      () => Hive.openBox<UniversityTarget>('$boxPrefix-targets'),
    );

    docsRepository = _FakeApplicationDocumentsRepository(docsBox!, initialDocs);

    final container = ProviderContainer(
      overrides: [
        studentApplicationDocumentsRepositoryProvider.overrideWithValue(docsRepository),
        studentClubsRepositoryProvider.overrideWithValue(
          _FakeClubsRepository(clubsBox!, initialClubSelection),
        ),
        studentUniversityTargetsRepositoryProvider.overrideWithValue(
          _FakeUniversityTargetsRepository(targetsBox!, initialTargets),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: EssayDocScreen(docKey: docKey, ay: ay, onBack: () => backTapped = true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('static content — text-kind (personal)', () {
    testWidgets('shows the doc name in the AppBar and the docinfo banner',
        (tester) async {
      await pumpScreen(tester, 'essay_static');

      expect(find.text('Personal Statement (UCAS)'), findsOneWidget);
      expect(
        find.textContaining('main essay UK universities read', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows Save and back buttons', (tester) async {
      await pumpScreen(tester, 'essay_static_nav');

      expect(find.byKey(const Key('essay_doc_save')), findsOneWidget);
      expect(find.byKey(const Key('essay_doc_back')), findsOneWidget);
      expect(find.text('← All documents'), findsOneWidget);
    });
  });

  group('initial score reflects already-saved content on open', () {
    testWidgets('a fresh, never-touched doc shows "Start writing"',
        (tester) async {
      await pumpScreen(tester, 'essay_initial_blank');

      expect(find.text('Start writing'), findsOneWidget);
      expect(find.text('checklist — your draft is scored against these'), findsOneWidget);
    });

    testWidgets('a doc pre-seeded with a full-marks essay shows "Looks '
        'strong" immediately, with no need to press Check feedback first',
        (tester) async {
      await pumpScreen(
        tester,
        'essay_initial_full_marks',
        initialDocs: {
          'personal': ApplicationDocumentState(
            docKey: 'personal',
            content: {'g11': _fullMarksPersonalEssay},
          ),
        },
      );

      expect(find.text('Looks strong'), findsOneWidget);
      expect(find.textContaining('6/6 criteria met'), findsOneWidget);
    });
  });

  group('the feedback panel is stale-until-refreshed, not live', () {
    testWidgets('typing a full-marks essay does NOT update the chip until '
        'Check feedback is pressed', (tester) async {
      await pumpScreen(tester, 'essay_stale_until_check');

      expect(find.text('Start writing'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('essay_doc_content')),
        _fullMarksPersonalEssay,
      );
      await tester.pump();

      // Still stale — the chip has not recomputed on keystroke.
      expect(find.text('Start writing'), findsOneWidget);
      expect(find.text('Looks strong'), findsNothing);

      await tester.tap(find.byKey(const Key('essay_doc_check_feedback')));
      await tester.pumpAndSettle();

      // Now it reflects the typed content.
      expect(find.text('Looks strong'), findsOneWidget);
      expect(find.textContaining('6/6 criteria met'), findsOneWidget);
    });
  });

  group('Save', () {
    testWidgets('persists the typed content and link to the repository',
        (tester) async {
      await pumpScreen(tester, 'essay_save');

      await tester.enterText(find.byKey(const Key('essay_doc_content')), 'A short draft.');
      await tester.enterText(
        find.byKey(const Key('essay_doc_link')),
        'https://docs.google.com/example',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('essay_doc_save')));
      await tester.pumpAndSettle();

      expect(docsRepository.saved, isNotEmpty);
      expect(docsRepository.load('personal').content['g11'], 'A short draft.');
      expect(docsRepository.load('personal').note, 'https://docs.google.com/example');
      expect(find.text('Personal Statement (UCAS) saved.'), findsOneWidget);
    });
  });

  group('Mark as ready — fully unconditional (Day 6 item 2)', () {
    testWidgets('works immediately on a completely empty doc — no crash, '
        'shows the confirmation toast, and flips status', (tester) async {
      await pumpScreen(tester, 'essay_mark_ready_empty');

      await tester.tap(find.byKey(const Key('essay_doc_mark_ready')));
      await tester.pumpAndSettle();

      expect(find.text('Marked as ready ✓'), findsOneWidget);
      expect(docsRepository.load('personal').status['g11'], DocumentStatus.finalStatus);
      // Content remains empty — Mark as Ready never required it.
      expect(docsRepository.load('personal').content['g11'], isNull);
    });

    testWidgets('also refreshes the feedback display, matching the JS '
        'calling renderStudent() afterward', (tester) async {
      await pumpScreen(tester, 'essay_mark_ready_refresh');

      await tester.enterText(
        find.byKey(const Key('essay_doc_content')),
        _fullMarksPersonalEssay,
      );
      await tester.pump();
      expect(find.text('Start writing'), findsOneWidget); // still stale

      await tester.tap(find.byKey(const Key('essay_doc_mark_ready')));
      await tester.pumpAndSettle();

      expect(find.text('Looks strong'), findsOneWidget); // refreshed
    });
  });

  group('doc-kind branching — Recommendation Letters (upload-kind)', () {
    testWidgets('has no textarea, no checklist, and no Check feedback / '
        'Mark as ready buttons', (tester) async {
      await pumpScreen(tester, 'essay_upload_no_text_ui', docKey: 'recletter');

      expect(find.byKey(const Key('essay_doc_content')), findsNothing);
      expect(find.byKey(const Key('essay_doc_check_feedback')), findsNothing);
      expect(find.byKey(const Key('essay_doc_mark_ready')), findsNothing);
      expect(find.byKey(const Key('essay_doc_toggle_uploaded')), findsOneWidget);
    });

    testWidgets('shows "Mark uploaded" initially, flips to "Uploaded ✓ · '
        'undo" after tapping, and persists submitted immediately', (tester) async {
      await pumpScreen(tester, 'essay_upload_toggle', docKey: 'recletter');

      expect(find.text('Mark uploaded'), findsOneWidget);

      await tester.tap(find.byKey(const Key('essay_doc_toggle_uploaded')));
      await tester.pumpAndSettle();

      expect(find.text('Uploaded ✓ · undo'), findsOneWidget);
      expect(docsRepository.load('recletter').submitted, isTrue);

      await tester.tap(find.byKey(const Key('essay_doc_toggle_uploaded')));
      await tester.pumpAndSettle();

      expect(find.text('Mark uploaded'), findsOneWidget);
      expect(docsRepository.load('recletter').submitted, isFalse);
    });

    testWidgets('typing a link/filename and Save persists the note',
        (tester) async {
      await pumpScreen(tester, 'essay_upload_save', docKey: 'recletter');

      await tester.enterText(find.byKey(const Key('essay_doc_link')), 'letter.pdf');
      await tester.pump();
      await tester.tap(find.byKey(const Key('essay_doc_save')));
      await tester.pumpAndSettle();

      expect(docsRepository.load('recletter').note, 'letter.pdf');
    });
  });

  group('back navigation', () {
    testWidgets('"← All documents" calls onBack', (tester) async {
      await pumpScreen(tester, 'essay_back');

      await tester.tap(find.byKey(const Key('essay_doc_back')));
      await tester.pumpAndSettle();

      expect(backTapped, isTrue);
    });
  });

  group('matCtx-driven "tailored to" line', () {
    testWidgets('falls back to placeholder text when no anchor major and '
        'no target exist', (tester) async {
      await pumpScreen(tester, 'essay_ctx_fallback');

      expect(
        find.textContaining(
          'tailored to your major, for applications to your target country',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows the real anchor major once clubs have been '
        'submitted', (tester) async {
      await pumpScreen(
        tester,
        'essay_ctx_anchor',
        initialClubSelection: StudentClubSelection(
          anchorMajor: 'Computer Science',
          rankedOthers: const [],
          submittedAt: DateTime(2026, 1, 1),
        ),
      );

      expect(
        find.textContaining('your anchor major — Computer Science', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('shows the real target country once a university target '
        'exists', (tester) async {
      await pumpScreen(
        tester,
        'essay_ctx_target',
        initialTargets: [
          UniversityTarget(
            id: 'target_1',
            major: 'Computer Science',
            country: 'Germany',
            university: 'TU Munich',
          ),
        ],
      );

      expect(
        find.textContaining('applications to Germany', findRichText: true),
        findsOneWidget,
      );
    });
  });
}