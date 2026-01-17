import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';

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

    isFavorite = widget.salon.isFavorite;

    if (user != null) {
      favRef = FirebaseDatabase.instance.ref(
        'users/${user!.uid}/favorites/${widget.salon.id}',
      );
    }
  }

  Future<void> toggleFavorite() async {
    if (user == null) {
      Fluttertoast.showToast(msg: 'Please login first');
      return;
    }

    setState(() => favAnimating = true);

    if (isFavorite) {
      await favRef.remove();
      setState(() => isFavorite = false);
    } else {
      await favRef.set(true);
      setState(() => isFavorite = true);
    }

    await Future.delayed(const Duration(milliseconds: 180));
    if (mounted) {
      setState(() => favAnimating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;

    if (user == null) {
      return _buildSalonCard(salon);
    }

    return StreamBuilder<DatabaseEvent>(
      stream: favRef.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          isFavorite = snapshot.data!.snapshot.value == true;
        }
        return _buildSalonCard(salon);
      },
    );
  }

  Widget _buildSalonCard(Salon salon) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        // margin: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEFEFEF)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
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
                  child: _buildImage(salon),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: toggleFavorite,
                    child: AnimatedScale(
                      scale: favAnimating ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: isFavorite ? Colors.red : kPrimaryColor,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: kPrimaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              salon.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${salon.reviewsCount} reviews)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    salon.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'in ${salon.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Salon salon) {
    final imageUrl = salon.images.isNotEmpty ? salon.images.first : null;

    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/salon_placeholder.png',
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      imageUrl,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/salon_placeholder.png',
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
