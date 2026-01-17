import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/utils/assets.dart';

class SlidingImg extends StatelessWidget {
  const SlidingImg({super.key, required this.slidingAnimation});
  final Animation<Offset> slidingAnimation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final w = (size.width * AppSizes.logoWFactor).clamp(0.0, AppSizes.logoMaxW);
    final h = (size.height * AppSizes.logoHFactor).clamp(
      0.0,
      AppSizes.logoMaxH,
    );

    return SlideTransition(
      position: slidingAnimation,
      child: SvgPicture.asset(
        AssetsData.logo,
        width: w,
        height: h,
        fit: BoxFit.contain,
        semanticsLabel: 'Logo',
      ),
    );
  }
}
