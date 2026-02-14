import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/workout_routine.dart';
import '../../providers/workout_provider.dart';
import '../../core/theme/app_colors.dart';
import 'routine_creator_screen.dart';
import '../workout/workout_session_screen.dart';
import '../exercises/exercise_library_screen.dart';

class GymScreen extends StatelessWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workoutProvider = context.watch<WorkoutProvider>();
    final routines = workoutProvider.routines;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gym & Routines',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(
                          'Manage your training',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Routines Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Routines', style: theme.textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.gym),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RoutineCreatorScreen(),
                          ),
                        );
                      },
                      tooltip: 'Create Routine',
                    ),
                  ],
                ),
              ),
            ),

            // Routines List
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: routines.isEmpty
                    ? _buildEmptyState(theme, context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: routines.length,
                        itemBuilder: (context, index) {
                          return _buildRoutineCard(
                            context,
                            routines[index],
                            theme,
                          );
                        },
                      ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Recent History Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Text(
                  'Recent Sessions',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),

            // Recent Sessions List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sessions = workoutProvider.sessions.reversed.toList();
                  if (index >= sessions.length) return null;
                  final session = sessions[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gym.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: AppColors.gym,
                      ),
                    ),
                    title: Text(
                      session.targetMuscleGroups.join(", "),
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${session.date.day}/${session.date.month}/${session.date.year} • ${session.completed ? "Completed" : "Incomplete"}',
                      style: theme.textTheme.labelSmall,
                    ),
                    onTap: () {
                      // Could navigate to details or repeat
                    },
                  );
                },
                childCount: workoutProvider.sessions.length > 5
                    ? 5
                    : workoutProvider.sessions.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Library Button
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExerciseLibraryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('Browse Exercise Library'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'No routines yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RoutineCreatorScreen()),
              );
            },
            child: const Text('Create your first routine'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(
    BuildContext context,
    WorkoutRoutine routine,
    ThemeData theme,
  ) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: Color(routine.color).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Color(routine.color).withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Start Routine
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkoutSessionScreen(
                  initialExercises: routine
                      .exerciseIds, // We need to update WorkoutSessionScreen to accept this
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(routine.color),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                      onSelected: (val) {
                        if (val == 'delete') {
                          context.read<WorkoutProvider>().deleteRoutine(
                            routine.id,
                          );
                        }
                      },
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  routine.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${routine.estimatedDuration} min • ${routine.exerciseIds.length} Exercises',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
