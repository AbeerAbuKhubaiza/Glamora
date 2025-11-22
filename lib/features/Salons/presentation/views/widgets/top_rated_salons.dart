import 'package:flutter/material.dart';
import 'package:glamora_project/features/Salons/presentation/views/all_salons_view.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_card.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_detail_view.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/section_header.dart';
import 'package:glamora_project/models.dart';

class TopRatedSalons extends StatefulWidget {
  final Future<List<Salon>> future;

  const TopRatedSalons({super.key, required this.future});

  @override
  State<TopRatedSalons> createState() => _TopRatedSalonsState();
}

class _TopRatedSalonsState extends State<TopRatedSalons> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Top Rated Salons",
          showViewAll: true,
          onViewAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllSalonsView()),
            );
          },
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 260,
          child: FutureBuilder<List<Salon>>(
            future: widget.future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final salons = snapshot.data ?? [];
              if (salons.isEmpty) {
                return const Center(child: Text('No salons found'));
              }

              salons.sort((a, b) => b.rating.compareTo(a.rating));
              final items = salons.length >= 3 ? salons.sublist(0, 3) : salons;

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final s = items[index];
                  return SalonCard(
                    salon: s, // تمرير الـ Salon كامل
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
              );
            },
          ),
        ),
      ],
    );
  }
}
