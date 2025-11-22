import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/models.dart';

class SalonCard extends StatefulWidget {
  final Salon salon;
  final VoidCallback? onTap;

  const SalonCard({super.key, required this.salon, this.onTap});

  @override
  State<SalonCard> createState() => _SalonCardState();
}

class _SalonCardState extends State<SalonCard> {
  bool isFavorite = false;
  bool favAnimating = false;
  late DatabaseReference favRef;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.salon.extra?['isFavorite'] == true;
    if (user != null) {
      favRef = FirebaseDatabase.instance.ref(
        'users/${user!.uid}/favorites/${widget.salon.id}',
      );
    }
  }

  Future<void> toggleFavorite() async {
    if (user == null) return;
    setState(() => favAnimating = true);

    if (isFavorite) {
      await favRef.remove();
      setState(() => isFavorite = false);
    } else {
      await favRef.set({
        'id': widget.salon.id,
        'name': widget.salon.name,
        'city': widget.salon.city,
        'rating': widget.salon.rating,
        'imageUrl': widget.salon.images.isNotEmpty
            ? widget.salon.images[0]
            : '',
        'isApproved': widget.salon.isApproved,
        'reviewsCount': widget.salon.reviewsCount,
      });
      setState(() => isFavorite = true);
    }

    await Future.delayed(const Duration(milliseconds: 180));
    setState(() => favAnimating = false);
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = 200.0;
    final salon = widget.salon;

    // إذا المستخدم مش مسجّل، فقط اعرض الكارد بدون متابعة الحالة
    if (user == null) {
      return _buildSalonCard(cardWidth, salon);
    }

    // StreamBuilder يتابع حالة المفضلة من Realtime Database بشكل مباشر
    return StreamBuilder<DatabaseEvent>(
      stream: favRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          isFavorite = true;
        } else {
          isFavorite = false;
        }
        return _buildSalonCard(cardWidth, salon);
      },
    );
  }

  Widget _buildSalonCard(double cardWidth, Salon salon) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEFEFEF)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: salon.images.isNotEmpty
                      ? Image.network(
                          salon.images[0],
                          width: cardWidth,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/salon_placeholder.png',
                            width: cardWidth,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/salon_placeholder.png',
                          width: cardWidth,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                ),

                // ❤️ أيقونة القلب
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: toggleFavorite,
                    child: AnimatedScale(
                      scale: favAnimating ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // تفاصيل الصالون
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salon.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          salon.city,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: kPrimaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            salon.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
