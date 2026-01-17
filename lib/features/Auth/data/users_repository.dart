import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/core/network/realtime_api.dart';

class UsersRepository {
  const UsersRepository();

  Future<AppUser?> fetchUserById(String uid) async {
    try {
      final data = await getNode('users/$uid');
      if (data == null) return null;
      return AppUser.fromMap(uid, data);
    } catch (e) {
      return null;
    }
  }

  Future<List<AppUser>> fetchAllUsers() async {
    try {
      final data = await getNode('users');
      if (data == null) return [];

      final List<AppUser> users = [];
      data.forEach((key, value) {
        if (value is Map) {
          users.add(AppUser.fromMap(key, Map<String, dynamic>.from(value)));
        }
      });
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, String>> fetchUsersNames() async {
    try {
      final data = await getNode('users');
      if (data == null) return {};

      final Map<String, String> result = {};

      final Map<dynamic, dynamic> dataMap = data as Map<dynamic, dynamic>;

      dataMap.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          if (map['name'] != null) {
            result[key.toString()] = map['name'].toString();
          }
        }
      });
      return result;
    } catch (e) {
      print("Error in fetchUsersNames: $e");
      return {};
    }
  }

  Future<void> saveUser(AppUser user) async {
    await setNode('users/${user.id}', user.toMap());

  }
}
