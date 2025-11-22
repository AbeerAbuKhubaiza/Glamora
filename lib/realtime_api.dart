import 'dart:convert';
import 'package:http/http.dart' as http;

const String dbBase = 'https://glamoraapp-cc35f-default-rtdb.firebaseio.com';

Future<Map<String, dynamic>?> getNode(String path) async {
  final url = Uri.parse('$dbBase/$path.json');
  final res = await http.get(url);
  if (res.statusCode != 200) {
    throw Exception('Failed to load $path (${res.statusCode})');
  }
  if (res.body == 'null' || res.body.isEmpty) return null;

  final decoded = json.decode(res.body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  // إذا حصلت على نوع غير متوقع (مثلاً قائمة) نحاول تحويله لخريطة
  if (decoded is List) {
    // حوِّل القائمة لخريطة index => value
    final Map<String, dynamic> map = {};
    for (int i = 0; i < decoded.length; i++) {
      map[i.toString()] = decoded[i];
    }
    return map;
  }
  return null;
}
