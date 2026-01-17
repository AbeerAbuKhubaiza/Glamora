import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_detail_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_card.dart';
import 'package:glamora_project/features/Home/presentation/views/search_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/home_search_widget.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/salons_repository.dart';

class AllSalonsView extends StatefulWidget {
  const AllSalonsView({super.key});

  @override
  State<AllSalonsView> createState() => _AllSalonsViewState();
}

class _AllSalonsViewState extends State<AllSalonsView> {
  late Future<List<Salon>> _future;

  @override
  void initState() {
    super.initState();
    _future = const SalonsRepository().fetchSalons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 15),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 6),
                   Expanded(child:               GlamoraSearchField(
                      readOnly: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SearchView(initialQuery: ''),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<List<Salon>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor,));
                  }

                  final salons = snap.data ?? const [];
                  if (salons.isEmpty) {
                    return const Center(child: Text('No salons available'));
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: GridView.builder(
                      itemCount: salons.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                      itemBuilder: (context, index) {
                        final s = salons[index];
                        return SalonCard(
                          salon: s,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SalonDetailView(salon: s),
                              ),
                            );
                            setState(() {});
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
