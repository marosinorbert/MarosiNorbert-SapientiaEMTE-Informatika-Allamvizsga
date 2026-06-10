import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000/api';
  static Future<Map<String, dynamic>> getLatestSensorData() async {
    final response = await http.get(Uri.parse('$baseUrl/sensors'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nem sikerült lekérni a szenzoradatokat');
    }
  }

  static Future<List<dynamic>> getSensorHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/sensors/history'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nem sikerült lekérni az előzményeket');
    }
  }
}
