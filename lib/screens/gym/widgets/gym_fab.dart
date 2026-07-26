import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../workout/workout_session_screen.dart';
import '../routine_creator_screen.dart';

class GymFab extends StatefulWidget {
  const GymFab({super.key});

  @override
  State<GymFab> createState() => _GymFabState();
}

class _GymFabState extends State<GymFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs
        ..._buildMiniFabs(context),
        const SizedBox(height: 12),
        // Main FAB
        FloatingActionButton(
          heroTag: 'gymMainFab',
          onPressed: _toggleFab,
          child: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (_, child) {
              return Transform.rotate(
                angle: _fabAnimation.value * pi * 0.75,
                child: child,
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMiniFabs(BuildContext context) {
    final workout = context.watch<WorkoutProvider>();
    final routines = workout.routines;

    final items = [
      _FabItem(
        icon: Icons.fitness_center,
        label: 'Add Workout',
        color: AppColors.gym,
        onTap: () {
          _toggleFab();
          _showGymOptions(context, routines);
        },
      ),
      _FabItem(
        icon: Icons.edit_note,
        label: 'Create Routine',
        color: AppColors.seed,
        onTap: () {
          _toggleFab();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RoutineCreatorScreen(),
            ),
          );
        },
      ),
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return AnimatedBuilder(
        animation: _fabAnimation,
        builder: (_, child) {
          final delay = (items.length - 1 - index) * 0.15;
          final progress =
              (_fabAnimation.value - delay).clamp(0.0, 1.0) /
              (1.0 - delay).clamp(0.01, 1.0);
          return Transform.translate(
            offset: Offset(0, (1 - progress) * 20),
            child: Opacity(opacity: progress.clamp(0.0, 1.0), child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'gym_fab_${item.label}',
                backgroundColor: item.color,
                foregroundColor: Colors.white,
                onPressed: item.onTap,
                child: Icon(item.icon),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showGymOptions(BuildContext context, List routines) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Start Workout',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gym.withValues(alpha: 0.1),
                  child: const Icon(Icons.add, color: AppColors.gym),
                ),
                title: const Text('Empty Workout'),
                subtitle: const Text('Start from scratch'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkoutSessionScreen(),
                    ),
                  );
                },
              ),
              if (routines.isNotEmpty) ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    'Quick Start Routine',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          color: Color(routine.color).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Color(
                                routine.color,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WorkoutSessionScreen(
                                    initialExercises: routine.exerciseIds,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routine.name,
                                    style: Theme.of(ctx).textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${routine.estimatedDuration} min',
                                    style: Theme.of(ctx).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _FabItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _FabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
