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
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.6,
              children: [
                _buildActivityStat(
                  theme,
                  icon: Icons.fitness_center,
                  color: AppColors.gym,
                  label: 'Gym',
                  value: '${workout.gymThisMonth}',
                  subtitle: 'sessions',
                ),
                _buildActivityStat(
                  theme,
                  icon: Icons.directions_run,
                  color: AppColors.run,
                  label: 'Runs',
                  value: '${workout.runsThisMonth}',
                  subtitle:
                      '${workout.totalRunDistanceThisMonth.toStringAsFixed(1)} km',
                ),
                _buildActivityStat(
                  theme,
                  icon: Icons.pool,
                  color: AppColors.swim,
                  label: 'Swims',
                  value: '${workout.swimsThisMonth}',
                  subtitle: 'sessions',
                ),
                _buildActivityStat(
                  theme,
                  icon: Icons.sports,
                  color: AppColors.football,
                  label: 'Sports',
                  value: '${workout.sportsThisMonth}',
                  subtitle: 'sessions',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
