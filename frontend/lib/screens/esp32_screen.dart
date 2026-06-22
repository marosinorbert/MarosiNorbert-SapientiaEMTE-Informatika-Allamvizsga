import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class Esp32Screen extends StatefulWidget {
  const Esp32Screen({super.key});

  @override
  State<Esp32Screen> createState() => _Esp32ScreenState();
}

class _Esp32ScreenState extends State<Esp32Screen> {
  bool _isOnline = false;
  int _signalStrength = 0;
  bool _wifiConnected = false;
  bool _mqttConnected = false;

  int _freeRAM = 0;
  int _totalRAM = 0;
  int _cpuTemp = 0;
  int _uptimeSeconds = 0;

  bool _isLoading = true;
  String? _error;
  bool _hasNoDevice = false;
  String _ipAddress = '-';
  String _firmwareVersion = '-';
  String _lastSeen = '-';

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

    if (days > 0) return '$days nap $hours óra';
    if (hours > 0) return '$hours óra $minutes perc';
    return '$minutes perc';
  }

  String _formatLastSeen(dynamic value) {
    final text = value?.toString();

    if (text == null || text.isEmpty || text == 'null') {
      return '-';
    }

    final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));

    if (parsed == null) {
      return text;
    }

    final year = parsed.year.toString();
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$year.$month.$day $hour:$minute';
  }

  @override
  void initState() {
    super.initState();
    _loadEsp32Status(showLoading: true);
  }

  Future<void> _loadEsp32Status({bool showLoading = false}) async {
    try {
      if (showLoading && mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final hasDevice = await ApiService.hasClaimedDevice();

      if (!mounted) return;

      if (!hasDevice) {
        setState(() {
          _hasNoDevice = true;
          _isOnline = false;
          _wifiConnected = false;
          _mqttConnected = false;
          _signalStrength = 0;
          _freeRAM = 0;
          _totalRAM = 0;
          _cpuTemp = 0;
          _uptimeSeconds = 0;
          _ipAddress = '-';
          _firmwareVersion = '-';
          _lastSeen = '-';
          _isLoading = false;
          _error = null;
        });
        return;
      }

      final status = await ApiService.getEsp32Status();

      if (!mounted) return;

      setState(() {
        _hasNoDevice = false;
        _error = null;

        _isOnline = status['isOnline'] ?? false;
        _wifiConnected = status['wifiConnected'] ?? false;
        _mqttConnected = status['mqttConnected'] ?? false;
        _signalStrength = _toInt(status['signalStrength'], 0);
        _freeRAM = _toInt(status['freeRam'], 0);
        _totalRAM = _toInt(status['totalRam'], 0);
        _cpuTemp = _toInt(status['cpuTemp'], 0);
        _uptimeSeconds = _toInt(status['uptimeSeconds'], 0);
        _ipAddress = status['ipAddress']?.toString() ?? '-';
        _firmwareVersion = status['firmwareVersion']?.toString() ?? '-';
        _lastSeen = _formatLastSeen(status['lastSeen']);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Nem sikerült betölteni az ESP32 státuszt: $e';
        _isLoading = false;
        _hasNoDevice = false;
      });
    }
  }

  String get _uptimeLabel => _formatUptime(_uptimeSeconds);

  double get _ramUsagePercent {
    if (_totalRAM <= 0) return 0;
    return ((_totalRAM - _freeRAM) / _totalRAM).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasNoDevice) {
      return _NoDeviceEsp32Card(
        onRefresh: () => _loadEsp32Status(showLoading: true),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      );
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
              _TelemetryCard(
                icon: Icons.access_time_rounded,
                label: 'Utolsó kapcsolat',
                value: _lastSeen,
                subtitle: 'Adatbázis szerinti idő',
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
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _NoDeviceEsp32Card extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NoDeviceEsp32Card({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  color: AppTheme.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nincs ESP32 hozzárendelve',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ehhez a fiókhoz még nincs ESP32 eszköz kapcsolva. '
                'A mikrovezérlő státuszának megjelenítéséhez először menj a '
                'Beállítások oldalra, és add meg az ESP32 claim kódját.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Újraellenőrzés'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
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
              Icon(icon, size: 16, color: const Color.fromARGB(255, 2, 56, 4)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 2, 56, 4),
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
                      ? const Color.fromARGB(255, 2, 56, 4)
                      : const Color.fromARGB(255, 2, 56, 4).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'Csatlakozva' : 'Lecsatlakozva',
                style: TextStyle(
                  fontSize: 11,
                  color: Color.fromARGB(255, 2, 56, 4).withOpacity(isConnected ? 1 : 0.5),
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