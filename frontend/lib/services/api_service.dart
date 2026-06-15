import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://cultivate-radar-swimmer.ngrok-free.dev/api';

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

  static Future<List<dynamic>> getSensorHistory({
    int? hours,
    int? days,
    bool today = false,
  }) async {
    String url = '$baseUrl/sensors/history';

    if (today) {
      url += '?today=true';
    } else if (hours != null) {
      url += '?hours=$hours';
    } else if (days != null) {
      url += '?days=$days';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Nem sikerült lekérni az előzményeket. '
      'Status: ${response.statusCode}',
    );
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

  static Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni a beállításokat');
  }

  static Future<void> updateSettings({
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required double soilMin,
    required double soilMax,
    required double lightMin,
    required double lightMax,
    required bool darkMode,
    required String language,
    required String tempUnit,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/settings'),
      headers: headers,
      body: jsonEncode({
        'tempMin': tempMin,
        'tempMax': tempMax,
        'humidityMin': humidityMin,
        'humidityMax': humidityMax,
        'soilMin': soilMin,
        'soilMax': soilMax,
        'lightMin': lightMin,
        'lightMax': lightMax,
        'darkMode': darkMode,
        'language': language,
        'tempUnit': tempUnit,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült menteni a beállításokat');
    }
  }

  static Future<Map<String, dynamic>> getEsp32Status() async {
    final response = await http.get(
      Uri.parse('$baseUrl/esp32/status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni az ESP32 státuszt');
  }

  static Future<List<dynamic>> getAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni a riasztásokat');
  }

  static Future<void> acknowledgeAlert(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/alerts/$id/read'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült nyugtázni');
    }
  }

  static Future<void> toggleDeviceMode(String device, bool isAuto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$device/mode'),
      headers: headers,
      body: jsonEncode({
        'isAuto': isAuto,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült módosítani az automata módot');
    }
  }

  static Future<List<dynamic>> getLogs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/logs'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni a naplóbejegyzéseket');
  }

  static Future<void> updateDeviceSchedule({
    required String device,
    required bool scheduleEnabled,
    required String scheduleOn,
    required String scheduleOff,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$device/schedule'),
      headers: headers,
      body: jsonEncode({
        'scheduleEnabled': scheduleEnabled,
        'scheduleOn': scheduleOn,
        'scheduleOff': scheduleOff,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült menteni az ütemezést');
    }
  }

  static Future<void> deleteAlert(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/alerts/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült törölni a riasztást');
    }
  }

  static Future<void> deleteAllAlerts() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/alerts'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült törölni a riasztásokat');
    }
  }
}
