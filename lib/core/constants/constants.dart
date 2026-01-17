import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xff6D123F);


class AppKeys {
  static const seenOnboarding = 'seenOnboarding';
}

class AppDurations {
  static const fast = Duration(milliseconds: 200);
  static const mid = Duration(milliseconds: 250);
  static const pageAnim = Duration(milliseconds: 350);
    static const splashDelay = Duration(seconds: 3);
  static const splashAnim = Duration(milliseconds: 900);

}

class AppSpacing {
  static const hPadding = EdgeInsets.symmetric(horizontal: 16);
  static const skipPadding = EdgeInsets.only(right: 10, top: 6);
}

class AppSizes {
  static const onboardingPageHeightFactor = 0.68;
  static const buttonHeight = 56.0;
  static const buttonRadius = 12.0;

  static const dotH = 8.0;
  static const dotWActive = 22.0;
  static const dotWInactive = 8.0;
  static const dotMargin = EdgeInsets.symmetric(horizontal: 5);
  static const keepSkipSpace = 48.0;




    static const splashCornerFactor = 0.12;
  static const logoWFactor = 0.45;
  static const logoHFactor = 0.15;
  static const logoMaxW = 300.0;
  static const logoMaxH = 250.0;

}

class AppColors {
  static const scaffoldBg = Colors.white;
  static Color subtitle = Colors.grey.shade700;
  static Color dotInactive = Colors.grey.shade300;
  static Color primary = Color(0xff6D123F);
}
