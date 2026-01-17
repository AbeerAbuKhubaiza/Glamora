import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:glamora_project/core/utils/assets.dart';
import 'package:glamora_project/features/Onbording/data/models/onboarding_model.dart';
import 'package:glamora_project/features/Onbording/presentation/widgets/onboarding_indicator.dart';
import 'package:glamora_project/features/Onbording/presentation/widgets/onboarding_page_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingViewBody extends StatefulWidget {
  const OnboardingViewBody({super.key});

  @override
  State<OnboardingViewBody> createState() => _OnboardingViewBodyState();
}

class _OnboardingViewBodyState extends State<OnboardingViewBody> {
  late final PageController _controller;
  int _index = 0;

  static const List<OnboardingModel> _pages = [
    OnboardingModel(
      title: 'Book Beauty in Seconds',
      subtitle:
          'Discover salons, book instantly, and enjoy personalized beauty experiences tailored to your style and schedule.',
      assetImage: AssetsData.onBord1,
    ),
    OnboardingModel(
      title: 'Clean, Safe & Reviewed',
      subtitle:
          'Trusted professionals, clean tools, and transparent reviews help you choose the safest services every time.',
      assetImage: AssetsData.onBord2,
    ),
    OnboardingModel(
      title: 'Offers & Rewards for You',
      subtitle:
          'Join our beauty community and enjoy discounts, early access to new salons, and surprise gifts.',
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

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppKeys.seenOnboarding, true);

    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    context.go(user != null ? AppRouter.kHomeView : AppRouter.kLoginView);
  }

  void _next() {
    final last = _pages.length - 1;
    if (_index < last) {
      _controller.animateToPage(
        _index + 1,
        duration: AppDurations.pageAnim,
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pageHeight = size.height * AppSizes.onboardingPageHeightFactor;

    return SafeArea(
      child: Column(
        children: [
          OnboardingSkip(visible: _index != _pages.length - 1, onSkip: _finish),

          SizedBox(
            height: pageHeight,
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => OnboardingPageWidget(page: _pages[i]),
            ),
          ),

          OnboardingIndicator(count: _pages.length, activeIndex: _index),
          const SizedBox(height: 12),

          Padding(
            padding: AppSpacing.hPadding,
            child: OnboardingPrimaryButton(
              isLast: _index == _pages.length - 1,
              onPressed: _next,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class OnboardingSkip extends StatelessWidget {
  const OnboardingSkip({
    super.key,
    required this.visible,
    required this.onSkip,
  });
  final bool visible;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      child: visible
          ? Align(
              key: const ValueKey('skip'),
              alignment: Alignment.topRight,
              child: Padding(
                padding: AppSpacing.skipPadding,
                child: TextButton(
                  onPressed: onSkip,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(
              key: ValueKey('no-skip'),
              height: AppSizes.keepSkipSpace,
            ),
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.isLast,
    required this.onPressed,
  });

  final bool isLast;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
        ),
        child: Text(
          isLast ? 'Get Started' : 'Next',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
