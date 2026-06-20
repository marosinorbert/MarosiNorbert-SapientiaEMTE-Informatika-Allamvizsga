import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/device_card.dart';
import '../widgets/chart_card.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _NoDeviceDashboardCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NoDeviceDashboardCard({
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
                  Icons.sensors_rounded,
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
                'A szenzoradatok, grafikonok és eszközvezérlés megjelenítéséhez '
                'először rendelj hozzá egy ESP32 eszközt a Beállítások oldalon.',
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

class _DashboardScreenState extends State<DashboardScreen> {
  double _tempMin = 18;
  double _tempMax = 28;
  double _humidityMin = 50;
  double _humidityMax = 75;
  double _soilMin = 35;
  double _soilMax = 80;
  double _lightMin = 800;
  double _lightMax = 3000;

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  double _hourFromCreatedAt(dynamic value) {
    if (value == null) return 0;

    final dateTime = DateTime.tryParse(value.toString());
    if (dateTime == null) return 0;

    final localTime = dateTime.toLocal();

    return localTime.hour + (localTime.minute / 60.0);
  }

  SensorData _data = SensorData.dummy;
  final List<DeviceState> _devices = DeviceState.dummyDevices;

  bool _isLoading = true;
  String? _error;
  bool _hasNoDevice = false;

