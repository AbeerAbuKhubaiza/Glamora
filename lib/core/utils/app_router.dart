import 'package:glamora_project/features/Auth/presentation/views/login_view.dart';
import 'package:glamora_project/features/Auth/presentation/views/signup_view.dart';
import 'package:glamora_project/features/Auth/presentation/views/widgets/forgot_password_page.dart';
import 'package:glamora_project/features/Onbording/presentation/views/onboarding_view.dart';
import 'package:glamora_project/features/Salons/presentation/views/home_view.dart';
import 'package:glamora_project/features/Search/presentaion/views/search_view.dart';
import 'package:glamora_project/home_admin_view.dart';
import 'package:glamora_project/home_onwer_view.dart';
import 'package:go_router/go_router.dart';
import '../../Features/Splash/presentation/views/splash_view.dart';

abstract class AppRouter {
  static const kHomeView = '/homeView';
  static const kOnbordingView = '/onboarding';
  static const kLoginView = '/loginview';
  static const kSignUpView = '/signupview';
  static const kSearchView = '/searchview';
  static const kForgetpassView = '/forgetpassview';
  static const kHomeOnwer = '/homeonwer';
  static const kHomeAdmin = '/homeadmin';

  //تناغم

  static final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashView()),
      GoRoute(
        path: kSearchView,
        builder: (context, state) => const SearchView(),
      ),
      GoRoute(
        path: kHomeAdmin,
        builder: (context, state) => const HomeAminView(),
      ),

      GoRoute(
        path: kHomeOnwer,
        builder: (context, state) => const HomeOnwerView(),
      ),

      GoRoute(path: kHomeView, builder: (context, state) => const HomeView()),
      GoRoute(path: kLoginView, builder: (context, state) => const LoginView()),
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
    ],
  );
}
