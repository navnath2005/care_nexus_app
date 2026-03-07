import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080";

  // ✅ EXISTING METHOD (UNCHANGED)
  static Future<List<dynamic>> getPatients() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/patients"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load patients");
    }
  }

  // ✅ NEW: DISTANCE + ETA (ONLY UPDATE)
  static Future<Map<String, String>> getDistanceAndETA({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String googleApiKey,
  }) async {
    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/distancematrix/json"
      "?origins=$originLat,$originLng"
      "&destinations=$destLat,$destLng"
      "&key=$googleApiKey",
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch distance & ETA");
    }

    final data = jsonDecode(response.body);
    final element = data["rows"][0]["elements"][0];

    return {
      "distance": element["distance"]["text"],
      "duration": element["duration"]["text"],
    };
  }
}
