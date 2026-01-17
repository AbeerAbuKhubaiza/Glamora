import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Owner/add_service_dialog.dart';
import 'package:glamora_project/features/Owner/owner_bookings_view.dart';
import 'package:glamora_project/features/Owner/owner_overview.dart';
import 'package:glamora_project/features/Owner/owner_profile_view.dart';
import 'package:glamora_project/features/Owner/owner_reviews_view.dart';
import 'package:glamora_project/features/Owner/owner_services_view.dart';
import 'package:glamora_project/features/Owner/showsalonpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class OwnerSalonDashboard extends StatefulWidget {
  final AppUser owner;
  final Salon salon;
  final List<Salon> salons;

  const OwnerSalonDashboard({
    super.key,
    required this.owner,
    required this.salon,
    required this.salons,
  });

  @override
  State<OwnerSalonDashboard> createState() => _OwnerSalonDashboardState();
}

class _OwnerSalonDashboardState extends State<OwnerSalonDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final pages = [
      OwnerOverviewTab(salon: widget.salon, owner: widget.owner),
      OwnerBookingsTab(salon: widget.salon),
      OwnerServicesTab(salon: widget.salon),
      OwnerReviewsTab(salonId: widget.salon.id),
      OwnerProfileTab(salon: widget.salon, owner: widget.owner),
    ];

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.6,
        title: Text(
          'Glamora',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: kPrimaryColor,
            letterSpacing: 2.2,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () async {
              final selected = await showSalonPickerSheet(
                context: context,
                salons: widget.salons,
              );

              if (selected != null && selected.id != widget.salon.id) {
                context.goNamed(
                  AppRouter.kOwnerSalonDashboard,
                  extra: {
                    'owner': widget.owner,
                    'salon': selected,
                    'salons': widget.salons,
                  },
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Add Service',
            icon: const Icon(Icons.add_circle_outline, color: kPrimaryColor),
            onPressed: () {
              showAddServiceDialog(
                context: context,
                salon: widget.salon,
                servicesRef: FirebaseDatabase.instance.ref('services'),
                salonServicesRef: FirebaseDatabase.instance.ref(
                  'salon_services',
                ),
                onSuccess: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service added successfully')),
                  );
                },
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: pages[_currentIndex],

      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 10 + (bottomInset * 0.25)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
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
              GButton(icon: Icons.dashboard_rounded, text: 'Overview'),
              GButton(icon: Icons.calendar_month_rounded, text: 'Bookings'),
              GButton(icon: Icons.content_cut_rounded, text: 'Services'),
              GButton(icon: Icons.star_rate_rounded, text: 'Reviews'),
              GButton(icon: Icons.person_rounded, text: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}
