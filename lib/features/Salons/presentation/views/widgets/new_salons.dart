import 'package:flutter/material.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_detail_view.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/section_header.dart';
import 'package:glamora_project/models.dart';

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
              return const SizedBox.shrink();
            }

            final salons = snapshot.data ?? [];
            if (salons.isEmpty) return const SizedBox.shrink();

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

            return Column(
              children: salons.map((s) {
                final imageUrl = s.images.isNotEmpty ? s.images[0] : null;
                return ListTile(
                  leading: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/salon_placeholder.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                  title: Text(s.name),
                  subtitle: Text('${s.city} • ${s.rating}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalonDetailView(salon: s),
                      ),
                    );
                    setState(() {});
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
