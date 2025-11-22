import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glamora_project/core/utils/assets.dart';

class SlidingImg extends StatelessWidget {
  const SlidingImg({super.key, required this.slidingAnimation});

  final Animation<Offset> slidingAnimation;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final logoWidth = screenWidth * 0.45;
    final logoHeight = screenHeight * 0.15;
    final maxWidth = 300.0;
    final maxHeight = 250.0;
    final width = logoWidth.clamp(0.0, maxWidth);
    final height = logoHeight.clamp(0.0, maxHeight);

    return Align(
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: slidingAnimation,
        builder: (context, _) {
          return SlideTransition(
            position: slidingAnimation,
            child: SvgPicture.asset(
              AssetsData.logo,
              width: width,
              height: height,
              fit: BoxFit.contain,
              semanticsLabel: 'Logo',
            ),
          );
        },
      ),
    );
  }
}
