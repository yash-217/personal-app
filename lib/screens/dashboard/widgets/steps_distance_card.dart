import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';

class StepsDistanceCard extends StatelessWidget {
  const StepsDistanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    final steps = workout.stepsToday;
    final stepGoal = profile?.dailyStepGoal ?? 10000;
    final stepProgress = stepGoal > 0 ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0;
    final stepExceeded = steps >= stepGoal;

    final walkKm = workout.walkDistanceToday;
    final walkGoal = profile?.dailyWalkKmGoal ?? 5.0;
    final walkProgress = walkGoal > 0 ? (walkKm / walkGoal).clamp(0.0, 1.0) : 0.0;
    final walkExceeded = walkKm >= walkGoal;

    final formattedSteps =
        steps >= 1000 ? '${(steps / 1000).toStringAsFixed(1)}k' : '$steps';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Steps & Walking',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // Steps progress ring
                Expanded(
                  child: _buildProgressRing(
                    theme,
                    value: formattedSteps,
                    label: 'Steps',
                    goal: '${(stepGoal / 1000).toStringAsFixed(0)}k goal',
                    progress: stepProgress,
                    exceeded: stepExceeded,
                    icon: Icons.directions_walk_rounded,
                  ),
                ),
                const SizedBox(width: 24),
                // Distance progress ring
                Expanded(
                  child: _buildProgressRing(
                    theme,
                    value: walkKm.toStringAsFixed(1),
                    label: 'km walked',
                    goal: '${walkGoal.toStringAsFixed(1)} km goal',
                    progress: walkProgress,
                    exceeded: walkExceeded,
                    icon: Icons.straighten_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildProgressRing(
    ThemeData theme, {
    required String value,
    required String label,
    required String goal,
    required double progress,
    required bool exceeded,
    required IconData icon,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    exceeded ? AppColors.success : theme.colorScheme.primary,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: exceeded
                        ? AppColors.success
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        Text(
          goal,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
