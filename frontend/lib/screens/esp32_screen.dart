import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class Esp32Screen extends StatefulWidget {
  const Esp32Screen({super.key});

  @override
  State<Esp32Screen> createState() => _Esp32ScreenState();
}

class _Esp32ScreenState extends State<Esp32Screen> {
  bool _isOnline = true;
  int _signalStrength = 85; // 0-100%
  bool _wifiConnected = true;
  bool _mqttConnected = true;

  int _freeRAM = 142; // KB
  int _totalRAM = 320; // KB
  int _cpuTemp = 42; // °C
  int _uptimeDays = 10;
  int _uptimeHours = 5;
  int _uptimeMinutes = 23;

  bool _isLoading = true;
  String? _error;
  String _ipAddress = '-';
  String _firmwareVersion = '-';

  @override
  void initState() {
    super.initState();
    _loadEsp32Status();
  }

  Future<void> _loadEsp32Status() async {
    try {
      final status = await ApiService.getEsp32Status();

      final uptimeSeconds = status['uptimeSeconds'] ?? 0;
      final days = uptimeSeconds ~/ 86400;
      final hours = (uptimeSeconds % 86400) ~/ 3600;
      final minutes = (uptimeSeconds % 3600) ~/ 60;

      setState(() {
        _isOnline = status['isOnline'] ?? false;
        _wifiConnected = status['wifiConnected'] ?? false;
        _mqttConnected = status['mqttConnected'] ?? false;
        _signalStrength = status['signalStrength'] ?? 0;
        _freeRAM = status['freeRam'] ?? 0;
        _totalRAM = status['totalRam'] ?? 320;
        _cpuTemp = status['cpuTemp'] ?? 0;
        _uptimeDays = days;
        _uptimeHours = hours;
        _uptimeMinutes = minutes;
        _ipAddress = status['ipAddress'] ?? '-';
        _firmwareVersion = status['firmwareVersion'] ?? '-';

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nem sikerült betölteni az ESP32 státuszt: $e';
        _isLoading = false;
      });
    }
  }

  final List<String> _debugLogs = [
    '[14:32:15] System started - v1.3.2',
    '[14:32:16] Initializing DHT22 sensor...',
    '[14:32:17] DHT22 initialized ✓',
    '[14:32:18] Initializing soil moisture sensor...',
    '[14:32:19] Soil sensor initialized ✓',
    '[14:32:20] Initializing light sensor (BH1750)...',
    '[14:32:21] BH1750 initialized ✓',
    '[14:32:22] WiFi: Connecting to "MyNetwork"...',
    '[14:32:25] WiFi: Connected! IP: 192.168.1.100',
    '[14:32:26] MQTT: Connecting to mqtt.example.com:1883...',
    '[14:32:28] MQTT: Connected ✓',
    '[14:32:30] Publishing sensor data...',
    '[14:32:31] Reading DHT22: 24.5°C, 62%',
    '[14:32:32] Reading soil: 45%',
    '[14:32:33] Reading light: 12500 lux',
    '[14:32:34] All data published successfully',
  ];

  final List<_PinInfo> _pins = [
    _PinInfo(
        name: 'DHT22 (Data)',
        gpio: 4,
        status: 'Aktív',
        color: AppTheme.primary),
    _PinInfo(
        name: 'Talajnedvesség',
        gpio: 34,
        status: 'Aktív',
        color: AppTheme.primary),
    _PinInfo(
        name: 'BH1750 (SDA)',
        gpio: 21,
        status: 'Aktív',
        color: AppTheme.primary),
    _PinInfo(
        name: 'BH1750 (SCL)',
        gpio: 22,
        status: 'Aktív',
        color: AppTheme.primary),
    _PinInfo(
        name: 'Relé — Szellőzés',
        gpio: 26,
        status: 'Kikapcsolt',
        color: const Color(0xFF9CA3AF)),
    _PinInfo(
        name: 'Relé — Öntözés',
        gpio: 27,
        status: 'Kikapcsolt',
        color: const Color(0xFF9CA3AF)),
    _PinInfo(
        name: 'Relé — Lámpa',
        gpio: 14,
        status: 'Bekapcsolt',
        color: AppTheme.primary),
    _PinInfo(
        name: 'Relé — Fűtés',
        gpio: 12,
        status: 'Kikapcsolt',
        color: const Color(0xFF9CA3AF)),
  ];

