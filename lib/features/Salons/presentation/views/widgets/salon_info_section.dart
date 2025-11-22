import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/booking_page.dart';
import 'package:glamora_project/models.dart';

class SalonInfoSection extends StatefulWidget {
  final Salon salon;
  final void Function(String) onCall;
  final VoidCallback onAddToCart;

  const SalonInfoSection({
    super.key,
    required this.salon,
    required this.onCall,
    required this.onAddToCart, required bool isFavorite, required bool favAnimating, required Future<void> Function() onToggleFavorite,
  });

  @override
  State<SalonInfoSection> createState() => _SalonInfoSectionState();
}

class _SalonInfoSectionState extends State<SalonInfoSection> {
  bool isFavorite = false;
  bool favAnimating = false;
  final user = FirebaseAuth.instance.currentUser;
  late DatabaseReference favRef;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      favRef = FirebaseDatabase.instance.ref(
        'users/${user!.uid}/favorites/${widget.salon.id}',
      );
      // التحقق من وجود الصالون في المفضلة عند البداية
      favRef.once().then((snapshot) {
        if (snapshot.snapshot.exists) {
          setState(() {
            isFavorite = true;
          });
        }
      });
    }
  }

  Future<void> toggleFavorite() async {
    if (user == null) return;

    setState(() {
      favAnimating = true;
    });

    if (isFavorite) {
      await favRef.remove();
      setState(() {
        isFavorite = false;
      });
    } else {
      await favRef.set({
        'id': widget.salon.id,
        'name': widget.salon.name,
        'city': widget.salon.city,
        'rating': widget.salon.rating,
        'imageUrl': widget.salon.images[0],
      });
      setState(() {
        isFavorite = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 180));
    setState(() {
      favAnimating = false;
    });
  }

  Map<String, String> _extractWorkingHours(Map<String, dynamic>? extra) {
    if (extra == null) return {};
    final wh =
        extra['working_hours'] ?? extra['workingHours'] ?? extra['hours'];
    if (wh is Map) {
      final res = <String, String>{};
      wh.forEach((k, v) {
        res[k.toString()] = v?.toString() ?? '';
      });
      return res;
    }
    return {};
  }

  List<Map<String, dynamic>> _normalizeServices(dynamic servicesRaw) {
    final List<Map<String, dynamic>> services = [];
    if (servicesRaw == null) return services;
    if (servicesRaw is List) {
      for (final s in servicesRaw) {
        if (s is Map) services.add(Map<String, dynamic>.from(s));
      }
    } else if (servicesRaw is Map) {
      servicesRaw.forEach((k, v) {
        if (v is Map) services.add(Map<String, dynamic>.from(v));
      });
    }
    return services;
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.salon.extra ?? {};
    final ownerName = map['ownerName']?.toString() ?? map['owner']?.toString();
    final city = widget.salon.city;
    final description = map['description']?.toString() ?? '';
    final phone =
        map['phone']?.toString() ?? map['phoneNumber']?.toString() ?? '';
    final rating = widget.salon.rating;
    final reviewsCount = widget.salon.reviewsCount;
    final services = _normalizeServices(map['services']);
    final workingHours = _extractWorkingHours(map);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.salon.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: toggleFavorite,
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
        if (services.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Services',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: services.map((svc) {
              final title = svc['title'] ?? svc['name'] ?? 'Service';
              final price = svc['price'] ?? svc['amount'] ?? '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_box_outline_blank,
                  color: Colors.grey,
                ),
                title: Text(title.toString()),
                trailing: Text(price != '' ? '\$${price.toString()}' : ''),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingPage(salon: widget.salon),
                  ),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () => phone.isNotEmpty ? widget.onCall(phone) : null,
                icon: const Icon(Icons.phone, color: kPrimaryColor),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: widget.onAddToCart,
                icon: const Icon(Icons.add_shopping_cart, color: kPrimaryColor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
