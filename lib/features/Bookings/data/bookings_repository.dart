import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/core/network/realtime_api.dart';

class BookingsRepository {
  const BookingsRepository();

  Future<List<Booking>> fetchUserBookings(String userId) async {
    try {
      final data = await getNode('bookings');
      if (data == null) return [];

      final List<Booking> bookings = [];
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final map = Map<String, dynamic>.from(value);
          if (map['userId']?.toString() == userId) {
            bookings.add(Booking.fromMap(key, map));
          }
        } else if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          if (map['userId']?.toString() == userId) {
            bookings.add(Booking.fromMap(key, map));
          }
        }
      });

      bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return bookings;
    } catch (e) {
      // print('fetchUserBookings error: $e');
      return [];
    }
  }

  Future<List<Booking>> fetchOwnerBookings(String ownerId) async {
    try {
      final salonsData = await getNode('salons');
      if (salonsData == null) return [];

      final Set<String> ownerSalonIds = {};
      salonsData.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          if (map['ownerId']?.toString() == ownerId) {
            ownerSalonIds.add(key); 
          }
        }
      });

      if (ownerSalonIds.isEmpty) return [];

      final bookingsData = await getNode('bookings');
      if (bookingsData == null) return [];

      final List<Booking> bookings = [];
      bookingsData.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          final salonId = map['salonId']?.toString() ?? '';
          if (ownerSalonIds.contains(salonId)) {
            bookings.add(Booking.fromMap(key, map));
          }
        }
      });

      bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      return bookings;
    } catch (e) {
      // print('fetchOwnerBookings error: $e');
      return [];
    }
  }


  Future<List<Booking>> fetchSalonBookings(String salonId) async {
    try {
      final data = await getNode('bookings');
      if (data == null) {
        print("DEBUG: No bookings node found in Firebase");
        return [];
      }

      final List<Booking> bookings = [];

      final Map<dynamic, dynamic> allBookings = Map<dynamic, dynamic>.from(
        data,
      );

      allBookings.forEach((key, value) {
        if (value != null && value is Map) {
          final map = Map<String, dynamic>.from(value);

          final bookingSalonId = map['salonId']?.toString();

          if (bookingSalonId == salonId) {
            bookings.add(Booking.fromMap(key.toString(), map));
          }
        }
      });

      bookings.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      print("DEBUG: Found ${bookings.length} bookings for salon: $salonId");
      return bookings;
    } catch (e) {
      print('DEBUG Error fetchSalonBookings: $e');
      return [];
    }
  }
}
