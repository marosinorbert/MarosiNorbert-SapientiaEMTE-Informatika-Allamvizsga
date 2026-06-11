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

class _DashboardScreenState extends State<DashboardScreen> {
  SensorData _data = SensorData.dummy;
  final List<DeviceState> _devices = DeviceState.dummyDevices;

  bool _isLoading = true;
  String? _error;

  List<FlSpot> _tempSpots = [];
  List<FlSpot> _humiditySpots = [];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSensorData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadSensorData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSensorData() async {
    try {
      final latestJson = await ApiService.getLatestSensorData();
      final historyJson = await ApiService.getSensorHistory(
        hours: 24,
      );
      final devicesJson = await ApiService.getDevices();

      final tempSpots = <FlSpot>[];
      final humiditySpots = <FlSpot>[];

      for (int i = 0; i < historyJson.length; i++) {
        final item = historyJson[i];

        tempSpots.add(
          FlSpot(
            i.toDouble(),
            (item['temperature'] ?? 0).toDouble(),
          ),
        );

        humiditySpots.add(
          FlSpot(
            i.toDouble(),
            (item['humidity'] ?? 0).toDouble(),
          ),
        );
      }

      for (final deviceJson in devicesJson) {
        final deviceName = deviceJson['device_name'];
        final isOn = deviceJson['is_on'];
        final isAuto = deviceJson['is_auto'];

        if (deviceName == 'pump') {
          _devices.firstWhere((d) => d.name == 'Öntözőrendszer').isOn = isOn;
          _devices.firstWhere((d) => d.name == 'Öntözőrendszer').isAuto =
              isAuto;
        }

        if (deviceName == 'light') {
          _devices.firstWhere((d) => d.name == 'Növénylámpa').isOn = isOn;
          _devices.firstWhere((d) => d.name == 'Növénylámpa').isAuto = isAuto;
        }

        if (deviceName == 'fan') {
          _devices.firstWhere((d) => d.name == 'Szellőzés').isOn = isOn;
          _devices.firstWhere((d) => d.name == 'Szellőzés').isAuto = isAuto;
        }

        if (deviceName == 'heater') {
          _devices.firstWhere((d) => d.name == 'Fűtés').isOn = isOn;
          _devices.firstWhere((d) => d.name == 'Fűtés').isAuto = isAuto;
        }
      }

      setState(() {
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
      setState(() {
        _error = 'Nem sikerült betölteni az adatokat: $e';
        _isLoading = false;
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

    if (_error != null) {
      return Center(
        child: Text(_error!),
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
                subtitle: 'Cél: 18° - 28°',
                icon: Icons.thermostat_rounded,
              ),
              StatCard(
                title: 'Páratartalom',
                value: '${_data.humidity.toInt()}',
                unit: '%',
                subtitle: 'Cél: 50% - 75%',
                icon: Icons.water_drop_rounded,
              ),
              StatCard(
                title: 'Talajnedvesség',
                value: '${_data.soilMoisture.toInt()}',
                unit: '%',
                subtitle: 'Min: 35%',
                icon: Icons.eco_rounded,
              ),
              StatCard(
                title: 'Fényerősség',
                value: '${_data.lightIntensity.toInt()}',
                unit: 'lux',
                subtitle: 'Optimális tartomány',
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
              ),
            ],
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
