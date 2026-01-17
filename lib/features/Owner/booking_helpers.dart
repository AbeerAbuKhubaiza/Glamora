import 'package:firebase_database/firebase_database.dart';

final _db = FirebaseDatabase.instance.ref();

final Map<String, String> _userNameCache = {};
final Map<String, String> _serviceNameCache = {};

Future<String> getUserName(String userId) async {
  try {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    final snap = await FirebaseDatabase.instance.ref('users/$userId').get();

    if (snap.exists && snap.value != null) {
      final data = snap.value;
      if (data is Map) {
        final name = data['name']?.toString() ?? 'Client';
        _userNameCache[userId] = name;
        return name;
      }
    }
    return 'Client';
  } catch (e) {
    print("DEBUG: Error fetching user name for $userId: $e");
    return 'Client'; 
  }
}
Future<String> getServiceName(String serviceId) async {
  if (_serviceNameCache.containsKey(serviceId)) {
    return _serviceNameCache[serviceId]!;
  }

  final snap = await _db.child('services').child(serviceId).get();
  if (!snap.exists || snap.value is! Map) return 'Service';

  final map = Map<String, dynamic>.from(snap.value as Map);
  final name = map['name']?.toString() ?? 'Service';

  _serviceNameCache[serviceId] = name;
  return name;
}
