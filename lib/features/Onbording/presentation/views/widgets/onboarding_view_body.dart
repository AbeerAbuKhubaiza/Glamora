import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/core/utils/app_router.dart';
import 'package:glamora_project/core/utils/assets.dart';
import 'package:glamora_project/features/Onbording/presentation/models/onboarding_model.dart';
import 'package:glamora_project/features/Onbording/presentation/views/widgets/onboarding_indicator.dart';
import 'package:glamora_project/features/Onbording/presentation/views/widgets/onboarding_page_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewbody extends StatefulWidget {
  const OnboardingViewbody({super.key});

  @override
  State<OnboardingViewbody> createState() => _OnboardingViewbodyState();
}

class _OnboardingViewbodyState extends State<OnboardingViewbody> {
  late final PageController _controller;
  int _currentIndex = 0;

  final List<OnboardingModel> pages = [
    OnboardingModel(
      title: 'Welcome to Your Beauty Haven',
      subtitle:
          'Step into a world where beauty meets self-love. discover a curated collection of makeup, skincare, and wellness essentials.',
      assetImage: AssetsData.onBord1,
    ),
    OnboardingModel(
      title: 'Clean, Safe & Natural',
      subtitle:
          'We believe your skin deserves the best. That’s why our products are made with gentle, natural ingredients full of nourishing goodness your skin will love.',
      assetImage: AssetsData.onBord2,
    ),
    OnboardingModel(
      title: 'Exclusive Deals Just for You',
      subtitle:
          'Join our beauty community and enjoy special discounts, first-access to new arrivals, and surprise gifts. ',
      assetImage: AssetsData.onBord3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      GoRouter.of(context).pushReplacement(AppRouter.kHomeView);
    } else {
      GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
    }
  }

  void _skip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      GoRouter.of(context).pushReplacement(AppRouter.kHomeView);
    } else {
      GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
    }
  }

  void _next() {
    if (_currentIndex < pages.length - 1) {
      if (_controller.hasClients) {
        _controller.animateToPage(
          _currentIndex + 1,
          duration: Duration(milliseconds: 400),
          curve: Curves.ease,
        );
      }
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            right: 12,
            top: 12,
            child: TextButton(
              onPressed: _skip,
              child: Text(
                'Skip',
                style: TextStyle(fontSize: w * 0.038, color: kPrimaryColor),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: h * 0.65,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return OnboardingPageWidget(page: pages[index]);
                  },
                ),
              ),

              OnboardingIndicator(
                count: pages.length,
                activeIndex: _currentIndex,
              ),
              SizedBox(height: h * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentIndex == pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: TextStyle(
                        fontSize: w * 0.045,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: h * 0.035),
            ],
          ),
        ],
      ),
    );
  }
}
