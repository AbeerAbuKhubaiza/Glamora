import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/core/network/realtime_api.dart';

class ServicesRepository {
  const ServicesRepository();

  Future<List<Service>> fetchAllServices() async {
    try {
      final data = await getNode('services');
      if (data == null) return [];

      final List<Service> services = [];
      data.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          services.add(Service.fromMap(key, map));
        }
      });

      return services;
    } catch (e) {
      // debugPrint('fetchAllServices error: $e');
      return [];
    }
  }

  Future<Map<String, String>> fetchServicesTitles() async {
    final data = await getNode('services');
    if (data == null) return {};

    final Map<String, String> result = {};
    data.forEach((key, value) {
      if (value is Map && value['title'] != null) {
        result[key] = value['title'].toString();
      }
    });
    return result;
  }

  Future<Service?> fetchServiceById(String serviceId) async {
    try {
      final data = await getNode('services/$serviceId');
      if (data == null) return null;
      return Service.fromMap(serviceId, data);
    } catch (e) {
      return null;
    }
  }

  Future<List<Service>> fetchSalonServices(String salonId) async {
    try {
      final servicesData = await getNode('services');
      final salonServicesData = await getNode('salon_services');

      if (servicesData == null || salonServicesData == null) return [];

      final Map<String, Map<String, dynamic>> baseServices = {};
      servicesData.forEach((key, value) {
        if (value is Map) {
          baseServices[key] = Map<String, dynamic>.from(value);
        }
      });

      final List<Service> services = [];
      salonServicesData.forEach((ssId, value) {
        if (value is! Map) return;
        final ssMap = Map<String, dynamic>.from(value);

        if (ssMap['salonId']?.toString() != salonId) return;

        final serviceId = ssMap['serviceId']?.toString();
        if (serviceId == null) return;

        final base = baseServices[serviceId];
        if (base == null) return;

        final merged = <String, dynamic>{};
        merged.addAll(base); 

        merged['price'] = ssMap['price'] ?? merged['price'];
        merged['duration'] = ssMap['duration'] ?? merged['duration'];
        merged['salonId'] = salonId;
        merged['salonServiceId'] = ssId;
        merged['serviceId'] = serviceId;

        services.add(Service.fromMap(ssId, merged));
      });

      return services;
    } catch (e) {
      // debugPrint('fetchSalonServices error: $e');
      return [];
    }
  }
}
