import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _wifiSSIDCtrl;
  late TextEditingController _wifiPasswordCtrl;
  late TextEditingController _mqttBrokerCtrl;
  late TextEditingController _mqttPortCtrl;
  late TextEditingController _claimCodeCtrl;

  List<dynamic> _myDevices = [];
  bool _isClaimingDevice = false;

  bool _isLoading = true;
  String? _error;

  double _tempMin = 18;
  double _tempMax = 28;
  double _humidityMin = 50;
  double _humidityMax = 75;
  double _soilMin = 35;
  double _soilMax = 80;
  double _lightMin = 800;
  double _lightMax = 3000;

  @override
  void initState() {
    super.initState();

    _wifiSSIDCtrl = TextEditingController(text: _wifiSSID);
    _wifiPasswordCtrl = TextEditingController(text: _wifiPassword);
    _mqttBrokerCtrl = TextEditingController(text: _mqttBroker);
    _mqttPortCtrl = TextEditingController(text: _mqttPort.toString());
    _claimCodeCtrl = TextEditingController();

    _loadSettings();
    _loadMyDevices();
  }

  @override
  void dispose() {
    _wifiSSIDCtrl.dispose();
    _wifiPasswordCtrl.dispose();
    _mqttBrokerCtrl.dispose();
    _mqttPortCtrl.dispose();
    _claimCodeCtrl.dispose();
    super.dispose();
  }

  // General settings
  bool _darkMode = false;
  String _language = 'hu';
  String _tempUnit = '°C';

  // Connection settings
  String _wifiSSID = 'MyNetwork';
  String _wifiPassword = '••••••••';
  String _mqttBroker = 'mqtt.example.com';
  int _mqttPort = 1883;

