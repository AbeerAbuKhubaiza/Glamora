import 'package:flutter/material.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_detail_view.dart';
import 'package:glamora_project/models.dart';
import 'package:glamora_project/salons_repository.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_card.dart';

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
    _future = SalonsRepository().fetchSalons(); // يجلب المعتمدين افتراضياً
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
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search salons...',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => setState(() {}),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: FutureBuilder<List<Salon>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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
                  salon: s, // تمرير الـ Salon كامل
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
