import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
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
        builder: (context, state) => const StudentDashboardStubScreen(),
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
          target == AppRoutes.studentClubs;

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