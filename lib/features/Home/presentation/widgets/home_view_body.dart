import 'package:flutter/material.dart';
import 'package:glamora_project/features/Home/presentation/widgets/banner_home.dart';
import 'package:glamora_project/features/Home/presentation/widgets/category_home.dart';
import 'package:glamora_project/features/Home/presentation/widgets/home_appbar.dart';
import 'package:glamora_project/features/Home/presentation/widgets/new_salons.dart';
import 'package:glamora_project/features/Home/presentation/widgets/section_header.dart';
import 'package:glamora_project/features/Home/presentation/widgets/single_banner_home.dart';
import 'package:glamora_project/features/Home/presentation/widgets/top_rated_salons.dart';
import 'package:glamora_project/features/Home/presentation/views/search_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/home_search_widget.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/salons_repository.dart';

class HomeViewBody extends StatefulWidget {
  final AppUser? currentUser;

  const HomeViewBody({super.key, this.currentUser});

  @override
  State<HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<HomeViewBody> {
  late Future<List<Salon>> _future;

  @override
  void initState() {
    super.initState();
    _loadSalons();
  }

  void _loadSalons() {
    _future = const SalonsRepository().fetchSalons(
      currentUser: null,
      onlyApproved: true,
    );
  }

  Future<void> _refreshSalons() async {
    setState(_loadSalons);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const floatingNavSpace = 20.0;
    return RefreshIndicator(
      onRefresh: _refreshSalons,
      child: Container(
        color: Colors.white,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 12, 0, floatingNavSpace + bottomSafe),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeAppBar(),
              GlamoraSearchField(
      readOnly: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SearchView(initialQuery: ''),
          ),);}),
        
              SizedBox(height: 12),
              BannerHome(),
              SizedBox(height: 16),

              SectionHeader(
                title: "Categories",
                showViewAll: true,
                onViewAll: null,
              ),
              CategoryHome(),
              SizedBox(height: 12),

              TopRatedSalonsWrapper(),
              SizedBox(height: 7),
              const SingleBannerHome(
                imageAsset: 'assets/images/special_offer_banner.jpeg',
                bottomLeftAsset: 'assets/images/special_offer_banner1.jpeg',
                bottomRightAsset: 'assets/images/special_offer_banner2.jpeg',
              ),

              SizedBox(height: 30),

              NewSalonsWrapper(),
              SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class TopRatedSalonsWrapper extends StatelessWidget {
  const TopRatedSalonsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeViewBodyState>();
    final future = state?._future ?? const SalonsRepository().fetchSalons();
    return TopRatedSalons(future: future);
  }
}

class NewSalonsWrapper extends StatelessWidget {
  const NewSalonsWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeViewBodyState>();
    final future = state?._future ?? const SalonsRepository().fetchSalons();
    return NewSalons(future: future);
  }
}
