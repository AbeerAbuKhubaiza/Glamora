import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_card.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_detail_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/section_header.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';

class NewSalons extends StatefulWidget {
  final Future<List<Salon>> future;

  const NewSalons({super.key, required this.future});

  @override
  State<NewSalons> createState() => _NewSalonsState();
}

class _NewSalonsState extends State<NewSalons> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "New Salons"),
        const SizedBox(height: 8),

        FutureBuilder<List<Salon>>(
          future: widget.future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 265,
                child: Center(
                  child: CircularProgressIndicator(color: kPrimaryColor),
                ),
              );
            }

            final salons = snapshot.data ?? [];
            if (salons.isEmpty) {
              return const SizedBox.shrink();
            }

            salons.sort((a, b) {
              if (a.createdAt != null && b.createdAt != null) {
                return b.createdAt!.compareTo(a.createdAt!);
              } else if (a.createdAt != null) {
                return -1;
              } else if (b.createdAt != null) {
                return 1;
              }
              return 0;
            });

            return SizedBox(
              height: 265,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,

                clipBehavior: Clip.none,
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 14),

                itemCount: salons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final salon = salons[i];

                  return SizedBox(
                    width: 200,
                    child: SalonCard(
                      salon: salon,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SalonDetailView(salon: salon),
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
