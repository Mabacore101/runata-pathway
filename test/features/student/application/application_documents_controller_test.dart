import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/application/application_documents_controller.dart';
import 'package:runata_pathway/features/student/data/student_application_documents_repository.dart';
import 'package:runata_pathway/features/student/domain/application_document_state.dart';

class _FakeRepository extends StudentApplicationDocumentsRepository {
  _FakeRepository(super.box, [Map<String, ApplicationDocumentState>? initial])
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

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(DocumentStatusAdapter());
    registerAdapterIfNeeded(ApplicationDocumentStateAdapter());
  });

  tearDown(() async => tearDownTestHive());

  late _FakeRepository repository;
  late ProviderContainer container;

  Future<ApplicationDocumentsController> setUpController(
    String boxName, [
    Map<String, ApplicationDocumentState>? initial,
  ]) async {
    final box = await Hive.openBox<ApplicationDocumentState>(boxName);
    repository = _FakeRepository(box, initial);
    container = ProviderContainer(
      overrides: [
        studentApplicationDocumentsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    return container.read(applicationDocumentsControllerProvider.notifier);
  }

  Map<String, ApplicationDocumentState> currentState() =>
      container.read(applicationDocumentsControllerProvider);

  group('build()', () {
    test('seeds exactly the 6 text/upload-kind doc keys, none extra', () async {
      await setUpController('adoc_ctrl_build_keys');

      expect(
        currentState().keys.toSet(),
        {'personal', 'commonapp', 'studyplan', 'sop', 'cv', 'recletter'},
      );
    });

    test('does NOT seed activities or portfolio (report/builder-kind, out '
        'of scope for this controller)', () async {
      await setUpController('adoc_ctrl_build_no_report_builder');

      expect(currentState().containsKey('activities'), isFalse);
      expect(currentState().containsKey('portfolio'), isFalse);
    });

    test('loads whatever the repository returns for a pre-seeded doc', () async {
      await setUpController('adoc_ctrl_build_preseed', {
        'personal': ApplicationDocumentState(
          docKey: 'personal',
          content: {'g11': 'Existing draft'},
        ),
      });

      expect(currentState()['personal']!.content['g11'], 'Existing draft');
    });
  });

  group('docFor', () {
    test('returns a fresh blank record for a valid key never written to',
        () async {
      final controller = await setUpController('adoc_ctrl_docfor_blank');

      final doc = controller.docFor('cv');
      expect(doc.docKey, 'cv');
      expect(doc.content, isEmpty);
      expect(doc.status, isEmpty);
      expect(doc.submitted, isFalse);
    });

    test('returns a blank record for an unrecognized key too (defensive)',
        () async {
      final controller = await setUpController('adoc_ctrl_docfor_unknown');

      final doc = controller.docFor('not_a_real_key');
      expect(doc.docKey, 'not_a_real_key');
      expect(doc.content, isEmpty);
    });
  });

  group('updateContent — local only, batched until save()', () {
    test('updates local state immediately but does NOT persist', () async {
      final controller = await setUpController('adoc_ctrl_update_content');

      controller.updateContent('personal', 'g11', 'A draft in progress');

      expect(currentState()['personal']!.content['g11'], 'A draft in progress');
      expect(repository.saved, isEmpty);
    });

    test('merges into the content map — editing one AY tab preserves '
        'another tab\'s existing draft', () async {
      final controller = await setUpController('adoc_ctrl_update_content_merge', {
        'personal': ApplicationDocumentState(
          docKey: 'personal',
          content: {'g10': 'Grade 10 draft'},
        ),
      });

      controller.updateContent('personal', 'g11', 'Grade 11 draft');

      expect(currentState()['personal']!.content['g10'], 'Grade 10 draft');
      expect(currentState()['personal']!.content['g11'], 'Grade 11 draft');
    });

    test('editing one doc\'s content never touches another doc\'s state — '
        'the whole point of the Map-based design', () async {
      final controller = await setUpController('adoc_ctrl_update_content_isolation');

      controller.updateContent('personal', 'g11', 'Personal statement draft');

      expect(currentState()['cv']!.content, isEmpty);
      expect(currentState()['commonapp']!.content, isEmpty);
    });
  });

  group('updateNote — local only, batched until save()', () {
    test('updates local state immediately but does NOT persist', () async {
      final controller = await setUpController('adoc_ctrl_update_note');

      controller.updateNote('recletter', 'https://drive.google.com/letter');

      expect(currentState()['recletter']!.note, 'https://drive.google.com/letter');
      expect(repository.saved, isEmpty);
    });
  });

  group('save', () {
    test('persists the doc\'s current local content + note to the '
        'repository', () async {
      final controller = await setUpController('adoc_ctrl_save');

      controller.updateContent('sop', 'g12', 'My statement of purpose draft.');
      controller.updateNote('sop', 'https://docs.google.com/example');
      await controller.save('sop');

      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.content['g12'], 'My statement of purpose draft.');
      expect(repository.saved.single.note, 'https://docs.google.com/example');
    });

    test('only persists the ONE doc it\'s called for — a per-doc Save '
        'button never writes the other 5 docs', () async {
      final controller = await setUpController('adoc_ctrl_save_scoped');

      controller.updateContent('personal', 'g11', 'Personal draft');
      controller.updateContent('cv', 'g11', 'CV content');
      await controller.save('personal');

      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.docKey, 'personal');
    });
  });

  group('markReady — fully unconditional flip (Day 6 item 2)', () {
    test('sets status[ay] to finalStatus and persists immediately, with '
        'no prior save() call needed', () async {
      final controller = await setUpController('adoc_ctrl_mark_ready');

      await controller.markReady('personal', 'g11');

      expect(currentState()['personal']!.status['g11'], DocumentStatus.finalStatus);
      expect(repository.saved, hasLength(1));
      expect(repository.load('personal').status['g11'], DocumentStatus.finalStatus);
    });

    test('works even when content is completely empty — no non-empty '
        'check, matching the JS exactly', () async {
      final controller = await setUpController('adoc_ctrl_mark_ready_empty');

      // Deliberately never call updateContent — content stays empty.
      await controller.markReady('personal', 'g11');

      expect(currentState()['personal']!.content['g11'], isNull);
      expect(currentState()['personal']!.status['g11'], DocumentStatus.finalStatus);
    });

    test('does nothing but flip status — content, note, and submitted are '
        'all untouched', () async {
      final controller = await setUpController(
        'adoc_ctrl_mark_ready_no_side_effects',
        {
          'personal': ApplicationDocumentState(
            docKey: 'personal',
            content: {'g11': 'Some draft text'},
            note: 'https://example.com/doc',
            submitted: false,
          ),
        },
      );

      await controller.markReady('personal', 'g11');

      final result = currentState()['personal']!;
      expect(result.content['g11'], 'Some draft text', reason: 'content must be untouched');
      expect(result.note, 'https://example.com/doc', reason: 'note must be untouched');
      expect(result.submitted, isFalse, reason: 'submitted must be untouched');
    });

    test('only affects the AY tab it was called for — Grade 10 stays '
        'notStarted when Grade 11 is marked ready', () async {
      final controller = await setUpController('adoc_ctrl_mark_ready_ay_scoped');

      await controller.markReady('personal', 'g11');

      expect(
        currentState()['personal']!.statusFor('g10'),
        DocumentStatus.notStarted,
      );
      expect(
        currentState()['personal']!.statusFor('g11'),
        DocumentStatus.finalStatus,
      );
    });

    test('is idempotent — calling it twice on an already-Final doc keeps '
        'it Final without error', () async {
      final controller = await setUpController('adoc_ctrl_mark_ready_idempotent');

      await controller.markReady('personal', 'g11');
      await controller.markReady('personal', 'g11');

      expect(currentState()['personal']!.status['g11'], DocumentStatus.finalStatus);
      expect(repository.saved, hasLength(2));
    });

    test('does not affect any other doc', () async {
      final controller = await setUpController('adoc_ctrl_mark_ready_doc_isolation');

      await controller.markReady('personal', 'g11');

      expect(currentState()['cv']!.status, isEmpty);
      expect(currentState()['sop']!.status, isEmpty);
    });
  });

  group('toggleSubmitted (Recommendation Letters\' upload toggle)', () {
    test('flips submitted and persists immediately', () async {
      final controller = await setUpController('adoc_ctrl_toggle_submitted');

      await controller.toggleSubmitted('recletter');

      expect(currentState()['recletter']!.submitted, isTrue);
      expect(repository.saved, hasLength(1));
      expect(repository.load('recletter').submitted, isTrue);
    });

    test('toggling twice returns to the original value', () async {
      final controller = await setUpController('adoc_ctrl_toggle_twice');

      await controller.toggleSubmitted('recletter');
      await controller.toggleSubmitted('recletter');

      expect(currentState()['recletter']!.submitted, isFalse);
    });

    test('is a bare toggle — content, note, and status are all untouched',
        () async {
      final controller = await setUpController(
        'adoc_ctrl_toggle_no_side_effects',
        {
          'recletter': ApplicationDocumentState(
            docKey: 'recletter',
            note: 'letter.pdf',
            status: {'g11': DocumentStatus.draft},
          ),
        },
      );

      await controller.toggleSubmitted('recletter');

      final result = currentState()['recletter']!;
      expect(result.note, 'letter.pdf');
      expect(result.status['g11'], DocumentStatus.draft);
    });
  });
}
