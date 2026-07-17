import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/profile_provider.dart';

class DashboardStatsRow extends StatelessWidget {
  const DashboardStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final stepGoal = profile?.dailyStepGoal ?? 10000;

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
          const SizedBox(width: 8),
          _buildStepCard(theme, workout.stepsToday, stepGoal),
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

  Widget _buildStepCard(ThemeData theme, int steps, int goal) {
    final progress = goal > 0 ? (steps / goal).clamp(0.0, 1.0) : 0.0;
    final formattedSteps = steps >= 1000
        ? '${(steps / 1000).toStringAsFixed(1)}k'
        : '$steps';

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    progress >= 1.0
                        ? Colors.green
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedSteps,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Steps\nToday',
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
