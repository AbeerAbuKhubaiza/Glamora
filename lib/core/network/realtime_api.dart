import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const String dbBase = 'https://glamoraapp-cc35f-default-rtdb.firebaseio.com';
Future<String?> _authParam() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final token = await user.getIdToken();
  return 'auth=$token';
}

Future<Map<String, dynamic>?> getNode(String path) async {
  final auth = await _authParam();
  final url = Uri.parse('$dbBase/$path.json${auth != null ? '?$auth' : ''}');

  final res = await http.get(url);

  if (res.statusCode != 200) {
    throw Exception('Failed to load $path (${res.statusCode})');
  }

  if (res.body == 'null' || res.body.isEmpty) return null;

  final decoded = json.decode(res.body);
  if (decoded is Map<String, dynamic>) return decoded;

  if (decoded is List) {
    final Map<String, dynamic> map = {};
    for (int i = 0; i < decoded.length; i++) {
      map[i.toString()] = decoded[i];
    }
    return map;
  }

  return null;
}


Future<void> setNode(String path, Map<String, dynamic> data) async {
  final auth = await _authParam();
  final url = Uri.parse('$dbBase/$path.json${auth != null ? '?$auth' : ''}');

  final res = await http.put(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(data),
  );

  if (res.statusCode >= 400) {
    throw Exception('Failed to set $path (${res.statusCode})');
  }
}

Future<void> updateNode(String path, Map<String, dynamic> data) async {
  final auth = await _authParam();
  final url = Uri.parse('$dbBase/$path.json${auth != null ? '?$auth' : ''}');

  final res = await http.patch(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(data),
  );

  if (res.statusCode >= 400) {
    throw Exception('Failed to update $path (${res.statusCode})');
  }
}
