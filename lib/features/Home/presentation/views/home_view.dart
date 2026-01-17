import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Bookings/presentation/views/user_bookings_page.dart';
import 'package:glamora_project/features/Home/presentation/views/profile_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/favorite_salons_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/home_view_body.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeViewBody(),
    MyOrdersPage(),
    FavoriteSalonsPage(),
    UserProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,

      extendBody: true,

      body: SafeArea(
        top: true,
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _pages[_currentIndex],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          10 + (bottomInset * 0.25),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // boxShadow: [
            //   BoxShadow(
            //     blurRadius: 25,
            //     spreadRadius: 0,
            //     offset: const Offset(0, 8),
            //     color: Colors.black.withOpacity(0.10),
            //   ),
            // ],
            boxShadow: [
              BoxShadow(
                blurRadius: 30,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.12),
              ),
              BoxShadow(
                blurRadius: 6,
                offset: const Offset(0, -1),
                color: Colors.black.withOpacity(0.03),
              ),
            ],

          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: GNav(
            selectedIndex: _currentIndex,
            onTabChange: (index) {
              setState(() => _currentIndex = index);
            },

            backgroundColor: Colors.white,
            color: kPrimaryColor, 
            activeColor: Colors.white, 
            tabBackgroundColor: kPrimaryColor,

            gap: 8,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            tabBorderRadius: 14,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            rippleColor: kPrimaryColor.withOpacity(0.15),

            tabs: const [
              GButton(icon: Icons.home_filled, text: 'Home'),
              GButton(icon: Icons.calendar_month, text: 'Order'),
              GButton(icon: Icons.favorite_border, text: 'Wishlist'),
              GButton(icon: Icons.person_outline, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
