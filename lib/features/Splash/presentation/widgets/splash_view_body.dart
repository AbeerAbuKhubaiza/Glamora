import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/utils/assets.dart';
import 'package:glamora_project/features/splash/presentation/widgets/sliding_img.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/routing/app_router.dart';

class SplashViewBody extends StatefulWidget {
  const SplashViewBody({super.key});

  @override
  State<SplashViewBody> createState() => _SplashViewBodyState();
}

class _SplashViewBodyState extends State<SplashViewBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  final _auth = FirebaseAuth.instance;
  final _usersRef = FirebaseDatabase.instance.ref('users');

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startRouting();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cornerW = size.width * AppSizes.splashCornerFactor;
    final cornerH = size.height * AppSizes.splashCornerFactor;

    return SafeArea(
      child: Stack(
        children: [
          _Corner(
            asset: AssetsData.sp1,
            alignment: Alignment.topRight,
            w: cornerW,
            h: cornerH,
          ),
          _Corner(
            asset: AssetsData.sp2,
            alignment: Alignment.topLeft,
            w: cornerW,
            h: cornerH,
          ),
          _Corner(
            asset: AssetsData.sp3,
            alignment: Alignment.bottomRight,
            w: cornerW,
            h: cornerH,
          ),
          _Corner(
            asset: AssetsData.sp4,
            alignment: Alignment.bottomLeft,
            w: cornerW,
            h: cornerH,
          ),
          Center(child: SlidingImg(slidingAnimation: _slide)),
        ],
      ),
    );
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.splashAnim,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(_controller);

    _controller.forward();
  }

  void _startRouting() {
    Future.delayed(AppDurations.splashDelay, () async {
      if (!mounted) return;

      final route = await _decideNextRoute();
      if (!mounted) return;

      context.go(route);
    });
  }

  Future<String> _decideNextRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(AppKeys.seenOnboarding) ?? false;
      if (!seen) return AppRouter.kOnbordingView;

      final fbUser = _auth.currentUser;
      if (fbUser == null) return AppRouter.kLoginView;

      final snap = await _usersRef.child(fbUser.uid).get();
      if (!snap.exists || snap.value is! Map) {
        await _auth.signOut();
        return AppRouter.kLoginView;
      }

      final data = Map<String, dynamic>.from(snap.value as Map);
      final role = (data['role'] ?? 'client').toString();
      final isApproved = (data['isApproved'] as bool?) ?? true;

      if (role == 'owner') {
        if (isApproved) return AppRouter.kHomeOnwer;
        await _auth.signOut();
        return AppRouter.kLoginView;
      }

      return AppRouter.kHomeView;
    } catch (_) {
      await _auth.signOut();
      return AppRouter.kLoginView;
    }
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    required this.asset,
    required this.alignment,
    required this.w,
    required this.h,
  });

  final String asset;
  final Alignment alignment;
  final double w;
  final double h;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: SvgPicture.asset(asset, width: w, height: h, fit: BoxFit.contain),
    );
  }
}