  List<FlSpot> _tempSpots = [];
  List<FlSpot> _humiditySpots = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSensorData(showLoading: true);

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (mounted) {
          _loadSensorData();
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSensorData({bool showLoading = false}) async {
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
          _isLoading = false;
          _error = null;
          _tempSpots = [];
          _humiditySpots = [];
        });
        return;
      }

      final latestJson = await ApiService.getLatestSensorData();
      final historyJson = await ApiService.getSensorHistory(today: true);
      final devicesJson = await ApiService.getDevices();
      final settingsJson = await ApiService.getSettings();

      final tempSpots = <FlSpot>[];
      final humiditySpots = <FlSpot>[];

      for (final item in historyJson) {
        final hour = _hourFromCreatedAt(item['createdAt']);

        tempSpots.add(
          FlSpot(
            hour,
            (item['temperature'] ?? 0).toDouble(),
          ),
        );

        humiditySpots.add(
          FlSpot(
            hour,
            (item['humidity'] ?? 0).toDouble(),
          ),
        );
      }

      for (final deviceJson in devicesJson) {
        final deviceName = deviceJson['device_name'];
        final isOn = deviceJson['is_on'] ?? false;
        final isAuto = deviceJson['is_auto'] ?? false;

        if (deviceName == 'pump') {
          final device = _devices.firstWhere((d) => d.name == 'Öntözőrendszer');
          device.isOn = isOn;
          device.isAuto = isAuto;
        }

        if (deviceName == 'light') {
          final device = _devices.firstWhere((d) => d.name == 'Növénylámpa');
          device.isOn = isOn;
          device.isAuto = isAuto;
        }

        if (deviceName == 'fan') {
          final device = _devices.firstWhere((d) => d.name == 'Szellőzés');
          device.isOn = isOn;
          device.isAuto = isAuto;
        }

        if (deviceName == 'heater') {
          final device = _devices.firstWhere((d) => d.name == 'Fűtés');
          device.isOn = isOn;
          device.isAuto = isAuto;
        }
      }

      if (!mounted) return;

      setState(() {
        _hasNoDevice = false;
        _error = null;

        _tempMin = _toDouble(settingsJson['temp_min'], 18);
        _tempMax = _toDouble(settingsJson['temp_max'], 28);

        _humidityMin = _toDouble(settingsJson['humidity_min'], 50);
        _humidityMax = _toDouble(settingsJson['humidity_max'], 75);

        _soilMin = _toDouble(settingsJson['soil_min'], 35);
        _soilMax = _toDouble(settingsJson['soil_max'], 80);

        _lightMin = _toDouble(settingsJson['light_min'], 800);
        _lightMax = _toDouble(settingsJson['light_max'], 3000);

        _data = SensorData(
          temperature: (latestJson['temperature'] ?? 0).toDouble(),
          humidity: (latestJson['humidity'] ?? 0).toDouble(),
          soilMoisture: (latestJson['soilMoisture'] ?? 0).toDouble(),
          lightIntensity: 0,
          lastUpdated: latestJson['createdAt'] ?? 'Most',
        );

        _tempSpots = tempSpots;
        _humiditySpots = humiditySpots;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Nem sikerült betölteni az adatokat: $e';
        _isLoading = false;
        _hasNoDevice = false;
      });
    }
  }

  Future<void> _toggleDevice(int index) async {
    final device = _devices[index];

    String apiDeviceName;

    switch (device.name) {
      case 'Öntözőrendszer':
        apiDeviceName = 'pump';
        break;
      case 'Növénylámpa':
        apiDeviceName = 'light';
        break;
      case 'Szellőzés':
        apiDeviceName = 'fan';
        break;
      case 'Fűtés':
        apiDeviceName = 'heater';
        break;
      default:
        return;
    }

    final newValue = !device.isOn;

    setState(() {
      _devices[index].isOn = newValue;
    });

    try {
      await ApiService.toggleDevice(apiDeviceName, newValue);
    } catch (e) {
      setState(() {
        _devices[index].isOn = !newValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nem sikerült kapcsolni: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasNoDevice) {
      return _NoDeviceDashboardCard(
        onRefresh: () => _loadSensorData(showLoading: true),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Üvegház ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: 'vezérlés',
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
                      'Figyelje és irányítsa a növekedési környezetet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!ResponsiveHelper.isMobile(context))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _data.lastUpdated,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Stat cards
          GridView.count(
            crossAxisCount: ResponsiveHelper.getCrossAxisCount(context,
                mobile: MediaQuery.of(context).size.width < 380 ? 1 : 2,
                tablet: 2,
                desktop: 4),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.25 : 1.5,
            children: [
              StatCard(
                title: 'Hőmérséklet',
                value: '${_data.temperature}',
                unit: '°C',
                subtitle: 'Cél: ${_tempMin.toInt()}° - ${_tempMax.toInt()}°',
                icon: Icons.thermostat_rounded,
              ),
              StatCard(
                title: 'Páratartalom',
                value: '${_data.humidity.toInt()}',
                unit: '%',
                subtitle:
                    'Cél: ${_humidityMin.toInt()}% - ${_humidityMax.toInt()}%',
                icon: Icons.water_drop_rounded,
              ),
              StatCard(
                title: 'Talajnedvesség',
                value: '${_data.soilMoisture.toInt()}',
                unit: '%',
                subtitle: 'Cél: ${_soilMin.toInt()}% - ${_soilMax.toInt()}%',
                icon: Icons.eco_rounded,
              ),
              StatCard(
                title: 'Fényerősség',
                value: '${_data.lightIntensity.toInt()}',
                unit: 'lux',
                subtitle:
                    'Cél: ${_lightMin.toInt()} - ${_lightMax.toInt()} lux',
                icon: Icons.wb_sunny_rounded,
              ),
            ],
          ),

          const SizedBox(height: 24),

          const Text(
            'Eszközvezérlés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          ..._devices.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeviceCard(
                  device: e.value,
                  onToggle: () => _toggleDevice(e.key),
                ),
              )),

          const SizedBox(height: 24),

          // Charts
          // Charts
          GridView.count(
            crossAxisCount: ResponsiveHelper.getCrossAxisCount(
              context,
              tablet: 1,
              desktop: 2,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.2 : 1.5,
            children: [
              ChartCard(
                title: 'Hőmérséklet',
                spots: _tempSpots.isEmpty ? [const FlSpot(0, 0)] : _tempSpots,
                lineColor: AppTheme.primary,
                fillColor: AppTheme.primary.withOpacity(0.1),
                minY: 0,
                maxY: 40,
                unit: '°C',
              ),
              ChartCard(
                title: 'Páratartalom',
                spots: _humiditySpots.isEmpty
                    ? [const FlSpot(0, 0)]
                    : _humiditySpots,
                lineColor: const Color(0xFF60A5FA),
                fillColor: const Color(0xFF60A5FA).withOpacity(0.1),
                minY: 0,
                maxY: 100,
                unit: '%',
              ),
            ],
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
