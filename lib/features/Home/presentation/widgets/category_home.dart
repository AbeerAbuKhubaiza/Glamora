import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/presentation/views/category_salons_view.dart';

class CategoryHome extends StatelessWidget {
  const CategoryHome({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('categories');

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kPrimaryColor,));
        }

        final raw = snapshot.data?.snapshot.value;
        if (raw == null || raw is! Map) {
          return const Center(child: Text('No categories available'));
        }

        final data = Map<String, dynamic>.from(raw);
        final categories = data.entries.map((entry) {
          final value = entry.value;
          if (value is Map) {
            final cat = Map<String, dynamic>.from(value);
            return {
              'id': (cat['id'] ?? entry.key).toString(),
              'name': (cat['name'] ?? '').toString(),
            };
          }
          return {'id': entry.key.toString(), 'name': entry.key.toString()};
        }).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, idx) {
                final cat = categories[idx];
                final id = cat['id']!;
                final name = cat['name']!;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategorySalonsView(
                          categoryId: id,
                          categoryTitle: name,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0E7EC),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Image.asset(
                            _getCategoryAsset(id),
                            // color: kPrimaryColor,
                            width: 32,
                            height: 32,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getCategoryAsset(String id) {
    switch (id) {
      case 'cat_makeup':
        return 'assets/images/makeup.png';
      case 'cat_skin':
        return 'assets/images/skincare.png';

      case 'cat_nails':
        return 'assets/images/nails.png';

      case 'cat_spa':
        return 'assets/images/spa.png';
      // return Icons.spa_outlined;
      case 'cat_hair':
      default:
        return 'assets/images/hair.png';
    }
  }
}
