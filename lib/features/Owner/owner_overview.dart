import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Bookings/data/bookings_repository.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/reviews_repository.dart';

class OwnerOverviewTab extends StatelessWidget {
  final Salon salon;
  final AppUser owner;

  const OwnerOverviewTab({super.key, required this.salon, required this.owner});

  @override
  Widget build(BuildContext context) {
    final bookingsRepo = const BookingsRepository();
    final reviewsRepo = const ReviewsRepository();

    return FutureBuilder(
      future: Future.wait([
        bookingsRepo.fetchSalonBookings(salon.id),
        reviewsRepo.fetchSalonReviews(salon.id),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        final bookings = snapshot.data![0] as List<Booking>;
        final reviews = snapshot.data![1] as List<Review>;

        final total = bookings.length;
        final pending = bookings.where((b) => b.status == 'pending').length;
        final accepted = bookings.where((b) => b.status == 'accepted').length;
        final completed = bookings.where((b) => b.status == 'completed').length;
        final cancelled = bookings.where((b) => b.status == 'cancelled').length;

        double avgRating = 0;
        if (reviews.isNotEmpty) {
          avgRating =
              reviews.fold<int>(0, (p, r) => p + r.rating) / reviews.length;
        }

        final latestReviews = reviews.take(3).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(avgRating, reviews.length),
              const SizedBox(height: 24),

              _section('Bookings overview'),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _statCard(
                    title: 'Total',
                    value: total,
                    icon: Icons.calendar_month,
                    color: kPrimaryColor,
                  ),
                  _statCard(
                    title: 'Completed',
                    value: completed,
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                  _statCard(
                    title: 'Pending',
                    value: pending,
                    icon: Icons.hourglass_top,
                    color: Colors.orange,
                  ),
                  _statCard(
                    title: 'Accepted',
                    value: accepted,
                    icon: Icons.done,
                    color: Colors.blue,
                  ),
                  _statCard(
                    title: 'Cancelled',
                    value: cancelled,
                    icon: Icons.cancel,
                    color: Colors.redAccent,
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _section('Bookings status'),
              const SizedBox(height: 12),
              _statusBar(
                pending: pending,
                accepted: accepted,
                completed: completed,
                cancelled: cancelled,
              ),

              const SizedBox(height: 28),
              _reviewsHeader(context),
              const SizedBox(height: 12),

              if (latestReviews.isEmpty)
                _emptyBox('No reviews yet')
              else
                Column(
                  children: latestReviews.map((r) => _reviewTile(r)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }


  Widget _hero(double rating, int reviewsCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.65)],
        ),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${owner.name} 👋',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  salon.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($reviewsCount reviews)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(Icons.store_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              SizedBox(width: 5),
              Text(
                title,

                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBar({
    required int pending,
    required int accepted,
    required int completed,
    required int cancelled,
  }) {
    final total = pending + accepted + completed + cancelled == 0
        ? 1
        : pending + accepted + completed + cancelled;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _bar(pending, total, Colors.orange),
              _bar(accepted, total, Colors.blue),
              _bar(completed, total, Colors.green),
              _bar(cancelled, total, Colors.redAccent),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: const [
              _Legend(color: Colors.orange, text: 'Pending'),
              _Legend(color: Colors.blue, text: 'Accepted'),
              _Legend(color: Colors.green, text: 'Completed'),
              _Legend(color: Colors.redAccent, text: 'Cancelled'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bar(int value, int total, Color color) {
    return Expanded(
      flex: value == 0 ? 1 : value,
      child: Container(
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _reviewsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _section('Latest reviews'),
        TextButton(
          onPressed: () {
            DefaultTabController.of(context).animateTo(3);
          },
          child: const Text('View all', style: TextStyle(color: kPrimaryColor)),
        ),
      ],
    );
  }

  Widget _reviewTile(Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Row(
        children: [
CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            child: ClipOval(
              child: Image.asset(
                "assets/images/user2.png",
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text("AbeerIsmail"),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < r.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.comment ?? 'Great experience!',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
