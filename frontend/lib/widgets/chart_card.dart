import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

enum ChartRange { hours24, days7, days30 }

class ChartCard extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color lineColor;
  final Color fillColor;
  final double minY;
  final double maxY;
  final ChartRange range;

  const ChartCard({
    super.key,
    required this.title,
    required this.spots,
    required this.lineColor,
    required this.fillColor,
    required this.minY,
    required this.maxY,
    this.range = ChartRange.hours24,
  });

  String get _rangeLabel {
    switch (range) {
      case ChartRange.hours24:
        return 'Utolsó 24 óra';
      case ChartRange.days7:
        return 'Utolsó 7 nap';
      case ChartRange.days30:
        return 'Utolsó 30 nap';
    }
  }

  double get _maxX {
    switch (range) {
      case ChartRange.hours24:
        return 24;
      case ChartRange.days7:
        return 7;
      case ChartRange.days30:
        return 30;
    }
  }

  double get _bottomInterval {
    switch (range) {
      case ChartRange.hours24:
        return 6;
      case ChartRange.days7:
        return 1;
      case ChartRange.days30:
        return 5;
    }
  }

  String _bottomLabel(double value) {
    final v = value.toInt();

    switch (range) {
      case ChartRange.hours24:
        if (v == 24) return '';
        return '${v.toString().padLeft(2, '0')}:00';
      case ChartRange.days7:
        if (v == 0) return '';
        return '$v. nap';
      case ChartRange.days30:
        if (v == 0) return '';
        return '$v';
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
          )
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
            height: 175,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: _maxX,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y.toStringAsFixed(1);
                        final x = spot.x.toInt();

                        String timeLabel;

                        switch (range) {
                          case ChartRange.hours24:
                            final hour = spot.x.floor();
                            final minute = ((spot.x - hour) * 60).round();

                            timeLabel =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                            break;
                          case ChartRange.days7:
                            timeLabel = '$x. nap';
                            break;
                          case ChartRange.days30:
                            timeLabel = '$x. nap';
                            break;
                        }

                        return LineTooltipItem(
                          '$value °C / $timeLabel',
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
                minY: chartMinY,
                maxY: chartMaxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval == 0 ? 1 : horizontalInterval,
                  getDrawingHorizontalLine: (value) => const FlLine(
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
                      interval: horizontalInterval == 0 ? 1 : horizontalInterval,
                      reservedSize: 32,
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
                      getTitlesWidget: (value, meta) {
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
