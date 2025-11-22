import 'package:flutter/material.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_detail_view.dart';
import 'package:glamora_project/models.dart';
import 'package:glamora_project/salons_repository.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_card.dart';

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
    _future = SalonsRepository().fetchSalons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Salons'),
        backgroundColor: Colors.white,
        foregroundColor: kPrimaryColor,
        elevation: 1,
      ),
      body: FutureBuilder<List<Salon>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final salons = snap.data ?? [];
          if (salons.isEmpty) {
            return const Center(child: Text('No salons available'));
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              itemCount: salons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final s = salons[index];
                return SalonCard(
                  salon: s, // تمرير الـ Salon كامل
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
