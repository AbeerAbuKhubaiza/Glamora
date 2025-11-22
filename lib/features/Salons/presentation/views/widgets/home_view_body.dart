import 'package:flutter/material.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/banner_home.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/category_home.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/home_appbar.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/new_salons.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/section_header.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/top_rated_salons.dart';
import 'package:glamora_project/features/Search/presentaion/views/widgets/home_search_widget.dart';
import 'package:glamora_project/models.dart';
import 'package:glamora_project/salons_repository.dart';

class HomeViewBody extends StatefulWidget {
  const HomeViewBody({super.key});

  @override
  State<HomeViewBody> createState() => _HomeViewBodyState();
}

class _HomeViewBodyState extends State<HomeViewBody> {
  late Future<List<Salon>> _future;

  @override
  void initState() {
    super.initState();
    _future = SalonsRepository().fetchSalons();
  }

  Future<void> _refreshSalons() async {
    setState(() => _future = SalonsRepository().fetchSalons());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshSalons,
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeAppBar(),
              const HomeSearch(),
              const SizedBox(height: 12),
              const BannerHome(),
              const SizedBox(height: 16),

              const SectionHeader(
                title: "Categories",
                showViewAll: true,
                onViewAll: null,
              ),
              const CategoryHome(),
              const SizedBox(height: 12),

              TopRatedSalons(future: _future),
              const SizedBox(height: 20),
              NewSalons(future: _future),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
