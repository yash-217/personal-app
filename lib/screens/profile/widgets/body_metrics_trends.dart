import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/body_metrics.dart';

class BodyMetricsTrends extends StatelessWidget {
  final List<BodyMetrics> metrics;

  const BodyMetricsTrends({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trends', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // Weight Chart
        _buildSingleTrendChart(
          theme,
          title: 'Weight',
          unit: 'kg',
          color: theme.colorScheme.primary,
          data: metrics.map((m) => m.weight).toList(),
          isDashed: false,
        ),
        const SizedBox(height: 12),
        // Body Fat % Chart
        if (metrics.any((m) => m.bodyFatPercentage > 0))
          _buildSingleTrendChart(
            theme,
            title: 'Body Fat',
            unit: '%',
            color: Colors.orange,
            data: metrics.map((m) => m.bodyFatPercentage).toList(),
            isDashed: true,
          ),
        const SizedBox(height: 12),
        // Protein Chart
        if (metrics.any((m) => m.protein > 0))
          _buildSingleTrendChart(
            theme,
            title: 'Protein',
            unit: 'kg',
            color: Colors.blue,
            data: metrics.map((m) => m.protein).toList(),
            isDashed: false,
            isCurved: false, // Dotted/Straight style
          ),
      ],
    );
  }

  Widget _buildSingleTrendChart(
    ThemeData theme, {
    required String title,
    required String unit,
    required Color color,
    required List<double> data,
    bool isDashed = false,
    bool isCurved = true,
  }) {
    final validData = data.where((v) => v > 0).toList();
    if (validData.length < 2) return const SizedBox.shrink();

    final spots = validData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final maxY = validData.reduce((curr, next) => curr > next ? curr : next);
    final minY = validData.reduce((curr, next) => curr < next ? curr : next);
    final interval = (maxY - minY) == 0 ? 1.0 : (maxY - minY) / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title ($unit)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval > 0 ? interval : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == minY || value == maxY) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit',
                            theme.textTheme.labelSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: isCurved,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      dashArray: isDashed ? [5, 5] : null,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: minY * 0.95,
                  maxY: maxY * 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
