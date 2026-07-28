import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import 'activities_report_controller.dart';
import 'application_documents_controller.dart';
import 'portfolio_controller.dart';
import '../domain/application_materials_catalog.dart';

/// Mirrors the JS's `matStartedCount(stu, studentAY(stu))` — combines all
/// 4 Application Materials doc kinds' own already-established "started"
/// definitions into one count: report/builder
/// (`StudentActivitiesReport.hasAnyData`/`StudentPortfolio.works.
/// isNotEmpty`) plus text/upload (`ApplicationDocumentState.startedFor`).
///
/// Reads the student's own default AY tab directly from
/// [authControllerProvider] (the same `defaultAcademicYearIndexForGrade`
/// used everywhere else this rebuild needs "the student's own grade
/// tab") rather than taking it as a parameter — every caller of this
/// provider wants the SAME AY (the student's own), so a plain `Provider`
/// is enough; there's no need for a `.family` provider here, matching
/// how this codebase has avoided introducing that shape everywhere else
/// (see `ApplicationDocumentsController`'s own doc comment for the
/// reasoning behind that choice).
final materialsStartedCountProvider = Provider<int>((ref) {
  final grade = ref.watch(authControllerProvider).session?.grade;
  final ay = academicYearTabs[defaultAcademicYearIndexForGrade(grade)].id;

  final report = ref.watch(activitiesReportControllerProvider);
  final portfolio = ref.watch(portfolioControllerProvider);
  final docs = ref.watch(applicationDocumentsControllerProvider);

  var count = 0;
  for (final doc in materialDocs) {
    switch (doc.kind) {
      case MaterialDocKind.report:
        if (report.hasAnyData) count++;
      case MaterialDocKind.builder:
        if (portfolio.works.isNotEmpty) count++;
      case MaterialDocKind.text:
        if (docs[doc.key]?.startedFor(ay, isUpload: false) ?? false) count++;
      case MaterialDocKind.upload:
        if (docs[doc.key]?.startedFor(ay, isUpload: true) ?? false) count++;
    }
  }
  return count;
});
