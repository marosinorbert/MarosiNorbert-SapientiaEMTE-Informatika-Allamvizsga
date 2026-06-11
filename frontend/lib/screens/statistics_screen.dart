import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

enum TimeRange { daily, weekly, monthly }

class _SensorStats {
  final double min;
  final double max;
  final double avg;

  _SensorStats({required this.min, required this.max, required this.avg});
}

class _DeviceStats {
  final String name;
  final IconData icon;
  final int switchCount;
  final int hoursOn;

  _DeviceStats({
    required this.name,
    required this.icon,
    required this.switchCount,
    required this.hoursOn,
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  TimeRange _timeRange = TimeRange.daily;

  bool _isLoading = true;
  String? _error;

  _SensorStats _tempStats = _SensorStats(min: 0, max: 0, avg: 0);
  _SensorStats _humidityStats = _SensorStats(min: 0, max: 0, avg: 0);
  _SensorStats _soilStats = _SensorStats(min: 0, max: 0, avg: 0);
  _SensorStats _lightStats = _SensorStats(min: 0, max: 0, avg: 0);

  List<FlSpot> _tempSpots = [];

  List<_DeviceStats> get _deviceStats => [
        _DeviceStats(
          name: 'Szellőzés',
          icon: Icons.air_rounded,
          switchCount: _timeRange == TimeRange.daily
              ? 3
              : (_timeRange == TimeRange.weekly ? 18 : 85),
          hoursOn: _timeRange == TimeRange.daily
              ? 8
              : (_timeRange == TimeRange.weekly ? 52 : 220),
        ),
        _DeviceStats(
          name: 'Öntözőrendszer',
          icon: Icons.water_drop_rounded,
          switchCount: _timeRange == TimeRange.daily
              ? 2
              : (_timeRange == TimeRange.weekly ? 12 : 58),
          hoursOn: _timeRange == TimeRange.daily
              ? 1
              : (_timeRange == TimeRange.weekly ? 6 : 26),
        ),
        _DeviceStats(
          name: 'Növénylámpa',
          icon: Icons.light_mode_rounded,
          switchCount: _timeRange == TimeRange.daily
              ? 2
              : (_timeRange == TimeRange.weekly ? 14 : 60),
          hoursOn: _timeRange == TimeRange.daily
              ? 14
              : (_timeRange == TimeRange.weekly ? 98 : 420),
        ),
        _DeviceStats(
          name: 'Fűtés',
          icon: Icons.local_fire_department_rounded,
          switchCount: _timeRange == TimeRange.daily
              ? 0
              : (_timeRange == TimeRange.weekly ? 2 : 8),
          hoursOn: _timeRange == TimeRange.daily
              ? 0
              : (_timeRange == TimeRange.weekly ? 2 : 18),
        ),
      ];

  String _timeRangeLabel(TimeRange tr) {
    switch (tr) {
      case TimeRange.daily:
        return 'Napi (24 óra)';
      case TimeRange.weekly:
        return 'Heti (7 nap)';
      case TimeRange.monthly:
        return 'Havi (30 nap)';
    }
  }

  int _timeRangeValue(TimeRange tr) {
    switch (tr) {
      case TimeRange.daily:
        return 24;
      case TimeRange.weekly:
        return 7;
      case TimeRange.monthly:
        return 30;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<dynamic> history;

      if (_timeRange == TimeRange.daily) {
        history = await ApiService.getSensorHistory(hours: 24);
      } else if (_timeRange == TimeRange.weekly) {
        history = await ApiService.getSensorHistory(days: 7);
      } else {
        history = await ApiService.getSensorHistory(days: 30);
      }

      final temperatures = history
          .map<double>((e) => (e['temperature'] ?? 0).toDouble())
          .toList();

      final humidities =
          history.map<double>((e) => (e['humidity'] ?? 0).toDouble()).toList();

      final soilValues = history
          .map<double>((e) => (e['soilMoisture'] ?? 0).toDouble())
          .toList();

      _SensorStats calculateStats(List<double> values) {
        if (values.isEmpty) {
          return _SensorStats(min: 0, max: 0, avg: 0);
        }

        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        final avg = values.reduce((a, b) => a + b) / values.length;

        return _SensorStats(min: min, max: max, avg: avg);
      }

      final tempSpots = <FlSpot>[];

      for (int i = 0; i < temperatures.length; i++) {
        tempSpots.add(
          FlSpot(i.toDouble(), temperatures[i]),
        );
      }

      setState(() {
        _tempStats = calculateStats(temperatures);
        _humidityStats = calculateStats(humidities);
        _soilStats = calculateStats(soilValues);

        // Fényszenzorod még nincs adatbázisban, ezért egyelőre 0.
        _lightStats = _SensorStats(min: 0, max: 0, avg: 0);

        _tempSpots = tempSpots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Nem sikerült betölteni a statisztikákat: $e';
        _isLoading = false;
      });
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
    final tempStats = _tempStats;
    final humidityStats = _humidityStats;
    final soilStats = _soilStats;
    final lightStats = _lightStats;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Statisztika ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'és elemzés',
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
            'Szenzor adatok és eszköz üzemidő statisztikái',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 20),

          // Time range selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TimeRange.values
                  .map((tr) => Padding(
                        padding: EdgeInsets.only(
                          right: tr == TimeRange.values.last ? 0 : 12,
                        ),
                        child: _TimeRangeButton(
                          label: _timeRangeLabel(tr),
                          isSelected: _timeRange == tr,
                          onTap: () {
                            setState(() => _timeRange = tr);
                            _loadStatistics();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Sensor stats cards
          const Text(
            'Szenzor statisztika',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 700 ? 2 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _StatCard(
                    title: 'Hőmérséklet',
                    icon: Icons.thermostat_rounded,
                    color: AppTheme.primary,
                    min: '${tempStats.min}°C',
                    max: '${tempStats.max}°C',
                    avg: '${tempStats.avg.toStringAsFixed(1)}°C',
                  ),
                  _StatCard(
                    title: 'Páratartalom',
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF60A5FA),
                    min: '${humidityStats.min.toInt()}%',
                    max: '${humidityStats.max.toInt()}%',
                    avg: '${humidityStats.avg.toStringAsFixed(1)}%',
                  ),
                  _StatCard(
                    title: 'Talajnedvesség',
                    icon: Icons.eco_rounded,
                    color: const Color(0xFF8B5CF6),
                    min: '${soilStats.min.toInt()}%',
                    max: '${soilStats.max.toInt()}%',
                    avg: '${soilStats.avg.toStringAsFixed(1)}%',
                  ),
                  _StatCard(
                    title: 'Fényerő',
                    icon: Icons.wb_sunny_rounded,
                    color: const Color(0xFFFCD34D),
                    min: '${lightStats.min.toInt()} lux',
                    max: '${lightStats.max.toInt()} lux',
                    avg: '${lightStats.avg.toInt()} lux',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // Trend chart
          const Text(
            'Hőmérséklet trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _TrendChart(
            spots: _tempSpots.isEmpty ? [const FlSpot(0, 0)] : _tempSpots,
            timeRange: _timeRange,
            lineColor: AppTheme.primary,
            fillColor: AppTheme.primary.withOpacity(0.1),
          ),

          const SizedBox(height: 28),

          // Device stats
          const Text(
            'Eszköz üzemidő',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _DeviceStatsTable(devices: _deviceStats),
        ],
      ),
    );
  }
}

// ── Time Range Button ────────────────────────────────────

class _TimeRangeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeRangeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String min;
  final String max;
  final String avg;

  const _StatCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.min,
    required this.max,
    required this.avg,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Min',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    min,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Átlag',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    avg,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Max',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    max,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trend Chart ──────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final TimeRange timeRange;
  final Color lineColor;
  final Color fillColor;

  const _TrendChart({
    required this.spots,
    required this.timeRange,
    required this.lineColor,
    required this.fillColor,
  });

  String _intervalLabel(TimeRange tr) {
    switch (tr) {
      case TimeRange.daily:
        return 'óra';
      case TimeRange.weekly:
        return 'nap';
      case TimeRange.monthly:
        return 'nap';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(20),
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
          minY: 0,
          maxY: 30,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 6,
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
                interval: 6,
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
                interval: timeRange == TimeRange.daily ? 3 : 1,
                getTitlesWidget: (v, _) {
                  if (timeRange == TimeRange.daily) {
                    return Text(
                      '${(v.toInt()) % 24}:00',
                      style: const TextStyle(
                          fontSize: 10, color: AppTheme.textSecondary),
                    );
                  }
                  return Text(
                    '${v.toInt() + 1}. nap',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
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

// ── Device Stats Table ───────────────────────────────────

class _DeviceStatsTable extends StatelessWidget {
  final List<_DeviceStats> devices;

  const _DeviceStatsTable({required this.devices});

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
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          // Header
          TableRow(
            decoration: const BoxDecoration(color: AppTheme.primarySurface),
            children: ['Eszköz', 'Be/ki kapcsolások', 'Üzemidő (h)']
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
          ...devices.asMap().entries.map(
                (e) => TableRow(
                  decoration: BoxDecoration(
                    color: e.key.isOdd ? Colors.white : Color(0xFFFAFAFA),
                    border:
                        const Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  children: [
                    // Device name
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(e.value.icon, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            e.value.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Switch count
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Text(
                        e.value.switchCount.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    // Hours on
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Text(
                        e.value.hoursOn.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
