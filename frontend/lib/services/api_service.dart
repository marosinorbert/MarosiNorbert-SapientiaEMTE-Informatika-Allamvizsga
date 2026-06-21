import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://cultivate-radar-swimmer.ngrok-free.dev/api';

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static const String _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();

    return {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/password'),
      headers: await authHeaders(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Nem sikerült módosítani a jelszót.');
    }
  }

  static Future<void> deleteProfile() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Nem sikerült törölni a profilt.');
    }

    await logout();
  }

  static Future<Map<String, dynamic>> getLatestSensorData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sensors'),
      headers: await authHeaders(),
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
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Nem sikerült lekérni az előzményeket. '
      'Status: ${response.statusCode}',
    );
  }

  static Future<String> exportSensorDataCsv({
    bool today = false,
    int? days,
  }) async {
    String url = '$baseUrl/sensors/export/csv';

    if (today) {
      url += '?today=true';
    } else {
      url += '?days=${days ?? 7}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    }

    throw Exception(
      'Nem sikerült exportálni a szenzoradatokat. '
      'Status: ${response.statusCode}',
    );
  }

  static Future<void> toggleDevice(String device, bool isOn) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$device'),
      headers: await authHeaders(),
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
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Nem sikerült lekérni az eszközöket. A Beállítások oldalon ellenőrizd az eszköz csatlakozást.');
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/settings'),
      headers: await authHeaders(),
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
      headers: await authHeaders(),
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
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni az ESP32 státuszt');
  }

  static Future<List<dynamic>> getAlerts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/alerts'),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni a riasztásokat');
  }

  static Future<void> acknowledgeAlert(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/alerts/$id/read'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült nyugtázni');
    }
  }

  static Future<void> toggleDeviceMode(String device, bool isAuto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$device/mode'),
      headers: await authHeaders(),
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
      headers: await authHeaders(),
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
      headers: await authHeaders(),
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
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült törölni a riasztást');
    }
  }

  static Future<void> deleteAllAlerts() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/alerts'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült törölni a riasztásokat');
    }
  }

  static Future<List<dynamic>> getPlants() async {
    final response = await http.get(
      Uri.parse('$baseUrl/plants'),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni a növényeket');
  }

  static Future<void> addPlant({
    required String name,
    required String species,
    required String emoji,
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required double soilMin,
    required double soilMax,
    required double lightMin,
    required double lightMax,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/plants'),
      headers: await authHeaders(),
      body: jsonEncode({
        'name': name,
        'species': species,
        'emoji': emoji,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'humidityMin': humidityMin,
        'humidityMax': humidityMax,
        'soilMin': soilMin,
        'soilMax': soilMax,
        'lightMin': lightMin,
        'lightMax': lightMax,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Nem sikerült létrehozni a növényt');
    }
  }

  static Future<void> deletePlant(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/plants/$id'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült törölni a növényt');
    }
  }

  static Future<void> updatePlant({
    required int id,
    required String name,
    required String species,
    required String emoji,
    required double tempMin,
    required double tempMax,
    required double humidityMin,
    required double humidityMax,
    required double soilMin,
    required double soilMax,
    required double lightMin,
    required double lightMax,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/plants/$id'),
      headers: await authHeaders(),
      body: jsonEncode({
        'name': name,
        'species': species,
        'emoji': emoji,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'humidityMin': humidityMin,
        'humidityMax': humidityMax,
        'soilMin': soilMin,
        'soilMax': soilMax,
        'lightMin': lightMin,
        'lightMax': lightMax,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Nem sikerült módosítani a növényt');
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await saveToken(data['token']);
      return data;
    }

    throw Exception(data['message'] ?? 'Sikertelen regisztráció');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveToken(data['token']);
      return data;
    }

    throw Exception(data['message'] ?? 'Sikertelen bejelentkezés');
  }

  static Future<List<dynamic>> getMyDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-devices'),
      headers: await authHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Nem sikerült lekérni a saját eszközöket');
  }

  static Future<bool> hasClaimedDevice() async {
    final devices = await getMyDevices();
    return devices.isNotEmpty;
  }

  static Future<Map<String, dynamic>> claimDevice({
    required String claimCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/my-devices/claim'),
      headers: await authHeaders(),
      body: jsonEncode({
        'claimCode': claimCode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      data['message'] ?? 'Nem sikerült hozzárendelni az eszközt',
    );
  }

  static Future<void> deleteMyDevice(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/my-devices/$id'),
      headers: await authHeaders(),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);

      throw Exception(
        data['message'] ?? 'Nem sikerült leválasztani az ESP32 eszközt',
      );
    }
  }
}
