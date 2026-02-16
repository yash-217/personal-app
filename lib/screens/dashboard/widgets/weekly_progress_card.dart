import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/theme/app_colors.dart';

class WeeklyProgressCard extends StatelessWidget {
  final int weeklyGoal;

  const WeeklyProgressCard({super.key, required this.weeklyGoal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();
    final gymThisWeek = workout.gymDaysThisWeek();

    final progress = weeklyGoal > 0
        ? (gymThisWeek / weeklyGoal).clamp(0.0, 1.0)
        : 0.0;
    final exceeded = gymThisWeek > weeklyGoal;
    final adherence = workout.weeklyAdherenceLastFourWeeks();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          exceeded
                              ? AppColors.success
                              : theme.colorScheme.primary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$gymThisWeek/$weeklyGoal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (exceeded)
                            Text('🎉', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (weeklyGoal + 2).toDouble(),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const weeks = ['W1', 'W2', 'W3', 'W4'];
                                return Text(
                                  weeks[value.toInt()],
                                  style: theme.textTheme.labelSmall,
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: List.generate(4, (i) {
                          final val = adherence.length > i
                              ? adherence[i].toDouble()
                              : 0.0;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: val,
                                color: val >= weeklyGoal
                                    ? AppColors.success
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                                width: 16,
                              ),
                            ],
                          );
                        }),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: weeklyGoal.toDouble(),
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }
}
