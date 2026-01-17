import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';

class OnboardingIndicator extends StatelessWidget {
  final int count;
  final int activeIndex;

  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: AppDurations.mid,
          margin: AppSizes.dotMargin,
          width: isActive ? AppSizes.dotWActive : AppSizes.dotWInactive,
          height: AppSizes.dotH,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.dotInactive,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}
