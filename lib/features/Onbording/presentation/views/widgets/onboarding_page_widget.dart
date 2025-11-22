// lib/features/onboarding/presentation/widgets/onboarding_page_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glamora_project/features/Onbording/presentation/models/onboarding_model.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingModel page;
  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;

    return Container(
      // color: Color(page.bgColorHex),
      padding: EdgeInsets.symmetric(horizontal: w * 0.06, vertical: h * 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // صورة تأخذ نسبة من الجهاز (responsive)
          SizedBox(
            height: h * 0.38,
            child: SvgPicture.asset(
              page.assetImage,
              width: w * 0.8,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: h * 0.04),
          Text(
            page.title,
            textAlign: TextAlign.center,
            // style: Theme.of(context).textTheme.headline6?.copyWith(
            //   fontSize: w * 0.06,
            //   fontWeight: FontWeight.bold,
            // ),
          ),
          SizedBox(height: h * 0.018),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            // style: Theme.of(
            //   context,
            // ).textTheme.bodyText2?.copyWith(fontSize: w * 0.042),
          ),
        ],
      ),
    );
  }
}
