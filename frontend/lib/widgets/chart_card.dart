import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color lineColor;
  final Color fillColor;
  final double minY;
  final double maxY;
  final String unit;

  const ChartCard({
    super.key,
    required this.title,
    required this.spots,
    required this.lineColor,
    required this.fillColor,
    required this.minY,
    required this.maxY,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final safeSpots = spots.isEmpty ? [const FlSpot(0, 0)] : spots;

    final dataMinY = safeSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    final dataMaxY = safeSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    final padding = ((dataMaxY - dataMinY).abs() * 0.15).clamp(2.0, 10.0);

    final chartMinY = dataMinY < minY ? dataMinY - padding : minY;
    final chartMaxY = dataMaxY > maxY ? dataMaxY + padding : maxY;

    final yInterval =
        ((chartMaxY - chartMinY) / 4) == 0 ? 1.0 : (chartMaxY - chartMinY) / 4;

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
              const Text(
                'Last 24h',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 175,
            child: LineChart(
              LineChartData(
                minY: chartMinY,
                maxY: chartMaxY,
                minX: 0,
                maxX: 23,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final value = spot.y.toStringAsFixed(1);

                        final hour = spot.x.floor();
                        final minute = ((spot.x - hour) * 60).round();

                        final timeLabel =
                            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                        return LineTooltipItem(
                          '$value$unit / $timeLabel',
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
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF0F0F0),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final hour = value.toInt();

                        if (hour % 2 != 0) {
                          return const SizedBox.shrink();
                        }

                        return Text(
                          hour.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
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
