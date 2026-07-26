import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
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
        leading: _isReadOnlySession
            ? const BackButton()
            : (_step > 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _step--),
                    )
                  : null),
        actions: [
          if (_step == 2 && !_isReadOnlySession)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              tooltip: 'Add Exercise',
              onPressed: _showAddExerciseSheet,
            ),
        ],
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

  /// Whether this screen was opened for an existing session or via a routine
  /// (i.e. not from scratch through muscle group selection).
  bool get _isReadOnlySession =>
      widget.existingSession != null ||
      (widget.initialExercises != null && widget.initialExercises!.isNotEmpty);

  void _createSession() {
    // If muscle groups weren't explicitly selected (e.g. started from routine),
    // derive them from the exercises' body parts.
    final muscleGroups = _selectedMuscleGroups.isNotEmpty
        ? _selectedMuscleGroups
        : _selectedExercises.map((e) => e.bodyPart).toSet().toList();

    _session = WorkoutSession(
      id: const Uuid().v4(),
      date: DateTime.now(),
      targetMuscleGroups: muscleGroups,
      exerciseIds: _selectedExercises.map((e) => e.id).toList(),
    );
  }

  // --- Step 3: Track Workout ---
  Widget _buildTrackingStep() {
    return Column(
      key: const ValueKey('step2'),
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedExercises.length + (_isReadOnlySession ? 0 : 1),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) {
              // Ignore reorder involving the "add" card
              if (oldIndex >= _selectedExercises.length ||
                  newIndex > _selectedExercises.length) {
                return;
              }
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final exercise = _selectedExercises.removeAt(oldIndex);
                _selectedExercises.insert(newIndex, exercise);
                if (_session != null) {
                  _session = _session!.copyWith(
                    exerciseIds: _selectedExercises.map((e) => e.id).toList(),
                  );
                }
              });
            },
            itemBuilder: (context, index) {
              // "Add exercise" card at the end
              if (index == _selectedExercises.length) {
                return _buildAddExerciseCard(key: const ValueKey('__add__'));
              }
              final exercise = _selectedExercises[index];
              return ExerciseTrackCard(
                key: ValueKey(exercise.id),
                exercise: exercise,
                index: index,
                initialSets:
                    _performanceData[exercise.id] ??
                    [WorkoutSet(weightLbs: 0, weightKg: 0, reps: 0)],
                onChanged: (sets) {
                  _performanceData[exercise.id] = sets;
                },
              );
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

  Widget _buildAddExerciseCard({Key? key}) {
    final theme = Theme.of(context);
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showAddExerciseSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Exercise',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExerciseSheet() {
    final provider = context.read<ExerciseProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddExerciseSheet(
        allExercises: provider.allExercises,
        alreadySelected: _selectedExercises.map((e) => e.id).toSet(),
        onAdd: (exercises) {
          setState(() {
            _selectedExercises.addAll(exercises);
            if (_session != null) {
              _session = _session!.copyWith(
                exerciseIds: _selectedExercises.map((e) => e.id).toList(),
              );
            }
          });
        },
      ),
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

/// Bottom sheet to search & add exercises mid-workout.
class _AddExerciseSheet extends StatefulWidget {
  final List<Exercise> allExercises;
  final Set<String> alreadySelected;
  final Function(List<Exercise>) onAdd;

  const _AddExerciseSheet({
    required this.allExercises,
    required this.alreadySelected,
    required this.onAdd,
  });

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final List<Exercise> _picked = [];

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = widget.allExercises.where((e) {
      if (_query.isEmpty) return true;
      final words = _query.toLowerCase().split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) return true;
      final haystack = '${e.name} ${e.targetMuscle} ${e.bodyPart} ${e.equipment}'
          .toLowerCase();
      return words.every((word) => haystack.contains(word));
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Add Exercises',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_picked.isNotEmpty)
                  Badge(
                    label: Text('${_picked.length}'),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search by name, muscle, or body part…',
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
              onChanged: (v) => setState(() => _query = v),
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Exercise list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No exercises found',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      final alreadyIn =
                          widget.alreadySelected.contains(exercise.id);
                      final picked = _picked.contains(exercise);
                      final color =
                          AppColors.getBodyPartColor(exercise.bodyPart);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: picked
                              ? BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: exercise.gifUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                width: 50,
                                height: 50,
                                color: color.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              errorWidget: (_, _, _) => Container(
                                width: 50,
                                height: 50,
                                color: color.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: color,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            _capitalize(exercise.name),
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_capitalize(exercise.targetMuscle)} · ${_capitalize(exercise.equipment)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: alreadyIn
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.outline,
                                )
                              : Checkbox(
                                  value: picked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _picked.add(exercise);
                                      } else {
                                        _picked.remove(exercise);
                                      }
                                    });
                                  },
                                ),
                          onTap: alreadyIn
                              ? null
                              : () {
                                  setState(() {
                                    if (picked) {
                                      _picked.remove(exercise);
                                    } else {
                                      _picked.add(exercise);
                                    }
                                  });
                                },
                        ),
                      );
                    },
                  ),
          ),

          // Add button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _picked.isEmpty
                  ? null
                  : () {
                      widget.onAdd(_picked);
                      Navigator.pop(context);
                    },
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _picked.isEmpty
                    ? 'Select exercises'
                    : 'Add ${_picked.length} exercise${_picked.length > 1 ? 's' : ''}',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
