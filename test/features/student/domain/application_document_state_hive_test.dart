import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/application_document_state.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(DocumentStatusAdapter());
    registerAdapterIfNeeded(ApplicationDocumentStateAdapter());
  });

  tearDown(() async => tearDownTestHive());

  group('ApplicationDocumentState Hive round-trip', () {
    test('writes and reads back a fully-populated record, keyed by docKey',
        () async {
      final box =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_full');

      final doc = ApplicationDocumentState(
        docKey: 'personal',
        content: {
          'g10': 'Early draft from Grade 10.',
          'g11': 'Revised draft from Grade 11.',
        },
        status: {
          'g10': DocumentStatus.draft,
          'g11': DocumentStatus.inReview,
        },
        note: 'https://drive.google.com/example',
        submitted: false,
      );

      await box.put(doc.docKey, doc);
      await box.close();

      final reopened =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_full');
      final result = reopened.get('personal');

      expect(result, isNotNull);
      expect(result!.content['g10'], 'Early draft from Grade 10.');
      expect(result.content['g11'], 'Revised draft from Grade 11.');
      expect(result.status['g10'], DocumentStatus.draft);
      expect(result.status['g11'], DocumentStatus.inReview);
      expect(result.note, 'https://drive.google.com/example');
      expect(result.submitted, isFalse);
    });

    test('a Map<String, String> content field with multiple AY keys '
        'round-trips every key correctly — new territory for this app, '
        'no prior model has used a Map-valued HiveField', () async {
      final box =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_content_map');

      await box.put(
        'studyplan',
        ApplicationDocumentState(
          docKey: 'studyplan',
          content: {'g10': 'g10 text', 'g11': 'g11 text', 'g12': 'g12 text'},
        ),
      );
      await box.close();

      final reopened =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_content_map');
      final result = reopened.get('studyplan')!;

      expect(result.content, hasLength(3));
      expect(result.content['g10'], 'g10 text');
      expect(result.content['g11'], 'g11 text');
      expect(result.content['g12'], 'g12 text');
    });

    test('a Map<String, DocumentStatus> status field preserves enum '
        'identity for every key after reopening the box — the specific '
        'pattern worth verifying, since an enum-valued Map is a step '
        'beyond the List<String> precedent (StudentGradesSettings)',
        () async {
      final box =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_status_map');

      await box.put(
        'sop',
        ApplicationDocumentState(
          docKey: 'sop',
          status: {
            'g10': DocumentStatus.notStarted,
            'g11': DocumentStatus.draft,
            'g12': DocumentStatus.finalStatus,
          },
        ),
      );
      await box.close();

      final reopened =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_status_map');
      final result = reopened.get('sop')!;

      expect(result.status['g10'], DocumentStatus.notStarted);
      expect(result.status['g11'], DocumentStatus.draft);
      expect(result.status['g12'], DocumentStatus.finalStatus);
    });

    test('every DocumentStatus enum value survives a round-trip', () async {
      final box =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_enum_matrix');

      for (final status in DocumentStatus.values) {
        final key = 'doc_${status.name}';
        await box.put(
          key,
          ApplicationDocumentState(docKey: key, status: {'g10': status}),
        );
      }
      await box.close();

      final reopened =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_enum_matrix');
      for (final status in DocumentStatus.values) {
        final key = 'doc_${status.name}';
        final result = reopened.get(key);
        expect(result, isNotNull, reason: 'missing round-tripped row $key');
        expect(result!.status['g10'], status);
      }
    });

    test('multiple distinct docs coexist independently in the same flat '
        'box — matches the 6 real doc keys (personal/commonapp/studyplan/'
        'sop/cv/recletter) all living in one box, each its own record',
        () async {
      final box =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_multi_doc');

      await box.put(
        'personal',
        ApplicationDocumentState(
          docKey: 'personal',
          content: {'g11': 'Personal statement draft'},
        ),
      );
      await box.put(
        'recletter',
        ApplicationDocumentState(docKey: 'recletter', note: 'letter.pdf', submitted: true),
      );

      expect(box.get('personal')!.content['g11'], 'Personal statement draft');
      expect(box.get('personal')!.submitted, isFalse);
      expect(box.get('recletter')!.note, 'letter.pdf');
      expect(box.get('recletter')!.submitted, isTrue);
    });

    test('a key with nothing written returns null, not a default instance '
        '— same contract as every other model in this app', () async {
      final box =
          await Hive.openBox<ApplicationDocumentState>('adoc_box_missing');

      expect(box.get('cv'), isNull);
    });
  });

  group('contentFor / statusFor defaults (pure model logic, no Hive)', () {
    test('a new ApplicationDocumentState() starts with empty content/status '
        'maps, null note, and submitted=false', () {
      final doc = ApplicationDocumentState(docKey: 'cv');

      expect(doc.content, isEmpty);
      expect(doc.status, isEmpty);
      expect(doc.note, isNull);
      expect(doc.submitted, isFalse);
    });

    test('contentFor returns "" for an AY tab never written to', () {
      final doc = ApplicationDocumentState(docKey: 'cv', content: {'g10': 'hi'});

      expect(doc.contentFor('g10'), 'hi');
      expect(doc.contentFor('g11'), '');
      expect(doc.contentFor('g12'), '');
    });

    test('statusFor returns notStarted for an AY tab never written to', () {
      final doc = ApplicationDocumentState(
        docKey: 'cv',
        status: {'g10': DocumentStatus.finalStatus},
      );

      expect(doc.statusFor('g10'), DocumentStatus.finalStatus);
      expect(doc.statusFor('g11'), DocumentStatus.notStarted);
      expect(doc.statusFor('g12'), DocumentStatus.notStarted);
    });
  });

  group('startedFor (pure model logic, no Hive) — mirrors matStartedCount\'s '
      'per-doc JS check', () {
    test('false for an untouched text-kind doc', () {
      final doc = ApplicationDocumentState(docKey: 'personal');
      expect(doc.startedFor('g10', isUpload: false), isFalse);
    });

    test('true for a text-kind doc once content is non-empty for that AY',
        () {
      final doc =
          ApplicationDocumentState(docKey: 'personal', content: {'g10': 'x'});
      expect(doc.startedFor('g10', isUpload: false), isTrue);
      // A different, untouched AY tab is unaffected.
      expect(doc.startedFor('g11', isUpload: false), isFalse);
    });

    test('true for a text-kind doc once status is anything but notStarted, '
        'even with empty content for that AY', () {
      final doc = ApplicationDocumentState(
        docKey: 'personal',
        status: {'g10': DocumentStatus.draft},
      );
      expect(doc.startedFor('g10', isUpload: false), isTrue);
    });

    test('true once submitted=true, regardless of kind or AY tab', () {
      final doc = ApplicationDocumentState(docKey: 'recletter', submitted: true);
      expect(doc.startedFor('g10', isUpload: true), isTrue);
      expect(doc.startedFor('g12', isUpload: true), isTrue);
    });

    test('note only counts toward "started" when isUpload is true — a '
        'text-kind doc\'s optional link does NOT count on its own, '
        'matching the JS\'s docKind(k)==="upload" guard exactly', () {
      final withNote =
          ApplicationDocumentState(docKey: 'personal', note: 'https://x.com');

      expect(withNote.startedFor('g10', isUpload: false), isFalse);
      expect(withNote.startedFor('g10', isUpload: true), isTrue);
    });

    test('false for an untouched upload-kind doc (Recommendation Letters '
        'before any note or submit)', () {
      final doc = ApplicationDocumentState(docKey: 'recletter');
      expect(doc.startedFor('g10', isUpload: true), isFalse);
    });
  });
}
