import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/presentation/views/reviews.dart';
import 'package:glamora_project/features/Home/presentation/widgets/booking_page.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';

class SalonInfoSection extends StatelessWidget {
  final Salon salon;
  final void Function(String) onCall;
  final VoidCallback onAddToCart;

  final bool isFavorite;
  final bool favAnimating;
  final Future<void> Function() onToggleFavorite;
  final List<Service> services;
  final bool loadingServices;

  final List<Review> reviews;
  final bool loadingReviews;

  SalonInfoSection({
    super.key,
    required this.salon,
    required this.onCall,
    required this.onAddToCart,
    required this.isFavorite,
    required this.favAnimating,
    required this.onToggleFavorite,
    required this.services,
    required this.loadingServices,
    required this.reviews,
    required this.loadingReviews,
  });

  Map<String, String> _extractWorkingHours(Map<String, dynamic>? extra) {
    if (extra == null) return {};
    final wh =
        extra['working_hours'] ?? extra['workingHours'] ?? extra['hours'];
    if (wh is Map) {
      final res = <String, String>{};
      wh.forEach((k, v) => res[k.toString()] = v?.toString() ?? '');
      return res;
    }
    return {};
  }

  final List<Map<String, String>> dummyUsers = [
    {'name': 'Shahd Ibrahim', 'image': 'assets/images/user1.png'},
    {'name': 'Abeer Ismail', 'image': 'assets/images/user2.png'},
    {'name': 'Noor Ahmad', 'image': 'assets/images/user3.png'},
    {'name': 'Lana Ahmad', 'image': 'assets/images/user2.png'},
    {'name': 'Soha Ayman', 'image': 'assets/images/user1.png'},
    {'name': 'Lina Ahmad', 'image': 'assets/images/user3.png'},
    {'name': 'Rorro ', 'image': 'assets/images/user2.png'},

    {'name': 'Rana Khaled', 'image': 'assets/images/user3.png'},
  ];

  @override
  Widget build(BuildContext context) {
    final map = salon.extra ?? {};
    final ownerName = map['ownerName']?.toString() ?? map['owner']?.toString();
    final city = salon.city;
    final description = map['description']?.toString() ?? '';
    final phone =
        map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '';
    final rating = salon.rating;
    final reviewsCount = salon.reviewsCount;

    final workingHours = _extractWorkingHours(map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                salon.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggleFavorite,
              child: AnimatedScale(
                scale: favAnimating ? 1.25 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.grey,
                  size: 26,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        if (ownerName != null)
          Text('Owner: $ownerName', style: const TextStyle(color: Colors.grey)),

        const SizedBox(height: 6),

        Row(
          children: [
            Text(city, style: const TextStyle(color: Colors.grey)),
            const Spacer(),
            const Icon(Icons.star, color: kPrimaryColor),
            const SizedBox(width: 6),
            Text(rating.toStringAsFixed(1)),
            const SizedBox(width: 8),
            Text('($reviewsCount)', style: const TextStyle(color: Colors.grey)),
          ],
        ),

        const SizedBox(height: 12),

        if (description.isNotEmpty)
          Text(description, style: const TextStyle(fontSize: 14, height: 1.5)),

        if (workingHours.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Working Hours',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: workingHours.entries
                .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                .toList(),
          ),
        ],

        const SizedBox(height: 18),

        Row(
          children: [
            const Text(
              "Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (!loadingServices && services.length > 4)
              Text(
                "${services.length} items",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 10),

        loadingServices
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : services.isEmpty
            ? const Text("No services found for this salon.")
            : SizedBox(
                height: 74,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: services.length > 8 ? 8 : services.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = services[i];
                    final duration = s.extra?['duration'];

                    return Container(
                      width: 165,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF2F2F2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.8,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  duration != null
                                      ? "$duration min"
                                      : "Standard",
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: kPrimaryColor,
                                  ),
                                ),
                              ),

                              Text(
                                "\$${s.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalonReviewsScreen(reviews: reviews),
                  ),
                );
              },
              child: const Text(
                'View all',
                style: TextStyle(color: kPrimaryColor),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (loadingReviews)
          const Center(child: CircularProgressIndicator(color: kPrimaryColor))
        else if (reviews.isEmpty)
          const Text("No reviews yet for this salon.")
        else
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: reviews.length > 6 ? 6 : reviews.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final r = reviews[i];
                final user = dummyUsers[i % dummyUsers.length];
                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF2F2F2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(user['image']!),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      user['name']!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),

                                    Text(
                                      '20/Aug/2025',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < r.rating
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 16,
                                      color: Colors.amber.shade600,
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        r.comment ?? 'Great experience!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookingPage(salon: salon)),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            _SquareIconButton(
              icon: Icons.phone,
              onPressed: phone.isNotEmpty ? () => onCall(phone) : null,
            ),

            const SizedBox(width: 8),

            _SquareIconButton(
              icon: Icons.add_shopping_cart,
              onPressed: onAddToCart,
            ),
          ],
        ),
      ],
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _SquareIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: kPrimaryColor),
      ),
    );
  }
}
