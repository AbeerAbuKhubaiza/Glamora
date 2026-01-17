import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Glamora',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
              letterSpacing: 2.2,
            ),
          ),

          // SvgPicture.asset(
          //   AssetsData.logo1,
          //   width: 50,
          //   height: 50,
          //   fit: BoxFit.contain,
          // ),
          const Spacer(),
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
