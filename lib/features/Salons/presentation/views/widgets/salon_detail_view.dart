import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/features/Salons/presentation/views/widgets/salon_info_section.dart';
import 'package:glamora_project/models.dart';
import 'package:url_launcher/url_launcher.dart';

class SalonDetailView extends StatefulWidget {
  final Salon salon;
  const SalonDetailView({super.key, required this.salon});

  @override
  State<SalonDetailView> createState() => _SalonDetailViewState();
}

class _SalonDetailViewState extends State<SalonDetailView> {
  late Salon _currentSalon;
  int _currentIndex = 0;
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  bool _isFavorite = false;
  bool _favAnimating = false;

  List<Service> _services = [];
  bool _loadingServices = true;

  // ======== خصائص التقييم =========
  String? _eligibleBookingId; // الحجز اللي مسموح له تقييمه
  bool _ratingDialogShown = false;
  bool _submittingReview = false;

  // ======== قائمة الريفيوهات =========
  List<Review> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _currentSalon = widget.salon; // نسخة قابلة للتحديث
    _pageController = PageController();
    _startAutoSlide();
    _checkIfFavorite();
    _fetchServices();
    _checkRatingEligibility(); // التحقق هل اليوزر يحق له التقييم
    _fetchReviews(); // جلب التقييمات الحالية للصالون
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide({Duration interval = const Duration(seconds: 4)}) {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(interval, (t) {
      final images = _currentSalon.images.isNotEmpty
          ? _currentSalon.images
          : ['assets/images/salon_placeholder.png'];
      if (_pageController.hasClients && images.isNotEmpty) {
        final next = (_currentIndex + 1) % images.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _checkIfFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isFavorite = false);
      return;
    }
    final snap = await FirebaseDatabase.instance
        .ref('users/$uid/favorites/${_currentSalon.id}')
        .get();

    setState(() => _isFavorite = snap.exists);
  }

  Future<void> _toggleFavorite() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add favorites')),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
      _favAnimating = true;
    });

    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _favAnimating = false);
    });

    final ref = FirebaseDatabase.instance.ref(
      'users/$uid/favorites/${_currentSalon.id}',
    );

    if (_isFavorite) {
      await ref.set(true);
    } else {
      await ref.remove();
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _addToCart() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final cartRef = FirebaseDatabase.instance.ref('cart/$uid').push();
    await cartRef.set({
      'id': cartRef.key,
      'salonId': _currentSalon.id,
      'addedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ============================ خدمات الصالون ============================
  Future<void> _fetchServices() async {
    setState(() => _loadingServices = true);

    final snap = await FirebaseDatabase.instance.ref('salon_services').get();
    if (!snap.exists || snap.value == null) {
      setState(() {
        _services = [];
        _loadingServices = false;
      });
      return;
    }

    final allSalonServices = Map<String, dynamic>.from(snap.value as Map);

    // نجلب كل الخدمات الخاصة بالصالون
    final futures = <Future<Service?>>[];

    allSalonServices.forEach((key, value) {
      final ss = Map<String, dynamic>.from(value);
      if (ss['salonId'] == _currentSalon.id) {
        futures.add(
          FirebaseDatabase.instance
              .ref('services/${ss['serviceId']}')
              .get()
              .then((serviceSnap) {
                if (serviceSnap.exists && serviceSnap.value != null) {
                  final sData = Map<String, dynamic>.from(
                    serviceSnap.value as Map,
                  );
                  return Service(
                    id: sData['id'] ?? ss['serviceId'],
                    name: sData['title'] ?? 'Service',
                    price: ss['price'] != null
                        ? double.tryParse(ss['price'].toString()) ?? 0.0
                        : 0.0,
                    extra: sData,
                  );
                }
                return null;
              }),
        );
      }
    });

    final results = await Future.wait(futures);
    setState(() {
      _services = results.whereType<Service>().toList();
      _loadingServices = false;
    });
  }

  // ============================ جلب التقييمات ============================

  Future<void> _fetchReviews() async {
    setState(() => _loadingReviews = true);

    try {
      final ref = FirebaseDatabase.instance.ref('reviews');
      final snap = await ref.get();

      // لو ما في نود أصلاً
      if (!snap.exists || snap.value == null) {
        if (!mounted) return;
        setState(() {
          _reviews = [];
          _loadingReviews = false;
        });
        return;
      }

      // تحويل القيمة لـ Map بشكل آمن
      final raw = Map<dynamic, dynamic>.from(snap.value as Map);

      final loaded = <Review>[];

      raw.forEach((key, value) {
        if (value == null) return;

        final data = Map<String, dynamic>.from(value as Map);

        // فلترة الريفيوهات حسب الصالون الحالي
        if (data['salonId']?.toString() == _currentSalon.id) {
          loaded.add(Review.fromMap(key.toString(), data));
        }
      });

      // ترتيب الأحدث أولاً
      loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) return;
      setState(() {
        _reviews = loaded;
        _loadingReviews = false;
      });
    } catch (e, st) {
      debugPrint('Error in _fetchReviews: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loadingReviews = false;
      });
    }
  }

  // ============================ التقييم ============================

  /// يتحقق إذا اليوزر الحالي عنده حجز مكتمل وغير مقيّم مع هذا الصالون
  Future<void> _checkRatingEligibility() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final bookingsSnap = await FirebaseDatabase.instance
        .ref('bookings')
        .orderByChild('userId')
        .equalTo(uid)
        .get();

    if (!bookingsSnap.exists) return;

    String? foundBookingId;

    for (final child in bookingsSnap.children) {
      if (child.value == null) continue;
      final data = Map<String, dynamic>.from(child.value as Map);

      final salonId = data['salonId']?.toString();
      final status = data['status']?.toString() ?? 'pending';
      final bool rated = data['rated'] == true;

      if (salonId == _currentSalon.id && status == 'completed' && !rated) {
        // id في الداتا أو المفتاح
        foundBookingId = data['id']?.toString() ?? child.key!;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _eligibleBookingId = foundBookingId;
    });

    // لو في حجز مؤهل، نعرض الـ Popup تلقائياً (Scenario 2)
    if (foundBookingId != null && !_ratingDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRatingDialog();
      });
    }
  }

  Future<void> _submitReview({required int rating, String? comment}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _eligibleBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to rate your experience')),
      );
      return;
    }

    final bookingId = _eligibleBookingId!;
    final rootRef = FirebaseDatabase.instance.ref();

    // قراءة بيانات الصالون الحالية
    final salonRef = rootRef.child('salons/${_currentSalon.id}');
    final salonSnap = await salonRef.get();
    if (!salonSnap.exists || salonSnap.value == null) {
      throw Exception('Salon not found');
    }

    final salonData = Map<String, dynamic>.from(salonSnap.value as Map);
    final double currentRating =
        (salonData['rating'] as num?)?.toDouble() ?? 0.0;
    final int currentCount = (salonData['reviews_count'] as num?)?.toInt() ?? 0;

    final int newCount = currentCount + 1;
    final double newAvg = ((currentRating * currentCount) + rating) / newCount;

    final now = DateTime.now().toUtc();
    final nowIso = now.toIso8601String();

    // إنشاء تقييم جديد
    final newReviewRef = rootRef.child('reviews').push();
    final reviewId = newReviewRef.key!;

    final Map<String, Object?> updates = {
      'reviews/$reviewId': {
        'id': reviewId,
        'userId': uid,
        'salonId': _currentSalon.id,
        'rating': rating,
        'comment': comment ?? '',
        'bookingId': bookingId,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      },
      'salons/${_currentSalon.id}/rating': newAvg,
      'salons/${_currentSalon.id}/reviews_count': newCount,
      'bookings/$bookingId/rated': true,
      'bookings/$bookingId/updatedAt': nowIso,
    };

    await rootRef.update(updates);

    if (!mounted) return;

    setState(() {
      _currentSalon = _currentSalon.copyWith(
        rating: newAvg,
        reviewsCount: newCount,
      );
      _eligibleBookingId = null;
    });

    // نرجع نجيب الريفيوهات من جديد (عشان يظهر آخر تقييم في القائمة)
    await _fetchReviews();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('شكراً لتقييمك 💖')));
  }

  void _showRatingDialog() {
    if (_eligibleBookingId == null || _ratingDialogShown) return;
    _ratingDialogShown = true;

    showDialog(
      context: context,
      builder: (context) {
        int selectedRating = 5;
        final TextEditingController commentController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('قيّمي تجربتك مع ${_currentSalon.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= selectedRating;
                      return IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            selectedRating = starIndex;
                          });
                        },
                        icon: Icon(
                          isSelected ? Icons.star : Icons.star_border,
                          color: isSelected ? Colors.amber[700] : Colors.grey,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'اكتبي تعليقك (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: _submittingReview
                      ? null
                      : () async {
                          if (selectedRating < 1 || selectedRating > 5) return;

                          setStateDialog(() {
                            _submittingReview = true;
                          });

                          try {
                            await _submitReview(
                              rating: selectedRating,
                              comment: commentController.text.trim().isEmpty
                                  ? null
                                  : commentController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _submittingReview = false;
                              });
                            }
                          }
                        },
                  child: _submittingReview
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _ratingDialogShown = false;
    });
  }

  Widget _buildImage(String url) {
    return Image.network(url, fit: BoxFit.cover, width: double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final images = _currentSalon.images.isNotEmpty
        ? _currentSalon.images
        : ['assets/images/salon_placeholder.png'];

    return Scaffold(
      backgroundColor: Colors.white,
      // شيلنا الـ FloatingActionButton اللي كان للحجز تحت
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (_, i) => _buildImage(images[i]),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 10 : 6,
                          height: _currentIndex == i ? 10 : 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == i
                                ? Colors.white
                                : Colors.white54,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // كل بيانات الصالون
                    SalonInfoSection(
                      salon: _currentSalon,
                      isFavorite: _isFavorite,
                      favAnimating: _favAnimating,
                      onToggleFavorite: _toggleFavorite,
                      onCall: _callPhone,
                      onAddToCart: _addToCart,
                    ),

                    const SizedBox(height: 12),

                    // زر تقييم التجربة (لو عنده حجز مكتمل)
                    if (_eligibleBookingId != null)
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _showRatingDialog,
                          icon: const Icon(Icons.star_rate),
                          label: const Text('قيّمي تجربتك'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 22),

                    const Text(
                      "Services",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _loadingServices
                        ? const Center(child: CircularProgressIndicator())
                        : _services.isEmpty
                        ? const Text("No services found for this salon.")
                        : Column(
                            children: _services.map((s) {
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 1.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Price: \$${s.price.toString()}",
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              );
                            }).toList(),
                          ),

                    const SizedBox(height: 22),

                    const Text(
                      "Reviews",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_loadingReviews)
                      const Center(child: CircularProgressIndicator())
                    else if (_reviews.isEmpty)
                      const Text("No reviews yet for this salon.")
                    else
                      Column(
                        children: _reviews.map((r) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      final starIndex = index + 1;
                                      return Icon(
                                        starIndex <= r.rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 18,
                                        color: Colors.amber[700],
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  if (r.comment != null &&
                                      r.comment!.trim().isNotEmpty)
                                    Text(
                                      r.comment!,
                                      style: const TextStyle(fontSize: 14),
                                    )
                                  else
                                    const Text(
                                      'No comment provided.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