// System info
  bool _esp32Online = false;
  String _firmwareVersion = '-';
  String _ipAddress = '-';
  String _lastSeen = '-';
  int _uptimeSeconds = 0;
  int _signalStrength = 0;
  int _freeRam = 0;
  int _totalRam = 0;

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _toInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _formatUptime(int seconds) {
    if (seconds <= 0) return '-';

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '$days nap $hours óra';
    }

    if (hours > 0) {
      return '$hours óra $minutes perc';
    }

    return '$minutes perc';
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ApiService.getSettings();

      Map<String, dynamic>? esp32Status;

      try {
        esp32Status = await ApiService.getEsp32Status();
      } catch (_) {
        esp32Status = null;
      }
      setState(() {
        _tempMin = _toDouble(settings['temp_min'], 18);
        _tempMax = _toDouble(settings['temp_max'], 28);

        _humidityMin = _toDouble(settings['humidity_min'], 50);
        _humidityMax = _toDouble(settings['humidity_max'], 75);

        _soilMin = _toDouble(settings['soil_min'], 35);
        _soilMax = _toDouble(settings['soil_max'], 80);

        _lightMin = _toDouble(settings['light_min'], 800);
        _lightMax = _toDouble(settings['light_max'], 3000);

        _darkMode = settings['dark_mode'] ?? false;
        _language = settings['language'] ?? 'hu';
        _tempUnit = settings['temp_unit'] ?? '°C';

        if (esp32Status != null) {
          _esp32Online = esp32Status['isOnline'] ?? false;
          _firmwareVersion = esp32Status['firmwareVersion']?.toString() ?? '-';
          _ipAddress = esp32Status['ipAddress']?.toString() ?? '-';
          _lastSeen = esp32Status['lastSeen']?.toString() ?? '-';
          _uptimeSeconds = _toInt(esp32Status['uptimeSeconds'], 0);
          _signalStrength = _toInt(esp32Status['signalStrength'], 0);
          _freeRam = _toInt(esp32Status['freeRam'], 0);
          _totalRam = _toInt(esp32Status['totalRam'], 0);
        } else {
          _esp32Online = false;
          _firmwareVersion = '-';
          _ipAddress = '-';
          _lastSeen = '-';
          _uptimeSeconds = 0;
          _signalStrength = 0;
          _freeRam = 0;
          _totalRam = 0;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nem sikerült betölteni a beállításokat: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await ApiService.updateSettings(
        tempMin: _tempMin,
        tempMax: _tempMax,
        humidityMin: _humidityMin,
        humidityMax: _humidityMax,
        soilMin: _soilMin,
        soilMax: _soilMax,
        lightMin: _lightMin,
        lightMax: _lightMax,
        darkMode: _darkMode,
        language: _language,
        tempUnit: _tempUnit,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Beállítások mentve az adatbázisba!'),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba mentés közben: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadMyDevices() async {
    try {
      final devices = await ApiService.getMyDevices();

      if (!mounted) return;

      setState(() {
        _myDevices = devices;
      });
    } catch (e) {
      // Ha még nincs eszköz vagy nincs token, ne törje meg a Settings oldalt.
    }
  }

  Future<void> _claimDevice() async {
    final claimCode = _claimCodeCtrl.text.trim();

    if (claimCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add meg az ESP32 claim kódját.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isClaimingDevice = true;
    });

    try {
      await ApiService.claimDevice(claimCode: claimCode);

      _claimCodeCtrl.clear();
      await _loadMyDevices();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ ESP32 eszköz sikeresen hozzárendelve!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaimingDevice = false;
        });
      }
    }
  }

  Future<void> _deleteDevice(dynamic device) async {
    try {
      await ApiService.deleteMyDevice(device['id']);

      await _loadMyDevices();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Az ESP32 eszköz le lett választva.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nem sikerült leválasztani az ESP32-t: $e'),
        ),
      );
    }
  }

  void _confirmDeleteDevice(dynamic device) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ESP32 leválasztása'),
          content: Text(
            'Biztosan le szeretnéd választani ezt az eszközt?\n\n'
            '${device['device_name'] ?? 'ESP32 eszköz'}\n'
            'Claim kód: ${device['claim_code'] ?? '-'}\n\n'
            'Az eszköz ezután újra hozzárendelhető lesz egy felhasználói fiókhoz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _deleteDevice(device);
              },
              child: const Text('Leválasztás'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Kijelentkezés'),
          content: const Text(
            'Biztosan ki szeretnél jelentkezni ebből a fiókból?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _logout();
              },
              child: const Text('Kijelentkezés'),
            ),
          ],
        );
      },
    );
  }

  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Jelszó módosítása',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jelenlegi jelszó',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                _SettingsTextField(
                  controller: currentCtrl,
                  hint: 'Jelenlegi jelszó',
                  obscure: !showCurrent,
                ),
                const SizedBox(height: 14),
                const Text('Új jelszó',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                _SettingsTextField(
                  controller: newCtrl,
                  hint: 'Új jelszó',
                  obscure: !showNew,
                ),
                const SizedBox(height: 14),
                const Text('Jelszó megerősítése',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                _SettingsTextField(
                  controller: confirmCtrl,
                  hint: 'Jelszó megerősítése',
                  obscure: !showConfirm,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final currentPassword = currentCtrl.text.trim();
                final newPassword = newCtrl.text.trim();
                final confirmPassword = confirmCtrl.text.trim();

                if (currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Minden jelszó mező kitöltése kötelező.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Az új jelszavak nem egyeznek.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await ApiService.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  );

                  if (!mounted) return;

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Jelszó sikeresen módosítva.'),
                      backgroundColor: AppTheme.primary,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hiba: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Mentés'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProfile() async {
    final confirmCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Profil törlése',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ez véglegesen törli a felhasználói profilodat, minden szenzoradatot, naplót, riasztást, növényt és beállítást. Az ESP32 eszköz leválasztásra kerül, és újra claimelhető lesz.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'A megerősítéshez írd be: TORLES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                decoration: InputDecoration(
                  hintText: 'TORLES',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Mégse',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (confirmCtrl.text.trim().toUpperCase() == 'TORLES') {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Profil törlése'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteProfile();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hiba: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Beállítások ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'és konfiguráció',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rendszer beállítások és konfigurációs paraméterek',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 28),

          // General settings
          _SettingsSection(
            title: 'Általános',
            icon: Icons.tune_rounded,
            children: [
              _SettingItem(
                label: 'Téma',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.light_mode_rounded,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Switch(
                      value: _darkMode,
                      onChanged: (v) {
                        setState(() => _darkMode = v);

                        AppSettingsController.themeMode.value =
                            v ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.dark_mode_rounded,
                        size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ),
              _SettingItem(
                label: 'Nyelv',
                trailing: DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'hu', child: Text('Magyar')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (v) {
                    final selected = v ?? 'hu';

                    setState(() => _language = selected);

                    AppSettingsController.language.value = selected;
                  },
                  underline: const SizedBox(),
                ),
              ),
              _SettingItem(
                label: 'Hőmérséklet egység',
                trailing: DropdownButton<String>(
                  value: _tempUnit,
                  items: const [
                    DropdownMenuItem(value: '°C', child: Text('°C')),
                    DropdownMenuItem(value: '°F', child: Text('°F')),
                  ],
                  onChanged: (v) => setState(() => _tempUnit = v ?? '°C'),
                  underline: const SizedBox(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ESP32 device claim
          _SettingsSection(
            title: 'Saját ESP32 eszköz',
            icon: Icons.memory_rounded,
            children: [
              const Text(
                'Add meg az ESP32-re ragasztott egyedi claim kódot. '
                'Ezzel az eszköz a saját fiókodhoz lesz rendelve.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              _SettingsTextField(
                label: 'Claim kód',
                hint: 'pl. GH-001-A7K9',
                controller: _claimCodeCtrl,
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isClaimingDevice ? null : _claimDevice,
                  icon: _isClaimingDevice
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link_rounded),
                  label: Text(
                    _isClaimingDevice
                        ? 'Hozzárendelés...'
                        : 'ESP32 hozzárendelése',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _SettingLabel('Hozzárendelt eszközök'),
              const SizedBox(height: 8),
              if (_myDevices.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Text(
                    'Még nincs ESP32 eszköz hozzárendelve ehhez a fiókhoz.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                )
              else
                Column(
                  children: _myDevices.map((device) {
                    final name = device['device_name'] ?? 'ESP32 eszköz';
                    final code = device['claim_code'] ?? '-';
                    final claimedAt = device['claimed_at'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.memory_rounded,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Kód: $code',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (claimedAt != null)
                                  Text(
                                    'Hozzárendelve: $claimedAt',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'ESP32 leválasztása',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                            ),
                            onPressed: () => _confirmDeleteDevice(device),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Automation settings
          _SettingsSection(
            title: 'Automatikus vezérlés',
            icon: Icons.auto_mode_rounded,
            children: [
              _SettingLabel('Hőmérséklet (°C)'),
              Row(
                children: [
                  Expanded(
                    child: _NumberInput(
                      label: 'Minimum',
                      value: _tempMin,
                      onChanged: (v) => setState(() => _tempMin = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberInput(
                      label: 'Maximum',
                      value: _tempMax,
                      onChanged: (v) => setState(() => _tempMax = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingLabel('Páratartalom (%)'),
              Row(
                children: [
                  Expanded(
                    child: _NumberInput(
                      label: 'Minimum',
                      value: _humidityMin,
                      onChanged: (v) => setState(() => _humidityMin = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberInput(
                      label: 'Maximum',
                      value: _humidityMax,
                      onChanged: (v) => setState(() => _humidityMax = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingLabel('Talajnedvesség (%)'),
              Row(
                children: [
                  Expanded(
                    child: _NumberInput(
                      label: 'Minimum',
                      value: _soilMin,
                      onChanged: (v) => setState(() => _soilMin = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberInput(
                      label: 'Maximum',
                      value: _soilMax,
                      onChanged: (v) => setState(() => _soilMax = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SettingLabel('Fényerősség (lux)'),
              Row(
                children: [
                  Expanded(
                    child: _NumberInput(
                      label: 'Minimum',
                      value: _lightMin,
                      onChanged: (v) => setState(() => _lightMin = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberInput(
                      label: 'Maximum',
                      value: _lightMax,
                      onChanged: (v) => setState(() => _lightMax = v),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          const SizedBox(height: 16),

          // Security settings
          _SettingsSection(
            title: 'Biztonság',
            icon: Icons.security_rounded,
            children: [
              _SettingItem(
                label: 'Jelszó módosítása',
                onTap: _changePassword,
              ),
              const Divider(color: AppTheme.border, height: 1),
              _SettingItem(
                label: 'Felhasználói profil törlése',
                subtitle:
                    'Profil, adatok és ESP32 hozzárendelés végleges törlése',
                onTap: _deleteProfile,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // System info
          _SettingsSection(
            title: 'Rendszer információ',
            icon: Icons.info_rounded,
            children: [
              _InfoRow(
                label: 'ESP32 állapot',
                value: _esp32Online ? 'Online' : 'Offline',
              ),
              _InfoRow(
                label: 'Firmware verzió',
                value: _firmwareVersion,
              ),
              _InfoRow(
                label: 'IP cím',
                value: _ipAddress,
              ),
              _InfoRow(
                label: 'Uptime',
                value: _formatUptime(_uptimeSeconds),
              ),
              _InfoRow(
                label: 'WiFi jelerősség',
                value: '$_signalStrength dBm',
              ),
              _InfoRow(
                label: 'Szabad memória',
                value: _totalRam > 0
                    ? '$_freeRam KB / $_totalRam KB'
                    : '$_freeRam KB',
              ),
              _InfoRow(
                label: 'Utolsó kapcsolat',
                value: _lastSeen,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Összes beállítás mentése'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _SettingsSection(
            title: 'Fiók',
            icon: Icons.account_circle_rounded,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Kijelentkezés'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kijelentkezés után újra be kell jelentkezned a fiókodhoz tartozó melegház adatok eléréséhez.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ── Settings Section ─────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primarySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Children
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Setting Item ─────────────────────────────────────────

class _SettingItem extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// ── Settings Text Field ──────────────────────────────────

class _SettingsTextField extends StatefulWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final bool obscure;
  final TextInputType keyboardType;

  const _SettingsTextField({
    this.label,
    required this.hint,
    this.controller,
    this.onChanged,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<_SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<_SettingsTextField> {
  late TextEditingController _controller;
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _obscured = widget.obscure;
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() => _obscured = !_obscured);
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// ── Number Input ─────────────────────────────────────────

class _NumberInput extends StatelessWidget {
  final String label;
  final double value;
  final Function(double) onChanged;
  final double step;

  const _NumberInput({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => onChanged(value - step),
                child: const Icon(Icons.remove_rounded,
                    size: 16, color: AppTheme.primary),
              ),
              Text(
                value.toStringAsFixed(step < 1 ? 1 : 0),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => onChanged(value + step),
                child: const Icon(Icons.add_rounded,
                    size: 16, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info Row ─────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Setting Label ────────────────────────────────────────

class _SettingLabel extends StatelessWidget {
  final String label;

  const _SettingLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
