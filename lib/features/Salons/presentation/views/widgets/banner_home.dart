import 'package:flutter/material.dart';

class BannerHome extends StatelessWidget {
  const BannerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: w * 0.42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.pink[50],
          image: const DecorationImage(
            image: AssetImage('assets/images/banner_placeholder.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
