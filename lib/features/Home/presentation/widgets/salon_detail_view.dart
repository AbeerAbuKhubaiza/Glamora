import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_card.dart';
import 'package:glamora_project/features/Home/presentation/widgets/salon_info_section.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/reviews_repository.dart';
import 'package:glamora_project/features/Home/data/repo/salons_repository.dart';
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

  final ReviewsRepository _reviewsRepository = const ReviewsRepository();

  List<Review> _reviews = [];
  bool _loadingReviews = true;

  String? _eligibleBookingId;
  bool _ratingDialogShown = false;
  bool _submittingReview = false;

  late Future<List<Salon>> _similarFuture;

  @override
  void initState() {
    super.initState();
    _currentSalon = widget.salon;
    _pageController = PageController();

    _startAutoSlide();
    _checkIfFavorite();
    _checkRatingEligibility();

    _fetchServices();
    _fetchReviews();

    _similarFuture = _fetchSimilarSalons();
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
      if (!mounted) return;
      setState(() => _isFavorite = false);
      return;
    }
    final snap = await FirebaseDatabase.instance
        .ref('users/$uid/favorites/${_currentSalon.id}')
        .get();

    if (!mounted) return;
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

  Future<void> _fetchServices() async {
    if (!mounted) return;
    setState(() => _loadingServices = true);

    try {
      final snap = await FirebaseDatabase.instance.ref('salon_services').get();
      if (!snap.exists || snap.value == null) {
        if (!mounted) return;
        setState(() {
          _services = [];
          _loadingServices = false;
        });
        return;
      }

      final allSalonServices = Map<dynamic, dynamic>.from(snap.value as Map);
      final futures = <Future<Service?>>[];

      allSalonServices.forEach((ssId, value) {
        if (value == null) return;
        final ss = Map<String, dynamic>.from(value as Map);

        if (ss['salonId']?.toString() != _currentSalon.id) return;

        futures.add(() async {
          final serviceId = ss['serviceId']?.toString();
          if (serviceId == null || serviceId.isEmpty) return null;

          final serviceSnap = await FirebaseDatabase.instance
              .ref('services/$serviceId')
              .get();

          if (!serviceSnap.exists || serviceSnap.value == null) return null;

          final base = Map<String, dynamic>.from(serviceSnap.value as Map);

          final merged = <String, dynamic>{};
          merged.addAll(base);
          merged['price'] = ss['price'] ?? base['price'];
          merged['duration'] = ss['duration'];
          merged['serviceId'] = serviceId;
          merged['salonId'] = _currentSalon.id;
          merged['salonServiceId'] = ssId.toString();

          return Service.fromMap(ssId.toString(), merged);
        }());
      });

      final results = await Future.wait(futures);

      if (!mounted) return;
      setState(() {
        _services = results.whereType<Service>().toList();
        _loadingServices = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _services = [];
        _loadingServices = false;
      });
    }
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() => _loadingReviews = true);

    try {
      debugPrint('FETCH REVIEWS FOR SALON: ${_currentSalon.id}');

      final reviews = await _reviewsRepository.fetchSalonReviews(
        _currentSalon.id,
      );

      final int count = reviews.length;
      final double avg = count == 0
          ? 0.0
          : reviews.fold<int>(0, (sum, r) => sum + r.rating) / count;

      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _loadingReviews = false;

        _currentSalon = _currentSalon.copyWith(
          rating: avg,
          reviewsCount: count,
        );
      });

      debugPrint('REVIEWS COUNT: $count | AVG: $avg');
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      if (!mounted) return;
      setState(() {
        _reviews = [];
        _loadingReviews = false;
      });
    }
  }

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
        foundBookingId = data['id']?.toString() ?? child.key!;
        break;
      }
    }

    if (!mounted) return;
    setState(() => _eligibleBookingId = foundBookingId);

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

    final nowIso = DateTime.now().toUtc().toIso8601String();

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
      'bookings/$bookingId/rated': true,
      'bookings/$bookingId/updatedAt': nowIso,
    };

    await rootRef.update(updates);

    if (!mounted) return;

    setState(() => _eligibleBookingId = null);

    await _fetchReviews();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: const Text(
          'Thanks for sharing your experience',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRatingDialog() {
    if (_eligibleBookingId == null || _ratingDialogShown) return;
    _ratingDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        int selectedRating = 0;
        final TextEditingController commentController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Material(
              color: Colors.transparent,
              child: Center(
                child: AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: AlertDialog(
                    elevation: 14,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),

                    title: Text(
                      'Rate your experience with ${_currentSalon.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),

                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isSelected = starIndex <= selectedRating;

                            return GestureDetector(
                              onTap: () {
                                setStateDialog(() {
                                  selectedRating = starIndex;
                                });
                              },
                              child: AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 34,
                                    color: isSelected
                                        ? Colors.amber.shade600
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 18),

                        TextField(
                          controller: commentController,
                          maxLines: 3,
                          cursorColor: kPrimaryColor,
                          decoration: InputDecoration(
                            hintText: 'Write your comment (optional)',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13.5,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            contentPadding: const EdgeInsets.all(14),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: kPrimaryColor,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    actionsPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),

                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: selectedRating == 0 || _submittingReview
                            ? null
                            : () async {
                                setStateDialog(() => _submittingReview = true);
                                try {
                                  await _submitReview(
                                    rating: selectedRating,
                                    comment:
                                        commentController.text.trim().isEmpty
                                        ? null
                                        : commentController.text.trim(),
                                  );
                                  if (mounted) Navigator.pop(context);
                                } finally {
                                  if (mounted) {
                                    setState(() => _submittingReview = false);
                                  }
                                }
                              },
                        child: _submittingReview
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Salon>> _fetchSimilarSalons() async {
    final all = await const SalonsRepository().fetchSalons(onlyApproved: true);

    final cat = _currentSalon.categoryId;
    final filtered = all.where((s) {
      if (s.id == _currentSalon.id) return false;
      if (cat == null || cat.isEmpty) return true;
      return s.categoryId == cat;
    }).toList();

    return filtered.length > 8 ? filtered.sublist(0, 8) : filtered;
  }

  Widget _imageSkeleton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.10),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.black.withOpacity(0.08),
        ),
      ),
    );
  }

  Widget _buildImageItem(String path) {
    final isAsset = path.startsWith('assets/');

    if (isAsset) {
      return Image.asset(path, fit: BoxFit.cover, width: double.infinity);
    }

    return Image.network(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _imageSkeleton();
      },
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets/images/salon_placeholder.png',
          fit: BoxFit.cover,
          width: double.infinity,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _currentSalon.images.isNotEmpty
        ? _currentSalon.images
        : ['assets/images/salon_placeholder.png'];

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 320,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) => _buildImageItem(images[i]),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 70,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: topPad + 10,
                  left: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.45),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SalonInfoSection(
                    salon: _currentSalon,
                    isFavorite: _isFavorite,
                    favAnimating: _favAnimating,
                    onToggleFavorite: _toggleFavorite,
                    onCall: _callPhone,
                    onAddToCart: _addToCart,

                    services: _services,
                    loadingServices: _loadingServices,

                    reviews: _reviews,
                    loadingReviews: _loadingReviews,
                  ),

                  const SizedBox(height: 12),

                  if (_eligibleBookingId != null)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _showRatingDialog,
                        icon: const Icon(Icons.star_rate),
                        label: const Text('Rate your experience'),
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

                  const SizedBox(height: 18),
                  const Text(
                    "Similar Salons",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<Salon>>(
                    future: _similarFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: kPrimaryColor,
                            ),
                          ),
                        );
                      }

                      final sims = snapshot.data ?? [];
                      if (sims.isEmpty) {
                        return Text(
                          "No similar salons found.",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 270,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: const EdgeInsets.fromLTRB(2, 2, 2, 14),
                          itemCount: sims.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final s = sims[i];
                            return SizedBox(
                              width: 200,
                              child: SalonCard(
                                salon: s,
                                onTap: () async {
                                  await Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SalonDetailView(salon: s),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
