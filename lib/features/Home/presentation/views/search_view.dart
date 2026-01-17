import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_detail_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/home_search_widget.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/salons_repository.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_card.dart';

class SearchView extends StatefulWidget {
  final String initialQuery;
  final String? categoryId;

  const SearchView({super.key, this.initialQuery = '', this.categoryId});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late TextEditingController _ctrl;
  late Future<List<Salon>> _future;
  List<Salon> _allSalons = [];

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
    _future = SalonsRepository().fetchSalons();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final list = await SalonsRepository().fetchSalons();
    setState(() {
      _allSalons = list;
    });
  }

  List<Salon> _filter(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty && widget.categoryId == null) return _allSalons;
    var filtered = _allSalons.where((s) {
      final name = s.name.toLowerCase();
      final matchesName = name.contains(query);
      final matchesCategory = widget.categoryId == null
          ? true
          : (s.extra?['categoryId']?.toString() == widget.categoryId);
      return matchesName && matchesCategory;
    }).toList();
    return filtered;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: SafeArea(
          child: Row(
            children: [
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: GlamoraSearchField(
                  controller: _ctrl,
                  autofocus: true,
                  readOnly: false,
                  padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
      ),

      body: FutureBuilder<List<Salon>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor,));
          }
          final results = _filter(_ctrl.text);

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _ctrl.text.isEmpty
                        ? 'No results yet'
                        : 'No salons match "${_ctrl.text}"',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GridView.builder(
              itemCount: results.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final s = results[index];
                return SalonCard(
                  salon: s, 
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalonDetailView(salon: s),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
