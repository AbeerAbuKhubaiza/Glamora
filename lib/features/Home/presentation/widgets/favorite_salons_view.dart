import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:glamora_project/core/constants/constants.dart';

import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_detail_view.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_card.dart';
import 'package:glamora_project/features/Home/data/repo/salons_repository.dart';

class FavoriteSalonsPage extends StatefulWidget {
  const FavoriteSalonsPage({super.key});

  @override
  State<FavoriteSalonsPage> createState() => _FavoriteSalonsPageState();
}

class _FavoriteSalonsPageState extends State<FavoriteSalonsPage> {
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference favRef;

  final SalonsRepository _salonsRepo = const SalonsRepository();

  @override
  void initState() {
    super.initState();
    if (user != null) {
      favRef = FirebaseDatabase.instance.ref('users/${user!.uid}/favorites');
    }
  }

  Future<List<Salon>> _fetchFavoriteSalons(List<String> ids) async {
    if (ids.isEmpty) return [];

    final List<Salon> result = [];
    for (final id in ids) {
      final salon = await _salonsRepo.fetchSalonById(id);
      if (salon != null && salon.isApproved) {
        result.add(salon.copyWith(isFavorite: true));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Text(
              "Please log in to see favorites.",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  "My Wishlist",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
                // SizedBox(height: 1),
                Text(
                  "Your favorite salons in one place",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: favRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kPrimaryColor,));
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return _buildEmptyState();
                  }

                  final snapshotValue = snapshot.data!.snapshot.value;

                  if (snapshotValue is! Map) {
                    return _buildEmptyState();
                  }

                  final favMap = Map<String, dynamic>.from(snapshotValue);

                  final favoriteIds = favMap.entries
                      .where((e) => e.value == true)
                      .map((e) => e.key.toString())
                      .toList();

                  if (favoriteIds.isEmpty) {
                    return _buildEmptyState();
                  }

                  return FutureBuilder<List<Salon>>(
                    future: _fetchFavoriteSalons(favoriteIds),
                    builder: (context, favSnapshot) {
                      if (favSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryColor,));
                      }

                      final salons = favSnapshot.data ?? [];

                      if (salons.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: salons.length,
                        itemBuilder: (context, index) {
                          final salon = salons[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SalonCard(
                              salon: salon,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SalonDetailView(salon: salon),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.favorite_border, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              "No favorite salons yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "Tap the heart icon on a salon to add it to your wishlist.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
