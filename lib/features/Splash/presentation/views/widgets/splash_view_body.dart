import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glamora_project/core/utils/assets.dart';
import 'package:glamora_project/features/Splash/presentation/views/widgets/sliding_img.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/app_router.dart';

class SplashViewbody extends StatefulWidget {
  const SplashViewbody({super.key});

  @override
  State<SplashViewbody> createState() => _SplashViewbodyState();
}

class _SplashViewbodyState extends State<SplashViewbody>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  late Animation<Offset> slidingAnimation;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    initSlidingAnimation();
    navigateToHome();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: SvgPicture.asset(
              AssetsData.sp1,
              width: screenWidth * 0.12,
              height: screenHeight * 0.12,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SvgPicture.asset(
              AssetsData.sp2,
              width: screenWidth * 0.12,
              height: screenHeight * 0.12,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SvgPicture.asset(
              AssetsData.sp3,
              width: screenWidth * 0.12,
              height: screenHeight * 0.12,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: SvgPicture.asset(
              AssetsData.sp4,
              width: screenWidth * 0.12,
              height: screenHeight * 0.12,
              fit: BoxFit.contain,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: SlidingImg(slidingAnimation: slidingAnimation),
          ),
        ],
      ),
    );
  }

  void initSlidingAnimation() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    slidingAnimation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(animationController);

    animationController.forward();
  }

  void navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      // لو لسه ما شاف الـ Onboarding
      if (!seenOnboarding) {
        GoRouter.of(context).pushReplacement(AppRouter.kOnbordingView);
        return;
      }

      // فحص حالة اليوزر في Firebase Auth
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        // مافي يوزر مسجل دخول → روح عاللوقن
        GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
        return;
      }

      try {
        // قراءة بيانات اليوزر من Realtime Database
        final snapshot = await _db.child('users').child(fbUser.uid).get();

        if (!snapshot.exists || snapshot.value is! Map) {
          // في يوزر في Auth بس ما في داتا إلُه في DB → نعمل signOut ونرجعه لوجن
          await _auth.signOut();
          if (!mounted) return;
          GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
          return;
        }

        final map = Map<String, dynamic>.from(snapshot.value as Map);
        final role = map['role']?.toString() ?? 'client';
        final bool isApproved = map['isApproved'] ?? true;

        if (!mounted) return;

        if (role == 'client') {
          GoRouter.of(context).pushReplacement(AppRouter.kHomeView);
        } else if (role == 'owner') {
          if (isApproved) {
            GoRouter.of(context).pushReplacement(AppRouter.kHomeOnwer);
          } else {
            // مش موافَق عليه → رجّعيه على اللوقن أو صفحة خاصة
            await _auth.signOut();
            GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
          }
        } else if (role == 'admin') {
          GoRouter.of(context).pushReplacement(AppRouter.kHomeAdmin);
        } else {
          // role غريب → نعتبره غير صالح
          await _auth.signOut();
          GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
        }
      } catch (e) {
        // لو صار خطأ في القراءة → رجّعيه على اللوقن
        if (!mounted) return;
        await _auth.signOut();
        GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
      }
    });
  }
}
