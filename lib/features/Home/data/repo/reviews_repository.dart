import 'package:flutter/foundation.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/core/network/realtime_api.dart';
import 'package:firebase_database/firebase_database.dart';

class ReviewsRepository {
  const ReviewsRepository();
  Future<List<Review>> fetchSalonReviews(String salonId) async {
    try {
      final snap = await FirebaseDatabase.instance
          .ref('reviews')
          .orderByChild('salonId')
          .equalTo(salonId)
          .get();

      if (!snap.exists) return [];

      final reviews = <Review>[];
      for (final child in snap.children) {
        final value = child.value;
        if (value is Map) {
          reviews.add(
            Review.fromMap(child.key ?? '', Map<String, dynamic>.from(value)),
          );
        }
      }

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } catch (e, st) {
      debugPrint('fetchSalonReviews error: $e');
      debugPrint('$st');
      return [];
    }
  }

  Future<List<Review>> fetchUserReviews(String userId) async {
    try {
      final raw = await getNode('reviews');
      if (raw == null) return [];

      final data = Map<String, dynamic>.from(raw as Map);

      final reviews = <Review>[];

      data.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);

          final reviewUserId = map['userId']?.toString();
          if (reviewUserId == userId) {
            reviews.add(Review.fromMap(key.toString(), map));
          }
        }
      });

      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    } catch (e, st) {
      debugPrint('fetchUserReviews error: $e');
      debugPrint('$st');
      return [];
    }
  }

  Future<Review?> fetchReviewForBooking(String bookingId) async {
    try {
      final raw = await getNode('reviews');
      if (raw == null) return null;

      final data = Map<String, dynamic>.from(raw as Map);

      for (final entry in data.entries) {
        final value = entry.value;

        if (value is Map) {
          final map = Map<String, dynamic>.from(value);

          if (map['bookingId']?.toString() == bookingId) {
            return Review.fromMap(entry.key.toString(), map);
          }
        }
      }

      return null;
    } catch (e, st) {
      debugPrint('fetchReviewForBooking error: $e');
      debugPrint('$st');
      return null;
    }
  }
}
