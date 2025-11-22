import 'package:flutter/material.dart';
import 'package:glamora_project/constants.dart';

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
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 22 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: isActive ? kPrimaryColor : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }
}
