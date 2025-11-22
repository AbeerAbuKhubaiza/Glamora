import 'package:flutter/material.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/models.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_card.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_detail_view.dart';

class SimilarSalonsSection extends StatefulWidget {
  final Future<List<Salon>>? similarFuture;
  const SimilarSalonsSection({super.key, this.similarFuture});

  @override
  State<SimilarSalonsSection> createState() => _SimilarSalonsSectionState();
}

class _SimilarSalonsSectionState extends State<SimilarSalonsSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.similarFuture == null) return const SizedBox();
    return FutureBuilder<List<Salon>>(
      future: widget.similarFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }

        if (snap.hasError) return const Text('Failed to load similar salons.');
        final list = snap.data ?? [];
        if (list.isEmpty) return const Text('No similar salons found.');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Similar salons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final s = list[index];
                  return SizedBox(
                    width: 200,
                    child: SalonCard(
                      salon: s,
onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SalonDetailView(salon: s),
                          ),
                        );

                        // لما أرجع من صفحة الديتيل → اعمل refresh للصفحة
                        setState(() {});
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
