import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/workout_routine.dart';
import '../../models/workout_session.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/muscle_group_selector.dart';
import 'widgets/exercise_selector.dart';
import 'widgets/exercise_track_card.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final List<String>? initialExercises;
  final WorkoutSession? existingSession;

  const WorkoutSessionScreen({
    super.key,
    this.initialExercises,
    this.existingSession,
  });

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int _step = 0; // 0=muscle groups, 1=select exercises, 2=track
  final List<String> _selectedMuscleGroups = [];
  final List<Exercise> _selectedExercises = [];
  WorkoutSession? _session;
  final Map<String, List<WorkoutSet>> _performanceData = {};

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
    if (widget.existingSession != null) {
      _session = widget.existingSession;
      _step = 2; // Directly to tracking
      // Muscle groups and exercises will be loaded in didChangeDependencies
    } else if (widget.initialExercises != null &&
        widget.initialExercises!.isNotEmpty) {
      _step = 2; // Skip directly to tracking
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.existingSession != null && _selectedExercises.isEmpty) {
      final provider = context.read<ExerciseProvider>();
      final all = provider.allExercises;
      for (var id in widget.existingSession!.exerciseIds) {
        try {
          final ex = all.firstWhere((e) => e.id == id);
          _selectedExercises.add(ex);
        } catch (_) {}
      }
      _selectedMuscleGroups.addAll(widget.existingSession!.targetMuscleGroups);
      _performanceData.addAll(widget.existingSession!.performance);
    } else if (widget.initialExercises != null && _selectedExercises.isEmpty) {
      final provider = context.read<ExerciseProvider>();
      final all = provider.allExercises;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle),
        centerTitle: true,
        leading: widget.existingSession != null
            ? const BackButton()
            : (_step > 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _step--),
                    )
                  : null),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: [
          _buildMuscleGroupStep(),
          _buildExerciseSelectionStep(),
          _buildTrackingStep(),
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
  Widget _buildMuscleGroupStep() {
    return MuscleGroupSelector(
      key: const ValueKey('step0'),
      initialMuscleGroups: _selectedMuscleGroups,
      muscleGroupsList: _muscleGroups,
      onNext: (selected) {
        setState(() {
          _selectedMuscleGroups.clear();
          _selectedMuscleGroups.addAll(selected);
          _step = 1;
        });
      },
    );
  }

  // --- Step 2: Exercise Selection ---
  Widget _buildExerciseSelectionStep() {
    return ExerciseSelector(
      key: const ValueKey('step1'),
      selectedMuscleGroups: _selectedMuscleGroups,
      initialSelectedExercises: _selectedExercises,
      onStart: (selected) {
        setState(() {
          _selectedExercises.clear();
          _selectedExercises.addAll(selected);
          _createSession();
          _step = 2;
        });
      },
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
  Widget _buildTrackingStep() {
    return Column(
      key: const ValueKey('step2'),
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedExercises.length,
            itemBuilder: (context, index) {
              final exercise = _selectedExercises[index];
              return ExerciseTrackCard(
                exercise: exercise,
                index: index,
                initialSets:
                    _performanceData[exercise.id] ??
                    [WorkoutSet(weightLbs: 0, weightKg: 0, reps: 0)],
                onChanged: (sets) {
                  _performanceData[exercise.id] = sets;
                },
              ).animate().fadeIn(delay: (index * 80).ms);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _finishWorkout,
            icon: const Icon(Icons.check_circle),
            label: Text(
              widget.existingSession != null
                  ? 'Update Workout'
                  : 'Finish Workout',
            ),
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

    final completedSession = _session!.copyWith(
      completed: true,
      performance: _performanceData,
    );

    final workoutProvider = context.read<WorkoutProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    if (widget.existingSession != null) {
      await workoutProvider.updateGymSession(
        completedSession,
        exerciseProvider,
      );
    } else {
      await workoutProvider.addGymSession(
        DateTime.now(),
        completedSession,
        exerciseProvider,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingSession != null
                ? 'Workout updated!'
                : 'Workout completed! 💪',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Offer to save as routine if it was started from scratch
      if (widget.existingSession == null &&
          (widget.initialExercises == null ||
              widget.initialExercises!.isEmpty)) {
        final saveAsRoutine = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Workout Complete!'),
            content: const Text(
              'Would you like to save this workout as a routine for the future?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No thanks'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save as Routine'),
              ),
            ],
          ),
        );

        if (saveAsRoutine == true && mounted) {
          await _showSaveRoutineDialog(context, completedSession);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showSaveRoutineDialog(
    BuildContext context,
    WorkoutSession session,
  ) async {
    final nameCtrl = TextEditingController();
    int selectedColor = 0xFF2196F3;
    final colors = [
      0xFF2196F3,
      0xFFF44336,
      0xFF4CAF50,
      0xFFFFC107,
      0xFF9C27B0,
      0xFFFF5722,
      0xFFE91E63,
      0xFF00BCD4,
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: const Text('Save as Routine'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Routine Name',
                      hintText: 'e.g., Morning Push',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  Text('Choose a color', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: colors.map((c) {
                      final isSelected = selectedColor == c;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = c),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: theme.colorScheme.onSurface,
                                    width: 2,
                                  )
                                : null,
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: Color(c).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final routine = WorkoutRoutine(
                      id: const Uuid().v4(),
                      name: nameCtrl.text.trim(),
                      exerciseIds: session.exerciseIds,
                      color: selectedColor,
                      targetMuscles: session.targetMuscleGroups,
                    );
                    context.read<WorkoutProvider>().createRoutine(routine);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Routine'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
