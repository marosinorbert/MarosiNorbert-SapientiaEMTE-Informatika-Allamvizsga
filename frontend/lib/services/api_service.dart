import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://kabob-headcount-silk.ngrok-free.dev/api';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<Map<String, dynamic>> getLatestSensorData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sensors'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Nem sikerült lekérni a szenzoradatokat. '
        'Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  static Future<List<dynamic>> getSensorHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sensors/history'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Nem sikerült lekérni az előzményeket. '
        'Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  static Future<void> toggleDevice(String device, bool isOn) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$device'),
      headers: headers,
      body: jsonEncode({
        'isOn': isOn,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült módosítani az eszköz állapotát');
    }
  }

  static Future<List<dynamic>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Nem sikerült lekérni az eszközöket');
    }
  }
}
