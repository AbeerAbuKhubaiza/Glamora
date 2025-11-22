import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/features/Salons/presentation/views/category_salons_view.dart';

class CategoryHome extends StatelessWidget {
  const CategoryHome({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref('categories');

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No categories available'));
        }

        final data = Map<String, dynamic>.from(
          snapshot.data!.snapshot.value as Map,
        );
        final categories = data.entries.map((entry) {
          final cat = Map<String, dynamic>.from(entry.value);
          return {'id': cat['id'] ?? entry.key, 'name': cat['name'] ?? ''};
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
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategorySalonsView(
                          categoryId: cat['id']!,
                          categoryTitle: cat['name']!,
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
                            color: const Color(0xFFFFE7EC),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            _getIconForCategory(cat['id']!),
                            color: kPrimaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['name']!,
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

  IconData _getIconForCategory(String id) {
    switch (id) {
      case 'cat_makeup':
        return Icons.brush;
      case 'cat_skin':
        return Icons.spa;
      case 'cat_nails':
        return Icons.content_cut;
      case 'cat_perfume':
        return Icons.local_drink;
      case 'cat_hair':
      default:
        return Icons.content_cut_outlined;
    }
  }
}
