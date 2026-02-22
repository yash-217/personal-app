import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/theme/app_colors.dart';

class ActivityStatsCard extends StatelessWidget {
  const ActivityStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity This Month', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActivityStat(
                  theme,
                  icon: Icons.directions_run,
                  color: AppColors.run,
                  label: 'Runs',
                  value: '${workout.runsThisMonth}',
                  subtitle:
                      '${workout.totalRunDistanceThisMonth.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 16),
                _buildActivityStat(
                  theme,
                  icon: Icons.pool,
                  color: AppColors.swim,
                  label: 'Swims',
                  value: '${workout.swimsThisMonth}',
                  subtitle: 'this month',
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildActivityStat(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(color: color),
                ),
                Text(subtitle, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
