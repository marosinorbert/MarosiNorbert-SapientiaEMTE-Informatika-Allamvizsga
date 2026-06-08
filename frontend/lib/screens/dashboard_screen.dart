import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/device_card.dart';
import '../widgets/chart_card.dart';
import '../utils/responsive.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SensorData _data = SensorData.dummy;
  final List<DeviceState> _devices = DeviceState.dummyDevices;

  List<FlSpot> get _tempSpots => List.generate(
        13,
        (i) => FlSpot(
          i.toDouble(),
          20 + (i % 3 == 0 ? 4.5 : i % 3 == 1 ? 3.0 : 5.0),
        ),
      );

  List<FlSpot> get _humiditySpots => List.generate(
        13,
        (i) => FlSpot(
          i.toDouble(),
          58 + (i % 4 == 0 ? 4.0 : i % 4 == 1 ? 2.0 : i % 4 == 2 ? 5.0 : 3.0),
        ),
      );

  @override
Widget build(BuildContext context) {
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
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
                          fontSize: 12,
                          color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // Stat cards
        GridView.count(
          crossAxisCount: ResponsiveHelper.getCrossAxisCount(context, mobile: MediaQuery.of(context).size.width < 380 ? 1 : 2, tablet: 2, desktop: 4),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
childAspectRatio: ResponsiveHelper.isMobile(context) ? 1.25 : 1.5,          children: [
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

        ..._devices
            .asMap()
            .entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DeviceCard(
                    device: e.value,
                    onToggle: () => setState(
                        () => _devices[e.key].isOn = !_devices[e.key].isOn),
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
      spots: _tempSpots,
      lineColor: AppTheme.primary,
      fillColor: AppTheme.primary.withOpacity(0.1),
      minY: 0,
      maxY: 28,
    ),
    ChartCard(
      title: 'Páratartalom',
      spots: _humiditySpots,
      lineColor: const Color(0xFF60A5FA),
      fillColor: const Color(0xFF60A5FA).withOpacity(0.1),
      minY: 0,
      maxY: 80,
    ),
  ],
),

        const SizedBox(height: 28),

           ],
    ),
  );
}
}