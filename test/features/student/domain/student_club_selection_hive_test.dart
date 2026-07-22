import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hive_ce_test/hive_ce_test.dart';

import 'package:runata_pathway/core/persistence/hive_adapter_registration.dart';
import 'package:runata_pathway/features/student/domain/student_club_selection.dart';

void main() {
  setUp(() async {
    await setUpTestHive();
    registerAdapterIfNeeded(StudentClubSelectionAdapter());
  });

  tearDown(() async => tearDownTestHive());

  test('round-trips every field through a real Hive box', () async {
    final box = await Hive.openBox<StudentClubSelection>('club_selection_hive_test');
    final submittedAt = DateTime(2026, 7, 22, 14, 5);

    await box.put(
      'club_selection',
      StudentClubSelection(
        anchorMajor: 'Computer Science',
        rankedOthers: ['Sports Club', 'Music Club'],
        submittedAt: submittedAt,
      ),
    );

    final reopened = await Hive.openBox<StudentClubSelection>('club_selection_hive_test');
    final loaded = reopened.get('club_selection');

    expect(loaded, isNotNull);
    expect(loaded!.anchorMajor, 'Computer Science');
    expect(loaded.rankedOthers, ['Sports Club', 'Music Club']);
    expect(loaded.submittedAt, submittedAt);
  });

  test('a box with nothing written returns null, not a default instance',
      () async {
    final box =
        await Hive.openBox<StudentClubSelection>('club_selection_hive_empty');

    expect(box.get('club_selection'), isNull);
  });
}
