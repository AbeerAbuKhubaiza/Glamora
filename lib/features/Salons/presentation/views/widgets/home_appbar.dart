import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glamora_project/core/utils/assets.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            AssetsData.logo1,
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
          Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Colors.black54),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
