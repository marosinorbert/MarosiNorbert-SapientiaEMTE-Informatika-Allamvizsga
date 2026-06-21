import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

enum TimeRange { daily, weekly, monthly }

class _SensorStats {
  final double min;
  final double max;
  final double avg;

  _SensorStats({required this.min, required this.max, required this.avg});
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
  bool _hasNoDevice = false;
  bool _isExporting = false;

  _SensorStats _tempStats = _SensorStats(min: 0, max: 0, avg: 0);
  _SensorStats _humidityStats = _SensorStats(min: 0, max: 0, avg: 0);
  _SensorStats _soilStats = _SensorStats(min: 0, max: 0, avg: 0);
  _SensorStats _lightStats = _SensorStats(min: 0, max: 0, avg: 0);

  List<FlSpot> _tempSpots = [];
  List<FlSpot> _humiditySpots = [];
  List<FlSpot> _soilSpots = [];
  List<FlSpot> _lightSpots = [];

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

  double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  DateTime _rangeStart() {
    final now = DateTime.now();

    switch (_timeRange) {
      case TimeRange.daily:
        return now.subtract(const Duration(hours: 24));
      case TimeRange.weekly:
        return now.subtract(const Duration(days: 7));
      case TimeRange.monthly:
        return now.subtract(const Duration(days: 30));
    }
  }