  void _reboot() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ESP32 újraindítása',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
          'Biztosan újra szeretnéd indítani az ESP32-t? Az összes jelenlegi működés leáll.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégse',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() {
                _isOnline = false;
                _wifiConnected = false;
                _mqttConnected = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ESP32 újraindítása...'),
                  duration: Duration(seconds: 3),
                ),
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _isOnline = true;
                    _wifiConnected = true;
                    _mqttConnected = true;
                  });
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Újraindítás'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ESP32 visszaállítása',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
          '⚠️ Ez MINDEN beállítást töröl! Az összes konfigurációt újra kell végezni.',
          style:
              TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégsem',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ESP32 visszaállítása...'),
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Visszaállítás (VÉGLEGESEN)'),
          ),
        ],
      ),
    );
  }

  String get _uptimeLabel =>
      '${_uptimeDays}d ${_uptimeHours}h ${_uptimeMinutes}m';

  double get _ramUsagePercent {
    if (_totalRAM == 0) return 0;
    return ((_totalRAM - _freeRAM) / _totalRAM).clamp(0, 1);
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
                  text: 'ESP32 ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'integráció',
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
            'Mikrovezérlő állapot és telemetria',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 24),

          // Status banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  _isOnline ? AppTheme.primaryLight : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isOnline ? AppTheme.primary : const Color(0xFFEF4444),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isOnline
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _isOnline
                          ? AppTheme.primary
                          : const Color(0xFFEF4444),
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _isOnline
                                  ? AppTheme.primary
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOnline
                                ? 'Az ESP32 aktív és működik'
                                : 'Az ESP32 nem elérhető',
                            style: TextStyle(
                              fontSize: 13,
                              color: _isOnline
                                  ? AppTheme.primary.withOpacity(0.7)
                                  : const Color(0xFFEF4444).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // WiFi + MQTT status
                Row(
                  children: [
                    Expanded(
                      child: _StatusBadge(
                        icon: Icons.wifi_rounded,
                        label: 'WiFi',
                        isConnected: _wifiConnected,
                        signal: _signalStrength,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusBadge(
                        icon: Icons.cloud_rounded,
                        label: 'MQTT',
                        isConnected: _mqttConnected,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Telemetria
          const Text(
            'Telemetria',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _TelemetryCard(
                icon: Icons.memory_rounded,
                label: 'RAM használat',
                value: '$_freeRAM KB',
                subtitle: 'Szabad / $_totalRAM KB',
                progress: _ramUsagePercent,
                color: AppTheme.primary,
              ),
              _TelemetryCard(
                icon: Icons.thermostat_rounded,
                label: 'CPU hőmérséklet',
                value: '$_cpuTemp°C',
                subtitle: 'Normál',
                progress: _cpuTemp / 100,
                color:
                    _cpuTemp > 70 ? const Color(0xFFEF4444) : AppTheme.primary,
              ),
              _TelemetryCard(
                icon: Icons.schedule_rounded,
                label: 'Uptime',
                value: _uptimeLabel,
                subtitle: 'Utolsó reboot óta',
                progress: null,
                color: AppTheme.primary,
              ),
              _TelemetryCard(
                icon: Icons.info_outline_rounded,
                label: 'IP cím',
                value: _ipAddress,
                subtitle: 'ESP32 hálózati cím',
                progress: null,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Firmware verzió',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _firmwareVersion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Pin status
          const Text(
            'Pin kiosztás és előkapcsolások',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          Container(
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
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
              },
              children: [
                // Header
                TableRow(
                  decoration:
                      const BoxDecoration(color: AppTheme.primarySurface),
                  children: ['Periféria', 'GPIO', 'Státusz']
                      .map(
                        (h) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            h,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Rows
                ..._pins.asMap().entries.map(
                      (e) => TableRow(
                        decoration: BoxDecoration(
                          color: e.key.isOdd
                              ? Colors.white
                              : const Color(0xFFFAFAFA),
                          border: const Border(
                              top: BorderSide(color: AppTheme.border)),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              e.value.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Text(
                              'GPIO${e.value.gpio}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: e.value.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  e.value.status,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: e.value.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Debug log
          const Text(
            'Debug napló (utolsó 16 esemény)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Text(
                _debugLogs.join('\n'),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Color(0xFF10B981),
                  height: 1.6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Control buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reboot,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Újraindítás'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Visszaállítás'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
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

// ── Status Badge ─────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isConnected;
  final int? signal;

  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.isConnected,
    this.signal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Csatlakozva' : 'Lecsatlakozva',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (signal != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$signal%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Telemetry Card ──────────────────────────────────────

class _TelemetryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final double? progress;
  final Color color;

  const _TelemetryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pin Info ────────────────────────────────────────────

class _PinInfo {
  final String name;
  final int gpio;
  final String status;
  final Color color;

  _PinInfo({
    required this.name,
    required this.gpio,
    required this.status,
    required this.color,
  });
}
