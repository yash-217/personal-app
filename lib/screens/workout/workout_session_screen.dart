import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/exercise.dart';
import '../../models/workout_session.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';
import '../../core/theme/app_colors.dart';
import '../exercises/exercise_detail_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final List<String>? initialExercises;

  const WorkoutSessionScreen({super.key, this.initialExercises});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int _step = 0; // 0=muscle groups, 1=select exercises, 2=track
  final List<String> _selectedMuscleGroups = [];
  final List<Exercise> _selectedExercises = [];
  WorkoutSession? _session;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const _muscleGroups = [
    'chest',
    'back',
    'shoulders',
    'upper arms',
    'lower arms',
    'upper legs',
    'lower legs',
    'waist',
    'cardio',
    'neck',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialExercises != null &&
        widget.initialExercises!.isNotEmpty) {
      _step = 2; // Skip directly to tracking
      // Implementation note: We need to load exercises in post-frame callback
      // or here if provider is available. Better do it in didChangeDependencies
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialExercises != null && _selectedExercises.isEmpty) {
      final provider = context.read<ExerciseProvider>();
      // Simple lookup
      final all = provider.exercises;
      for (var id in widget.initialExercises!) {
        try {
          final ex = all.firstWhere((e) => e.id == id);
          _selectedExercises.add(ex);
        } catch (_) {}
      }
      if (_selectedExercises.isNotEmpty) {
        _createSession();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: [
          _buildMuscleGroupStep(theme),
          _buildExerciseSelectionStep(theme),
          _buildTrackingStep(theme),
        ][_step],
      ),
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'Select Muscle Groups';
      case 1:
        return 'Choose Exercises';
      case 2:
        return 'Track Workout';
      default:
        return '';
    }
  }

  // --- Step 1: Muscle Groups ---
  Widget _buildMuscleGroupStep(ThemeData theme) {
    return Column(
      key: const ValueKey('step0'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _muscleGroups.map((group) {
              final selected = _selectedMuscleGroups.contains(group);
              final color = AppColors.getBodyPartColor(group);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(
                      alpha: selected ? 0.3 : 0.1,
                    ),
                    child: Icon(
                      selected ? Icons.check : Icons.fitness_center,
                      color: color,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _capitalize(group),
                    style: theme.textTheme.titleSmall,
                  ),
                  selected: selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: selected
                        ? BorderSide(color: color, width: 2)
                        : BorderSide.none,
                  ),
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedMuscleGroups.remove(group);
                      } else {
                        _selectedMuscleGroups.add(group);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selectedMuscleGroups.isNotEmpty
                ? () => setState(() => _step = 1)
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text('Next (${_selectedMuscleGroups.length} selected)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Exercise Selection ---
  Widget _buildExerciseSelectionStep(ThemeData theme) {
    final provider = context.watch<ExerciseProvider>();
    final allForMuscles = provider.getExercisesForMuscleGroups(
      _selectedMuscleGroups,
    );

    final filteredExercises = allForMuscles.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      key: const ValueKey('step1'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search exercises...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
            ],
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            '${_selectedExercises.length} exercises selected',
            style: theme.textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: filteredExercises.isEmpty
              ? Center(
                  child: Text(
                    'No exercises found for selected muscles',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    final selected = _selectedExercises.contains(exercise);
                    final color = AppColors.getBodyPartColor(exercise.bodyPart);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: selected
                            ? BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selectedExercises.remove(exercise);
                            } else {
                              _selectedExercises.add(exercise);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Checkbox(
                                  value: selected,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _selectedExercises.add(exercise);
                                      } else {
                                        _selectedExercises.remove(exercise);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Hero(
                                tag: 'session-exercise-${exercise.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: exercise.gifUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (_, _) => Container(
                                      width: 60,
                                      height: 60,
                                      color: color.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.fitness_center,
                                        color: color,
                                      ),
                                    ),
                                    errorWidget: (_, _, _) => Container(
                                      width: 60,
                                      height: 60,
                                      color: color.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.fitness_center,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _capitalize(exercise.name),
                                      style: theme.textTheme.titleSmall,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_capitalize(exercise.targetMuscle)} · ${_capitalize(exercise.equipment)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _difficultyColor(
                                          exercise.difficulty,
                                        ).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${_difficultyEmoji(exercise.difficulty)} ${exercise.difficulty}',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: _difficultyColor(
                                                exercise.difficulty,
                                              ),
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ExerciseDetailScreen(
                                        exercise: exercise,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _selectedExercises.isNotEmpty
                ? () {
                    _createSession();
                    setState(() => _step = 2);
                  }
                : null,
            icon: const Icon(Icons.play_arrow),
            label: Text('Start (${_selectedExercises.length} exercises)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ),
      ],
    );
  }

  void _createSession() {
    _session = WorkoutSession(
      id: const Uuid().v4(),
      date: DateTime.now(),
      targetMuscleGroups: _selectedMuscleGroups,
      exerciseIds: _selectedExercises.map((e) => e.id).toList(),
    );
  }

  // --- Step 3: Track Workout ---
  Widget _buildTrackingStep(ThemeData theme) {
    return Column(
      key: const ValueKey('step2'),
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedExercises.length,
            itemBuilder: (context, index) {
              final exercise = _selectedExercises[index];
              return _ExerciseTrackCard(
                exercise: exercise,
                index: index,
              ).animate().fadeIn(delay: (index * 80).ms);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _finishWorkout,
            icon: const Icon(Icons.check_circle),
            label: const Text('Finish Workout'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.success,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _finishWorkout() async {
    if (_session == null) return;
    final completedSession = _session!.copyWith(completed: true);
    final workoutProvider = context.read<WorkoutProvider>();
    await workoutProvider.addGymSession(DateTime.now(), completedSession);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout completed! 💪'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _difficultyEmoji(String difficulty) {
    switch (difficulty) {
      case 'Rookie':
        return '🌱';
      case 'Regular':
        return '💪';
      case 'Gym Bro':
        return '🏋';
      case 'Lifter':
        return '🔥';
      case 'Veteran':
        return '⭐';
      default:
        return '💪';
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Rookie':
        return Colors.green;
      case 'Regular':
        return Colors.blue;
      case 'Gym Bro':
        return Colors.orange;
      case 'Lifter':
        return Colors.deepOrange;
      case 'Veteran':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class _ExerciseTrackCard extends StatefulWidget {
  final Exercise exercise;
  final int index;

  const _ExerciseTrackCard({required this.exercise, required this.index});

  @override
  State<_ExerciseTrackCard> createState() => _ExerciseTrackCardState();
}

class _ExerciseTrackCardState extends State<_ExerciseTrackCard> {
  final List<_SetData> _sets = [_SetData()];
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.getBodyPartColor(widget.exercise.bodyPart);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _completed
            ? BorderSide(color: AppColors.success, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(color: color),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _capitalize(widget.exercise.name),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _completed
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: _completed
                        ? AppColors.success
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _completed = !_completed),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sets table
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Set',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Weight (kg)',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Reps',
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                ..._sets.asMap().entries.map((entry) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${entry.key + 1}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (v) =>
                                entry.value.weight = double.tryParse(v),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: SizedBox(
                          height: 36,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onChanged: (v) =>
                                entry.value.reps = int.tryParse(v),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _sets.add(_SetData())),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class _SetData {
  double? weight;
  int? reps;
}
