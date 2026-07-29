import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
import '../../features/student/presentation/application_materials_screen.dart';
import '../../features/student/presentation/counsellor_corner_screen.dart';
import '../../features/student/presentation/dashboard_screen.dart';
import '../../features/student/presentation/pathways_screen.dart';
import '../../features/student/presentation/profile_screen.dart';
import '../../features/student/presentation/grades_screen.dart';
import '../../features/student/presentation/my_clubs_screen.dart';
import '../../features/student/presentation/student_home_screen.dart';
import '../../features/student/presentation/stub_screens.dart';
import '../../features/student/presentation/target_universities_screen.dart';
import '../../features/student/presentation/tests_screen.dart';

/// Route paths, named here so screens/tests never hardcode raw strings.
class AppRoutes {
  AppRoutes._();
  static const chooseRole = '/';
  static const studentLogin = '/student/login';
  static const studentHome = '/student/home';
  static const studentDashboard = '/student/dashboard';
  static const studentPathway = '/student/pathway';
  static const studentNavGrid = '/student/nav-grid';
  static const studentProfile = '/student/profile';
  static const studentTests = '/student/tests';
  static const studentGrades = '/student/grades';

  /// Target Universities — hosts Explore Majors / Find Universities / My
  /// Shortlist as tabs on ONE screen (see target_universities_screen.dart),
  /// mirroring the original site's single `renderUniPath()` function
  /// rather than 3 separate pages. Replaces the earlier
  /// `studentExploreMajors` route, which pointed at Explore Majors as its
  /// own standalone page before Find Universities existed.
  static const studentTargetUniversities = '/student/target-universities';

  /// My Clubs — Day 4. Not tabbed like Target Universities: the JS's
  /// renderClubs()/renderConfirm()/renderReturning() etc. are SUB-STATES
  /// of one screen, not separate routes — this one route hosts all of
  /// them, MyClubsScreen owning that sub-state internally as items 2-5
  /// land, same as TargetUniversitiesScreen owns its tab index.
  static const studentClubs = '/student/clubs';

  /// Application Materials — Day 5. Not tabbed by go_router the way
  /// Target Universities is, and not sub-routed per doc the way a naive
  /// reading of "8 sections" might suggest: the JS's `renderMaterials()`
  /// /`renderMatDoc()` split is a single function swapping its own
  /// output based on one `matDoc` variable — this route hosts all of
  /// that internally (`ApplicationMaterialsScreen._openDocKey`), same
  /// shape as [studentClubs]'s `ClubsView` sub-state switch.
  static const studentMaterials = '/student/materials';

  /// Counsellor's Corner — Day 6. Unlike Application Materials' 8 docs,
  /// this is a single, standalone screen with no internal sub-state to
  /// host — a real, top-level route, reached from Nav Grid once that's
  /// built (today it's only reachable via a temporary preview link on
  /// [studentNavGrid]'s stub, same interim pattern [studentPathway]'s
  /// stub already uses for its 6 forms).
  static const studentCounsellorCorner = '/student/counsellor-corner';

  /// Pathways — Runata's Signature Country Pathways (Germany/China
  /// guides). Day 6. Named [studentCountryPathways], deliberately NOT
  /// "studentPathways" — this rebuild already has [studentPathway]
  /// (singular), a DIFFERENT feature entirely (the 6-form Pathway hub
  /// stub, this rebuild's own naming, not present in the original JS).
  /// The JS's own "Pathways" (country guides) and this rebuild's
  /// "Pathway" (form hub) are two unrelated things that happen to share
  /// a near-identical name — picking a clearly distinct constant here
  /// avoids adding a typo-prone collision on top of an already-confusing
  /// naming coincidence. Same standalone-screen, no-internal-sub-state
  /// shape as [studentCounsellorCorner] — reached from Nav Grid once
  /// that's built, today only via a temporary preview link on
  /// [studentNavGrid]'s stub.
  static const studentCountryPathways = '/student/country-pathways';
}

/// Bridges auth-state changes into go_router's `refreshListenable`.
///
/// Explicit in-app transitions (sign-in success, sign-out) already navigate
/// with context.go(...) themselves, which re-runs `redirect` on its own.
/// But go_router's `redirect` ONLY re-runs when a navigation event happens —
/// if auth state changes with no accompanying navigation call (e.g. a
/// session gets restored from storage before the user taps anything, once
/// that exists), nothing would ever prompt the guard below to re-check.
/// This listenable exists so ANY sign-in/sign-out state change forces a
/// fresh redirect check against whatever screen is currently showing, not
/// just ones the app happened to trigger via context.go(...).
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.isSignedIn != next.isSignedIn) {
          notifyListeners();
        }
      },
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefreshListenable(ref);
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.chooseRole,
    refreshListenable: authRefresh,
    routes: [
      GoRoute(
        path: AppRoutes.chooseRole,
        builder: (context, state) => const ChooseRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentLogin,
        builder: (context, state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentHome,
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentPathway,
        builder: (context, state) => const StudentPathwayStubScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentNavGrid,
        builder: (context, state) => const StudentNavGridStubScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentTests,
        builder: (context, state) => const TestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentGrades,
        builder: (context, state) => const GradesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentTargetUniversities,
        builder: (context, state) => const TargetUniversitiesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentClubs,
        builder: (context, state) => const MyClubsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentMaterials,
        builder: (context, state) => const ApplicationMaterialsScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentCounsellorCorner,
        builder: (context, state) => const CounsellorCornerScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentCountryPathways,
        builder: (context, state) => const PathwaysScreen(),
      ),
    ],
    redirect: (context, state) {
      final isSignedIn = ref.read(authControllerProvider).isSignedIn;
      final target = state.matchedLocation;

      final isProtectedStudentRoute = target == AppRoutes.studentHome ||
          target == AppRoutes.studentDashboard ||
          target == AppRoutes.studentPathway ||
          target == AppRoutes.studentNavGrid ||
          target == AppRoutes.studentProfile ||
          target == AppRoutes.studentTests ||
          target == AppRoutes.studentGrades ||
          target == AppRoutes.studentTargetUniversities ||
          target == AppRoutes.studentClubs ||
          target == AppRoutes.studentMaterials ||
          target == AppRoutes.studentCounsellorCorner ||
          target == AppRoutes.studentCountryPathways;

      // Both "public-only" screens (Choose Role and the Login form itself)
      // should be skipped once a session already exists — not just Login.
      final isPublicOnlyRoute =
          target == AppRoutes.chooseRole || target == AppRoutes.studentLogin;

      if (!isSignedIn && isProtectedStudentRoute) {
        return AppRoutes.studentLogin;
      }
      if (isSignedIn && isPublicOnlyRoute) {
        return AppRoutes.studentHome;
      }
      return null;
    },
  );
});