import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/choose_role_screen.dart';
import '../../features/auth/presentation/student_login_screen.dart';
import '../../features/student/presentation/explore_majors_screen.dart';
import '../../features/student/presentation/profile_screen.dart';
import '../../features/student/presentation/grades_screen.dart';
import '../../features/student/presentation/student_home_screen.dart';
import '../../features/student/presentation/stub_screens.dart';
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

  /// Explore Majors — Target Universities tab 1 (Day 3, in progress).
  /// Routed on its own for now, same "preview" treatment
  /// studentPathway's stub gives Profile/Tests/Grades — once Find
  /// Universities + My Shortlist exist, day3-trimmed-source.md's
  /// evidence that the original site treats all 3 as ONE screen with
  /// internal tab-switching (`renderUniPath()`), not 3 separate pages,
  /// is worth revisiting before this becomes 3 permanent separate
  /// routes instead of 1 route with tab state.
  static const studentExploreMajors = '/student/explore-majors';
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
        path: AppRoutes.studentExploreMajors,
        builder: (context, state) => const ExploreMajorsScreen(),
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
          target == AppRoutes.studentExploreMajors;

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