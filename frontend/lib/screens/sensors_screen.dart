import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  bool _isLoading = true;
  String? _error;

  List<_SensorInfo> _sensors = [];

  List<FlSpot> _tempSpots = [];
  List<FlSpot> _soilSpots = [];
  @override
  void initState() {
    super.initState();
    _loadSensorData();
  }

  Future<void> _loadSensorData() async {
    try {
      final latestJson = await ApiService.getLatestSensorData();
      final historyJson = await ApiService.getSensorHistory(
        hours: 24,
      );
      final temperature = (latestJson['temperature'] ?? 0).toDouble();
      final humidity = (latestJson['humidity'] ?? 0).toDouble();
      final soilMoisture = (latestJson['soilMoisture'] ?? 0).toDouble();

      final tempValues = historyJson
          .map<double>((item) => (item['temperature'] ?? 0).toDouble())
          .toList();

      final soilValues = historyJson
          .map<double>((item) => (item['soilMoisture'] ?? 0).toDouble())
          .toList();

      double minValue(List<double> values, double fallback) =>
          values.isEmpty ? fallback : values.reduce((a, b) => a < b ? a : b);

      double maxValue(List<double> values, double fallback) =>
          values.isEmpty ? fallback : values.reduce((a, b) => a > b ? a : b);

      double avgValue(List<double> values, double fallback) => values.isEmpty
          ? fallback
          : values.reduce((a, b) => a + b) / values.length;

      final tempSpots = <FlSpot>[];
      final soilSpots = <FlSpot>[];

      for (int i = 0; i < historyJson.length; i++) {
        final item = historyJson[i];

        tempSpots.add(
          FlSpot(
            i.toDouble(),
            (item['temperature'] ?? 0).toDouble(),
          ),
        );

        soilSpots.add(
          FlSpot(
            i.toDouble(),
            (item['soilMoisture'] ?? 0).toDouble(),
          ),
        );
      }

      setState(() {
        _sensors = [
          _SensorInfo(
            name: 'DHT22 — Hőmérséklet',
            icon: Icons.thermostat_rounded,
            value: '${temperature.toStringAsFixed(1)} °C',
            min: '${minValue(tempValues, temperature).toStringAsFixed(1)} °C',
            max: '${maxValue(tempValues, temperature).toStringAsFixed(1)} °C',
            avg: '${avgValue(tempValues, temperature).toStringAsFixed(1)} °C',
            status: 'online',
            pin: 'GPIO 4',
          ),
          _SensorInfo(
            name: 'DHT22 — Páratartalom',
            icon: Icons.water_drop_rounded,
            value: '${humidity.toStringAsFixed(0)} %',
            min: '-',
            max: '-',
            avg: '-',
            status: 'online',
            pin: 'GPIO 4',
          ),
          _SensorInfo(
            name: 'Talajnedvesség',
            icon: Icons.eco_rounded,
            value: '${soilMoisture.toStringAsFixed(0)} %',
            min: '${minValue(soilValues, soilMoisture).toStringAsFixed(0)} %',
            max: '${maxValue(soilValues, soilMoisture).toStringAsFixed(0)} %',
            avg: '${avgValue(soilValues, soilMoisture).toStringAsFixed(0)} %',
            status: soilMoisture < 35 ? 'warning' : 'online',
            pin: 'GPIO 34',
          ),
          _SensorInfo(
            name: 'Fényszenzor',
            icon: Icons.wb_sunny_rounded,
            value: '0 lux',
            min: '-',
            max: '-',
            avg: '-',
            status: 'offline',
            pin: 'GPIO 21/22',
          ),
        ];

        _tempSpots = tempSpots;
        _soilSpots = soilSpots;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nem sikerült betölteni a szenzoradatokat: $e';
        _isLoading = false;
      });
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
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Szenzor ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'monitor',
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
            'Valós idejű szenzor adatok és státuszok',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Sensor cards grid
          GridView.count(
            crossAxisCount: ResponsiveHelper.getCrossAxisCount(context,
                mobile: 1, tablet: 2, desktop: 2),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ResponsiveHelper.getChildAspectRatio(context,
                mobile: 2.2, tablet: 1.8, desktop: 1.6),
            children: _sensors.map((s) => _SensorCard(sensor: s)).toList(),
          ),

          const SizedBox(height: 24),

          const Text(
            'Hőmérséklet — 24 órás trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildChart(
            spots: _tempSpots.isEmpty ? [const FlSpot(0, 0)] : _tempSpots,
            lineColor: AppTheme.primary,
            fillColor: AppTheme.primary.withOpacity(0.1),
            minY: 0,
            maxY: 30,
          ),

          const SizedBox(height: 24),

          const Text(
            'Talajnedvesség — 24 órás trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _buildChart(
            spots: _soilSpots.isEmpty ? [const FlSpot(0, 0)] : _soilSpots,
            lineColor: const Color(0xFF8B5CF6),
            fillColor: const Color(0xFF8B5CF6).withOpacity(0.1),
            minY: 0,
            maxY: 80,
          ),

          const SizedBox(height: 24),

          const Text(
            'ESP32 Pin kiosztás',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _PinTable(),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  static Widget _buildChart({
    required List<FlSpot> spots,
    required Color lineColor,
    required Color fillColor,
    required double minY,
    required double maxY,
  }) {
    final safeSpots = spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    final dataMinY = safeSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final dataMaxY = safeSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    final chartMinY = ((dataMinY < minY ? dataMinY : minY) - 5).floorToDouble();

    final chartMaxY = ((dataMaxY > maxY ? dataMaxY : maxY) + 5).ceilToDouble();

    final double chartInterval =
        (chartMaxY - chartMinY) == 0 ? 1.0 : (chartMaxY - chartMinY) / 4.0;

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
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
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24,
          minY: chartMinY,
          maxY: chartMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: chartInterval,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFF0F0F0), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: chartInterval,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6.0,
                reservedSize: 30,
                getTitlesWidget: (v, _) {
                  final hour = v.toInt();

                  if (hour < 0 || hour > 24) {
                    return const SizedBox.shrink();
                  }

                  if (hour == 24) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: safeSpots,
              isCurved: true,
              color: lineColor,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: fillColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorInfo {
  final String name;
  final IconData icon;
  final String value;
  final String min;
  final String max;
  final String avg;
  final String status;
  final String pin;

  const _SensorInfo({
    required this.name,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.avg,
    required this.status,
    required this.pin,
  });
}

class _SensorCard extends StatelessWidget {
  final _SensorInfo sensor;
  const _SensorCard({required this.sensor});

  Color get _statusColor {
    switch (sensor.status) {
      case 'online':
        return AppTheme.primary;
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEF4444);
    }
  }

  String get _statusLabel {
    switch (sensor.status) {
      case 'online':
        return 'Online';
      case 'warning':
        return 'Figyelmeztetés';
      default:
        return 'Offline';
    }
  }

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(sensor.icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sensor.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sensor.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _StatPill(label: 'Min', value: sensor.min),
              _StatPill(label: 'Max', value: sensor.max),
              _StatPill(label: 'Átlag', value: sensor.avg),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pin: ${sensor.pin}',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primarySurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTable extends StatelessWidget {
  final List<List<String>> _rows = const [
    ['DHT22 (Data)', 'GPIO 4', 'Hőmérséklet + Páratartalom'],
    ['Talajnedvesség', 'GPIO 34', 'Analóg bemenet (ADC)'],
    ['BH1750 (SDA)', 'GPIO 21', 'I2C adatvonal'],
    ['BH1750 (SCL)', 'GPIO 22', 'I2C órajel'],
    ['Relé — Szellőzés', 'GPIO 26', 'Digitális kimenet'],
    ['Relé — Öntözés', 'GPIO 27', 'Digitális kimenet'],
    ['Relé — Lámpa', 'GPIO 14', 'Digitális kimenet'],
    ['Relé — Fűtés', 'GPIO 12', 'Digitális kimenet'],
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(180),
            1: FixedColumnWidth(90),
            2: FixedColumnWidth(180),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppTheme.primarySurface),
              children: ['Szenzor / Eszköz', 'Pin', 'Leírás']
                  .map(
                    (h) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            ..._rows.asMap().entries.map(
                  (e) => TableRow(
                    decoration: BoxDecoration(
                      color:
                          e.key.isOdd ? Colors.white : const Color(0xFFFAFAFA),
                      border:
                          const Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    children: e.value
                        .asMap()
                        .entries
                        .map(
                          (cell) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Text(
                              cell.value,
                              style: TextStyle(
                                fontSize: 12,
                                color: cell.key == 1
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary,
                                fontFamily: cell.key == 1 ? 'monospace' : null,
                                fontWeight: cell.key == 1
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
