import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Onbording/data/models/onboarding_model.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingModel page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: h * 0.02),
          SizedBox(
            height: h * 0.36,
            child: SvgPicture.asset(page.assetImage, fit: BoxFit.contain),
          ),

          SizedBox(height: h * 0.025),

          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: w * 0.06,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: h * 0.014),

          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: w * 0.042,
              height: 1.35,
              color: AppColors.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
