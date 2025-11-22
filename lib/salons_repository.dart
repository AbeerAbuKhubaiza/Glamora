import 'package:glamora_project/models.dart';
import 'package:glamora_project/realtime_api.dart';

/// sortBy: 'rating' | 'createdAt' | null
Future<List<Salon>> _sortSalons(List<Salon> list, String? sortBy) async {
  if (sortBy == 'rating') {
    list.sort((a, b) => (b.rating).compareTo(a.rating));
  } else if (sortBy == 'createdAt') {
    list.sort((a, b) {
      final aDt = a.createdAt;
      final bDt = b.createdAt;
      if (aDt != null && bDt != null) return bDt.compareTo(aDt);
      if (aDt != null) return -1;
      if (bDt != null) return 1;
      return 0;
    });
  }
  return list;
}

class SalonsRepository {
  /// Fetch salons from Realtime DB.
  /// [onlyApproved] when true returns only salons with isApproved == true.
  /// [sortBy] optional: 'rating' or 'createdAt'
  /// [limit] optional: limit number of results (after filtering & sorting)
  Future<List<Salon>> fetchSalons({
    bool onlyApproved = true,
    String? sortBy,
    int? limit,
  }) async {
    try {
      final data = await getNode('salons');
      if (data == null) return [];

      final List<Salon> salons = [];
      data.forEach((key, value) {
        try {
          // ensure we have a Map<String, dynamic> for the factory
          if (value is Map<String, dynamic>) {
            salons.add(Salon.fromMap(key, value));
          } else if (value is Map) {
            salons.add(Salon.fromMap(key, Map<String, dynamic>.from(value)));
          } else {
            // In case getNode returned a list converted to map indices or other types,
            // attempt to coerce to Map.
            // Skip if cannot.
          }
        } catch (e) {
          // ignore malformed entry but log for debug
          // print('Skipped salon $key due to parse error: $e');
        }
      });

      // filter approved if requested
      List<Salon> results = salons;
      if (onlyApproved) {
        results = results.where((s) => s.isApproved).toList();
      }

      // optional sorting
      if (sortBy != null) {
        results = await _sortSalons(results, sortBy);
      }

      // optional limiting
      if (limit != null && limit > 0 && results.length > limit) {
        results = results.sublist(0, limit);
      }

      return results;
    } catch (e) {
      // print('fetchSalons error: $e');
      return [];
    }
  }
}
