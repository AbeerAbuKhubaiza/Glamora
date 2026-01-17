import 'package:flutter/material.dart';
import 'package:glamora_project/features/Auth/presentation/views/login_view.dart';
import 'package:glamora_project/features/Auth/presentation/views/signup_view.dart';
import 'package:glamora_project/features/Auth/presentation/views/forgot_password_view.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Onbording/presentation/views/onboarding_view.dart';
import 'package:glamora_project/features/Home/presentation/views/home_view.dart';
import 'package:glamora_project/features/Home/presentation/views/search_view.dart';
import 'package:glamora_project/features/Splash/presentation/views/splash_view.dart';
import 'package:glamora_project/features/Owner/home_onwer_view.dart';
import 'package:glamora_project/features/Owner/owner_salon_dashboard.dart';
import 'package:go_router/go_router.dart';

abstract class AppRouter {
  static const kHomeView = '/homeView';
  static const kOnbordingView = '/onboarding';
  static const kLoginView = '/loginview';
  static const kSignUpView = '/signupview';
  static const kSearchView = '/searchview';
  static const kForgetpassView = '/forgetpassview';
  static const kHomeOnwer = '/homeonwer';
  static const kOwnerSalonDashboard = '/dashboard';

  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashView()),
      GoRoute(path: kHomeView, builder: (context, state) => const HomeView()),
      GoRoute(
        path: kHomeOnwer,
        builder: (context, state) => const HomeOnwerView(),
      ),
      GoRoute(path: kLoginView, builder: (context, state) => const LoginView()),

      GoRoute(
        path: '/owner-dashboard',
        name: AppRouter.kOwnerSalonDashboard,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          if (extra == null ||
              extra['owner'] == null ||
              extra['salon'] == null) {
            return MaterialPage(
              child: Scaffold(body: Center(child: Text('Error: Missing data'))),
            );
          }

          return MaterialPage(
            child: OwnerSalonDashboard(
              owner: extra['owner'] as AppUser,
              salon: extra['salon'] as Salon,
              salons: extra['salons'],
            ),
          );
        },
      ),
      GoRoute(
        path: kSignUpView,
        builder: (context, state) => const SignupView(),
      ),
      GoRoute(
        path: kOnbordingView,
        builder: (context, state) => const OnboardingView(),
      ),
      GoRoute(
        path: kForgetpassView,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: kSearchView,
        builder: (context, state) => const SearchView(),
      ),
    ],
  );
}
