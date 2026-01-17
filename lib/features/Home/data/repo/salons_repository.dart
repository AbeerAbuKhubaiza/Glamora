import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/core/network/realtime_api.dart';

Future<List<Salon>> _sortSalons(List<Salon> list, String? sortBy) async {
  if (sortBy == 'rating') {
    list.sort((a, b) => b.rating.compareTo(a.rating));
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
  const SalonsRepository();

  Future<List<Salon>> fetchSalons({
    AppUser? currentUser,
    bool onlyApproved = true,
    String? sortBy,
    int? limit,
  }) async {
    try {
      final data = await getNode('salons');
      if (data == null) return [];

      final favorites = currentUser?.favorites ?? <String, bool>{};

      final List<Salon> salons = [];
      data.forEach((key, value) {
        try {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            salons.add(
              Salon.fromMap(key, map, isFavorite: favorites[key] == true),
            );
          }
        } catch (e) {
        }
      });

      List<Salon> results = salons;
      if (onlyApproved) {
        results = results.where((s) => s.isApproved).toList();
      }

      if (sortBy != null) {
        results = await _sortSalons(results, sortBy);
      }

      if (limit != null && limit > 0 && results.length > limit) {
        results = results.sublist(0, limit);
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<Salon>> fetchOwnerSalonsByOwnerId(
    String ownerId, {
    String? sortBy,
  }) async {
    try {
      final data = await getNode('salons');
      if (data == null) return [];

      final List<Salon> salons = [];
      data.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          if (map['ownerId']?.toString() == ownerId) {
            salons.add(Salon.fromMap(key, map));
          }
        }
      });

      if (sortBy != null) {
        return _sortSalons(salons, sortBy);
      }

      return salons;
    } catch (e) {
      return [];
    }
  }

  Future<Salon?> fetchSalonById(String salonId) async {
    try {
      final data = await getNode('salons/$salonId');
      if (data == null) return null;
      return Salon.fromMap(salonId, data);
    } catch (e) {
      return null;
    }
  }
}