  double _xFromCreatedAt(dynamic value, DateTime start) {
    final text = value?.toString();

    if (text == null || text.isEmpty) return 0;

    final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));

    if (parsed == null) return 0;

    final diffMinutes = parsed.difference(start).inMinutes;

    return diffMinutes / 1440;
  }

  List<FlSpot> _buildTrendSpots({
    required List<dynamic> history,
    required DateTime start,
    required double Function(Map<String, dynamic> item) valueGetter,
  }) {
    final spots = <FlSpot>[];

    for (final rawItem in history) {
      final item = rawItem as Map<String, dynamic>;

      final createdAt =
          item['createdAtFormatted'] ?? item['createdAt'] ?? item['created_at'];

      final x = _timeRange == TimeRange.daily
          ? localHourFromCreatedAt(createdAt)
          : _xFromCreatedAt(createdAt, start);

      final y = valueGetter(item);

      spots.add(FlSpot(x, y));
    }

    spots.sort((a, b) => a.x.compareTo(b.x));

    return spots;
  }

  double localHourFromCreatedAt(dynamic value) {
    final text = value?.toString();

    if (text == null || text.isEmpty) return 0;

    final parsed = DateTime.tryParse(text.replaceFirst(' ', 'T'));

    if (parsed == null) return 0;

    return parsed.hour + (parsed.minute / 60.0);
  }

  @override
  void initState() {
    super.initState();
    _loadStatistics(showLoading: true);
  }

  Future<void> _loadStatistics({bool showLoading = false}) async {
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

          _tempStats = _SensorStats(min: 0, max: 0, avg: 0);
          _humidityStats = _SensorStats(min: 0, max: 0, avg: 0);
          _soilStats = _SensorStats(min: 0, max: 0, avg: 0);
          _lightStats = _SensorStats(min: 0, max: 0, avg: 0);

          _tempSpots = [];
          _humiditySpots = [];
          _soilSpots = [];
          _lightSpots = [];
        });
        return;
      }

      List<dynamic> history;

      if (_timeRange == TimeRange.daily) {
        history = await ApiService.getSensorHistory(hours: 24);
      } else if (_timeRange == TimeRange.weekly) {
        history = await ApiService.getSensorHistory(days: 7);
      } else {
        history = await ApiService.getSensorHistory(days: 30);
      }

      final rangeStart = _rangeStart();

      final temperatures =
          history.map<double>((e) => _toDouble(e['temperature'], 0)).toList();

      final humidities =
          history.map<double>((e) => _toDouble(e['humidity'], 0)).toList();

      final soilValues =
          history.map<double>((e) => _toDouble(e['soilMoisture'], 0)).toList();

      final lightValues = history
          .map<double>(
            (e) => _toDouble(
              e['lightIntensity'] ?? e['light_intensity'] ?? e['light'],
              0,
            ),
          )
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

      final tempSpots = _buildTrendSpots(
        history: history,
        start: rangeStart,
        valueGetter: (item) => _toDouble(item['temperature'], 0),
      );

      final humiditySpots = _buildTrendSpots(
        history: history,
        start: rangeStart,
        valueGetter: (item) => _toDouble(item['humidity'], 0),
      );

      final soilSpots = _buildTrendSpots(
        history: history,
        start: rangeStart,
        valueGetter: (item) => _toDouble(item['soilMoisture'], 0),
      );

      final lightSpots = _buildTrendSpots(
        history: history,
        start: rangeStart,
        valueGetter: (item) => _toDouble(
          item['lightIntensity'] ?? item['light_intensity'] ?? item['light'],
          0,
        ),
      );

      if (!mounted) return;

      setState(() {
        _hasNoDevice = false;
        _error = null;

        _tempStats = calculateStats(temperatures);
        _humidityStats = calculateStats(humidities);
        _soilStats = calculateStats(soilValues);
        _lightStats = calculateStats(lightValues);

        _tempSpots = tempSpots;
        _humiditySpots = humiditySpots;
        _soilSpots = soilSpots;
        _lightSpots = lightSpots;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Nem sikerült betölteni a statisztikákat: $e';
        _isLoading = false;
        _hasNoDevice = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    try {
      setState(() {
        _isExporting = true;
      });

      final hasDevice = await ApiService.hasClaimedDevice();

      if (!mounted) return;

      if (!hasDevice) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'CSV exporthoz először hozzá kell rendelni egy ESP32 eszközt.',
            ),
          ),
        );
        return;
      }

      final csv = await ApiService.exportSensorDataCsv(
        today: _timeRange == TimeRange.daily,
        days: _timeRange == TimeRange.weekly
            ? 7
            : _timeRange == TimeRange.monthly
                ? 30
                : null,
      );

      await Clipboard.setData(
        ClipboardData(text: csv),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _timeRange == TimeRange.daily
                ? 'A mai szenzoradatok CSV formátumban a vágólapra kerültek.'
                : 'A szenzoradatok CSV formátumban a vágólapra kerültek.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nem sikerült exportálni: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasNoDevice) {
      return _NoDeviceStatisticsCard(
        onRefresh: () => _loadStatistics(showLoading: true),
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
            'Szenzor adatok és környezeti értékek statisztikái',
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
                            _loadStatistics(showLoading: true);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isExporting ? null : _exportCsv,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                _isExporting ? 'Exportálás...' : 'CSV export vágólapra',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                childAspectRatio: cols == 1 ? 2.45 : 2.2,
                children: [
                  _StatCard(
                    title: 'Hőmérséklet',
                    icon: Icons.thermostat_rounded,
                    color: AppTheme.primary,
                    min: '${tempStats.min.toStringAsFixed(1)}°C',
                    max: '${tempStats.max.toStringAsFixed(1)}°C',
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
                    min: '${lightStats.min.toInt()} %',
                    max: '${lightStats.max.toInt()} %',
                    avg: '${lightStats.avg.toInt()} %',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          const Text(
            'Trendek',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          _TrendChart(
            title: 'Hőmérséklet trend',
            spots: _tempSpots,
            timeRange: _timeRange,
            lineColor: AppTheme.primary,
            fillColor: AppTheme.primary.withOpacity(0.1),
            unit: '°C',
            minY: 0,
            maxY: 35,
          ),

          const SizedBox(height: 18),

          _TrendChart(
            title: 'Páratartalom trend',
            spots: _humiditySpots,
            timeRange: _timeRange,
            lineColor: const Color(0xFF60A5FA),
            fillColor: const Color(0xFF60A5FA).withOpacity(0.1),
            unit: '%',
            minY: 0,
            maxY: 100,
          ),

          const SizedBox(height: 18),

          _TrendChart(
            title: 'Talajnedvesség trend',
            spots: _soilSpots,
            timeRange: _timeRange,
            lineColor: const Color(0xFF8B5CF6),
            fillColor: const Color(0xFF8B5CF6).withOpacity(0.1),
            unit: '%',
            minY: 0,
            maxY: 100,
          ),

          const SizedBox(height: 18),

          _TrendChart(
            title: 'Fényerő trend',
            spots: _lightSpots,
            timeRange: _timeRange,
            lineColor: const Color(0xFFF59E0B),
            fillColor: const Color(0xFFF59E0B).withOpacity(0.1),
            unit: '%',
            minY: 0,
            maxY: 100,
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _NoDeviceStatisticsCard extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NoDeviceStatisticsCard({
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
                  Icons.query_stats_rounded,
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
                'A statisztikák megjelenítéséhez először rendelj hozzá '
                'egy ESP32 eszközt a Beállítások oldalon. Ezután a rendszer '
                'a saját szenzoradataidból számolja a napi, heti és havi értékeket.',
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

class _TrendChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final TimeRange timeRange;
  final Color lineColor;
  final Color fillColor;
  final String unit;
  final double minY;
  final double maxY;

  const _TrendChart({
    required this.title,
    required this.spots,
    required this.timeRange,
    required this.lineColor,
    required this.fillColor,
    required this.unit,
    required this.minY,
    required this.maxY,
  });

  String get _rangeLabel {
    switch (timeRange) {
      case TimeRange.daily:
        return 'Utolsó 24 óra';
      case TimeRange.weekly:
        return 'Utolsó 7 nap';
      case TimeRange.monthly:
        return 'Utolsó 30 nap';
    }
  }

  double get _maxX {
    switch (timeRange) {
      case TimeRange.daily:
        return 24;
      case TimeRange.weekly:
        return 7;
      case TimeRange.monthly:
        return 30;
    }
  }

  double get _bottomInterval {
    switch (timeRange) {
      case TimeRange.daily:
        return 6;
      case TimeRange.weekly:
        return 1;
      case TimeRange.monthly:
        return 5;
    }
  }

  String _bottomLabel(double value) {
    final v = value.toInt();

    switch (timeRange) {
      case TimeRange.daily:
        if (v == 24) return '';
        return '${v.toString().padLeft(2, '0')}:00';
      case TimeRange.weekly:
        if (v == 0) return '';
        return '$v. nap';
      case TimeRange.monthly:
        if (v == 0) return '';
        return '$v';
    }
  }

  String _tooltipTime(double x) {
    switch (timeRange) {
      case TimeRange.daily:
        final hour = x.floor();
        final minute = ((x - hour) * 60).round();

        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

      case TimeRange.weekly:
        return '${x.toStringAsFixed(1)}. nap';

      case TimeRange.monthly:
        return '${x.toStringAsFixed(1)}. nap';
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeSpots = spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    final dataMinY = safeSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final dataMaxY = safeSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    final chartMinY = dataMinY < minY ? dataMinY - 5 : minY;
    final chartMaxY = dataMaxY > maxY ? dataMaxY + 5 : maxY;

    final horizontalInterval = (chartMaxY - chartMinY) / 4;

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
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _rangeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: _maxX,
                minY: chartMinY,
                maxY: chartMaxY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y.toStringAsFixed(1);
                        final time = _tooltipTime(spot.x);

                        return LineTooltipItem(
                          '$value $unit / $time',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      horizontalInterval == 0 ? 1 : horizontalInterval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFF0F0F0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval:
                          horizontalInterval == 0 ? 1 : horizontalInterval,
                      reservedSize: 34,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _bottomInterval,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) {
                        final label = _bottomLabel(value);

                        if (label.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
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
                    belowBarData: BarAreaData(
                      show: true,
                      color: fillColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
