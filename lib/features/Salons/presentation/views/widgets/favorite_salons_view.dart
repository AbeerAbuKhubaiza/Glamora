import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_detail_view.dart';
import 'package:glamora_project/models.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_card.dart';

class FavoriteSalonsPage extends StatefulWidget {
  const FavoriteSalonsPage({super.key});

  @override
  State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
}

class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference favRef;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      favRef = FirebaseDatabase.instance.ref('users/${user!.uid}/favorites');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Favorites")),
        body: const Center(child: Text("Please log in to see favorites.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Favorites")),
      body: StreamBuilder<DatabaseEvent>(
        stream: favRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final snapshotValue = snapshot.data!.snapshot.value;
          if (snapshotValue == null) {
            return const Center(child: Text("No favorite salons yet."));
          }

          final raw = snapshotValue as Map;
          final data = raw.map(
            (key, value) =>
                MapEntry(key.toString(), Map<String, dynamic>.from(value)),
          );

          // تحويل كل عنصر Map إلى كائن Salon
          final favoriteSalons = data.values.map((e) {
            final map = Map<String, dynamic>.from(e);

            // تحويل rating بأمان لأي نوع
            double ratingValue = 0.0;
            if (map['rating'] != null) {
              if (map['rating'] is double) {
                ratingValue = map['rating'];
              } else {
                ratingValue = double.tryParse(map['rating'].toString()) ?? 0.0;
              }
            }

            return Salon(
              id: map['id'] ?? '',
              name: map['name'] ?? '',
              city: map['city'] ?? '',
              rating: ratingValue,
              images: map['imageUrl'] != null ? [map['imageUrl']] : [],
              extra: {'isFavorite': true}, // القلب يظهر أحمر مباشرة
              isApproved: map['isApproved'] ?? false,
              reviewsCount: map['reviewsCount'] ?? 0,
            );
          }).toList();

          if (favoriteSalons.isEmpty) {
            return const Center(child: Text("No favorite salons yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: favoriteSalons.length,
            itemBuilder: (context, index) {
              final salon = favoriteSalons[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SalonCard(
                  salon: salon,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalonDetailView(salon: salon),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
