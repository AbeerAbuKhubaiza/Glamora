import 'package:flutter/material.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/features/Bookings/user_bookings_page.dart';
import 'package:glamora_project/features/Profile/profile_view.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/favorite_salons_view.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/home_view_body.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  // هنا ضع الـ userId الحقيقي للمستخدم المسجل
  final String userId = 'USER_ID';

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeViewBody(),
      MyOrdersPage(),
      FavoriteSalonsPage(),
      UserProfileView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
