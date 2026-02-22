import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_provider.dart';

class DashboardStatsRow extends StatelessWidget {
  const DashboardStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            theme,
            'Total\nWorkouts',
            '${workout.totalGymDays}',
            Icons.fitness_center,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            'Current\nStreak',
            '${workout.currentStreak}',
            Icons.local_fire_department,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            'Best\nStreak',
            '${workout.bestStreak}',
            Icons.emoji_events,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
