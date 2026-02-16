import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/theme/app_colors.dart';

class WeeklyProgressCard extends StatelessWidget {
  final int weeklyGoal;

  const WeeklyProgressCard({super.key, required this.weeklyGoal});

  String _getProgressMessage(int current, int goal) {
    if (current >= goal) return 'Goal achieved! You\'re crushing it! 🔥';
    if (current == 0) return 'Start your first workout of the week! 💪';
    final remaining = goal - current;
    return 'Just $remaining more workout${remaining > 1 ? 's' : ''} to reach your goal!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();
    final gymThisWeek = workout.gymDaysThisWeek();

    final progress = weeklyGoal > 0
        ? (gymThisWeek / weeklyGoal).clamp(0.0, 1.0)
        : 0.0;
    final exceeded = gymThisWeek > weeklyGoal;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Progress',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getProgressMessage(gymThisWeek, weeklyGoal),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                exceeded
                                    ? AppColors.success
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$gymThisWeek',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Goal: $weeklyGoal',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
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
}
