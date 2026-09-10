import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/auth/presentation/screens/login_screen.dart';
import 'package:gymrank/features/auth/presentation/screens/signup_screen.dart';
import 'package:gymrank/features/body_measurement/presentation/screens/body_measurement_screen.dart';
import 'package:gymrank/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:gymrank/features/championships/presentation/screens/championships_screen.dart';
import 'package:gymrank/features/checkin/presentation/screens/checkin_screen.dart';
import 'package:gymrank/features/friendship/presentation/screens/friends_screen.dart';
import 'package:gymrank/features/gamification/presentation/screens/achievements_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/client_detail_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/coach_dashboard_screen.dart';
import 'package:gymrank/features/coach_panel/presentation/screens/coach_setup_screen.dart';
import 'package:gymrank/features/home/presentation/screens/app_shell_screen.dart';
import 'package:gymrank/features/home/presentation/screens/home_dashboard_screen.dart';
import 'package:gymrank/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/screens/my_plans_screen.dart';
import 'package:gymrank/features/plans/presentation/screens/plan_detail_screen.dart';
import 'package:gymrank/features/plans/presentation/screens/plan_review_screen.dart';
import 'package:gymrank/features/profile/presentation/screens/profile_screen.dart';
import 'package:gymrank/features/progress_photo/presentation/screens/progress_photo_screen.dart';
import 'package:gymrank/features/rankings/presentation/screens/rankings_screen.dart';
import 'package:gymrank/features/rewards/presentation/screens/my_rewards_screen.dart';
import 'package:gymrank/features/social_feed/presentation/screens/feed_screen.dart';
import 'package:gymrank/features/workout/presentation/screens/log_workout_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (authState.isLoading) return null;
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeDashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/rankings', builder: (context, state) => const RankingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/challenges', builder: (context, state) => const ChallengesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/checkin',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlide(state, const CheckInScreen()),
      ),
      GoRoute(
        path: '/workout/new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const LogWorkoutScreen()),
      ),
      GoRoute(
        path: '/body-measurement',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const BodyMeasurementScreen()),
      ),
      GoRoute(
        path: '/progress-photos',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const ProgressPhotoScreen()),
      ),
      GoRoute(
        path: '/achievements',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const AchievementsScreen()),
      ),
      GoRoute(
        path: '/friends',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlide(state, const FriendsScreen()),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '/championships',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const ChampionshipsScreen()),
      ),
      GoRoute(
        path: '/rewards',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlide(state, const MyRewardsScreen()),
      ),
      // Painel da treinadora (papel `coach`).
      GoRoute(
        path: '/coach',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _fadeSlide(state, const CoachDashboardScreen()),
        routes: [
          GoRoute(
            path: 'setup',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) =>
                _fadeSlide(state, const CoachSetupScreen()),
          ),
          GoRoute(
            path: 'clients/:userId',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _fadeSlide(
              state,
              ClientDetailScreen(userId: state.pathParameters['userId']!),
            ),
            routes: [
              // Captura manual de um plano para o aluno (?kind=dieta…).
              GoRoute(
                path: 'plans/new',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) => _fadeSlide(
                  state,
                  PlanReviewScreen(
                    userId: state.pathParameters['userId']!,
                    kind: PlanKind.values.asNameMap()[
                            state.uri.queryParameters['kind'] ?? ''] ??
                        PlanKind.entrenamiento,
                  ),
                ),
              ),
            ],
          ),
          // Revisão do resultado do parser de um documento enviado.
          GoRoute(
            path: 'documents/:docId/review',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _fadeSlide(
              state,
              PlanReviewScreen(documentId: state.pathParameters['docId']!),
            ),
          ),
          // Editar e republicar um plano vigente.
          GoRoute(
            path: 'plans/:planId/edit',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _fadeSlide(
              state,
              PlanReviewScreen(planId: state.pathParameters['planId']!),
            ),
          ),
        ],
      ),
      // Planos publicados (aluno; a treinadora também abre daqui).
      GoRoute(
        path: '/plans',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _fadeSlide(state, const MyPlansScreen()),
        routes: [
          GoRoute(
            path: ':planId',
            parentNavigatorKey: _rootNavigatorKey,
            pageBuilder: (context, state) => _fadeSlide(
              state,
              PlanDetailScreen(planId: state.pathParameters['planId']!),
            ),
          ),
        ],
      ),
    ],
  );
}

/// Transição padrão das telas empurradas: fade + leve deslize de baixo,
/// dando fluidez à navegação.
CustomTransitionPage<void> _fadeSlide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
