import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../providers/workout_provider.dart';

enum TrendViewMode {
  sevenDays('7d'),
  thirtyDays('30d'),
  progress('Progress');

  final String label;
  const TrendViewMode(this.label);
}

class PlankPushupTrends extends StatefulWidget {
  const PlankPushupTrends({super.key});

  @override
  State<PlankPushupTrends> createState() => _PlankPushupTrendsState();
}

class _PlankPushupTrendsState extends State<PlankPushupTrends> {
  TrendViewMode _viewMode = TrendViewMode.sevenDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();

    final allPlanks = workout.allPlankEntries();
    final allPushups = workout.allPushupEntries();

    final hasPlankData = allPlanks.isNotEmpty;
    final hasPushupData = allPushups.isNotEmpty;

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
              SegmentedButton<TrendViewMode>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                segments: const [
                  ButtonSegment(
                    value: TrendViewMode.sevenDays,
                    label: Text('7d', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: TrendViewMode.thirtyDays,
                    label: Text('30d', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: TrendViewMode.progress,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart_rounded, size: 14),
                        SizedBox(width: 4),
                        Text('Progress', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                selected: {_viewMode},
                onSelectionChanged: (s) => setState(() => _viewMode = s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (hasPlankData)
          _buildExerciseCard(
            theme,
            title: '🧘 Plank Hold',
            unit: 's',
            color: Colors.deepPurple,
            selectedView: _viewMode,
            sevenDayData: workout.plankHistory(7).map((d) => (date: d.date, value: d.seconds.toDouble())).toList(),
            thirtyDayData: workout.plankHistory(30).map((d) => (date: d.date, value: d.seconds.toDouble())).toList(),
            allEntriesData: allPlanks.map((d) => (date: d.date, value: d.seconds.toDouble())).toList(),
          ),
        if (hasPushupData)
          _buildExerciseCard(
            theme,
            title: '💪 Pushups',
            unit: 'reps',
            color: Colors.orange,
            selectedView: _viewMode,
            sevenDayData: workout.pushupHistory(7).map((d) => (date: d.date, value: d.count.toDouble())).toList(),
            thirtyDayData: workout.pushupHistory(30).map((d) => (date: d.date, value: d.count.toDouble())).toList(),
            allEntriesData: allPushups.map((d) => (date: d.date, value: d.count.toDouble())).toList(),
          ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildExerciseCard(
    ThemeData theme, {
    required String title,
    required String unit,
    required Color color,
    required TrendViewMode selectedView,
    required List<({DateTime date, double value})> sevenDayData,
    required List<({DateTime date, double value})> thirtyDayData,
    required List<({DateTime date, double value})> allEntriesData,
  }) {
    final isProgress = selectedView == TrendViewMode.progress;
    final List<({DateTime date, double value})> activeData = switch (selectedView) {
      TrendViewMode.sevenDays => sevenDayData,
      TrendViewMode.thirtyDays => thirtyDayData,
      TrendViewMode.progress => allEntriesData,
    };

    final latestValue = allEntriesData.isNotEmpty ? allEntriesData.last.value : 0.0;
    final startValue = allEntriesData.isNotEmpty ? allEntriesData.first.value : 0.0;
    final bestValue = allEntriesData.fold(0.0, (prev, e) => e.value > prev ? e.value : prev);
    final diff = latestValue - startValue;

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
                if (latestValue > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${latestValue.toInt()} $unit',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (isProgress && allEntriesData.length > 1) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(theme, 'Start', '${startValue.toInt()} $unit'),
                    _buildStatCol(theme, 'Best', '${bestValue.toInt()} $unit'),
                    _buildStatCol(
                      theme,
                      'Change',
                      '${diff >= 0 ? '+' : ''}${diff.toInt()} $unit',
                      color: diff >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: isProgress
                  ? _buildLineChart(
                      theme,
                      unit: unit,
                      data: activeData,
                      color: color,
                    )
                  : _buildBarChart(
                      theme,
                      unit: unit,
                      data: activeData,
                      color: color,
                      days: selectedView == TrendViewMode.sevenDays ? 7 : 30,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCol(ThemeData theme, String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
    ThemeData theme, {
    required String unit,
    required List<({DateTime date, double value})> data,
    required Color color,
    required int days,
  }) {
    final maxVal = data.map((d) => d.value).fold(0.0, (a, b) => a > b ? a : b);
    final topBound = maxVal > 0 ? (maxVal * 1.3).ceilToDouble() : 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topBound,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final d = data[group.x.toInt()];
              final dateLabel = DateFormat('d MMM').format(d.date);
              return BarTooltipItem(
                '$dateLabel\n${d.value.toInt()} $unit',
                TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
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
                final interval = days <= 7 ? 1 : 5;
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
                width: days <= 7 ? 16 : 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(
    ThemeData theme, {
    required String unit,
    required List<({DateTime date, double value})> data,
    required Color color,
  }) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No activity recorded yet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final maxVal = data.map((d) => d.value).fold(0.0, (a, b) => a > b ? a : b);
    final minVal = data.map((d) => d.value).fold(double.infinity, (a, b) => a < b ? a : b);
    final topBound = maxVal > 0 ? (maxVal * 1.25).ceilToDouble() : 10.0;
    final bottomBound = minVal > 0 ? (minVal * 0.75).floorToDouble() : 0.0;

    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final maxX = (data.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX > 0 ? maxX : 1,
        minY: bottomBound,
        maxY: topBound,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: topBound > bottomBound ? (topBound - bottomBound) / 4 : 5,
          getDrawingHorizontalLine: (val) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), // No X-axis labels required
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, meta) {
                if (val == meta.min || val == meta.max) return const SizedBox.shrink();
                return Text(
                  '${val.toInt()}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= data.length) return null;
                final item = data[idx];
                final dateLabel = DateFormat('d MMM yyyy').format(item.date);
                return LineTooltipItem(
                  'Set #${idx + 1} • $dateLabel\n${item.value.toInt()} $unit',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: data.length > 2,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 3.5,
                color: color,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
