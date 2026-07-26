import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../providers/workout_provider.dart';

class PlankPushupTrends extends StatefulWidget {
  const PlankPushupTrends({super.key});

  @override
  State<PlankPushupTrends> createState() => _PlankPushupTrendsState();
}

class _PlankPushupTrendsState extends State<PlankPushupTrends> {
  int _days = 7; // 7 or 30

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();

    final plankData = workout.plankHistory(_days);
    final pushupData = workout.pushupHistory(_days);

    final hasPlankData = plankData.any((d) => d.seconds > 0);
    final hasPushupData = pushupData.any((d) => d.count > 0);

    if (!hasPlankData && !hasPushupData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Plank & Pushups',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SegmentedButton<int>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(value: 7, label: Text('7d')),
                  ButtonSegment(value: 30, label: Text('30d')),
                ],
                selected: {_days},
                onSelectionChanged: (s) => setState(() => _days = s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (hasPlankData)
          _buildChart(
            theme,
            title: '🧘 Plank Hold',
            unit: 's',
            data: plankData.map((d) => (date: d.date, value: d.seconds.toDouble())).toList(),
            color: Colors.deepPurple,
          ),
        if (hasPushupData)
          _buildChart(
            theme,
            title: '💪 Pushups',
            unit: 'reps',
            data: pushupData.map((d) => (date: d.date, value: d.count.toDouble())).toList(),
            color: Colors.orange,
          ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildChart(
    ThemeData theme, {
    required String title,
    required String unit,
    required List<({DateTime date, double value})> data,
    required Color color,
  }) {
    final maxVal = data.map((d) => d.value).fold(0.0, (a, b) => a > b ? a : b);
    final topBound = maxVal > 0 ? (maxVal * 1.3).ceilToDouble() : 10.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Show latest value
                if (data.isNotEmpty && data.last.value > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${data.last.value.toInt()} $unit',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: topBound,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = data[group.x.toInt()];
                        final dateLabel = DateFormat('d MMM').format(d.date);
                        return BarTooltipItem(
                          '$dateLabel\n${d.value.toInt()} $unit',
                          TextStyle(
                            color: theme.colorScheme.onInverseSurface,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) {
                          if (val == 0) return const SizedBox.shrink();
                          return Text(
                            '${val.toInt()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                          // Show label for every Nth bar to avoid crowding
                          final interval = _days <= 7 ? 1 : 5;
                          if (idx % interval != 0 && idx != data.length - 1) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d/M').format(data[idx].date),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: topBound / 4,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: d.value,
                          color: d.value > 0 ? color : color.withValues(alpha: 0.15),
                          width: _days <= 7 ? 16 : 6,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
