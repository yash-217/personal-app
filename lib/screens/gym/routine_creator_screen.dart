import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/workout_routine.dart';
import '../../providers/exercise_provider.dart';
import '../../providers/workout_provider.dart';
import '../../core/theme/app_colors.dart';
import '../exercises/exercise_detail_screen.dart';

class RoutineCreatorScreen extends StatefulWidget {
  const RoutineCreatorScreen({super.key});

  @override
  State<RoutineCreatorScreen> createState() => _RoutineCreatorScreenState();
}

class _RoutineCreatorScreenState extends State<RoutineCreatorScreen> {
  final _nameController = TextEditingController();
  final List<Exercise> _selectedExercises = [];
  int _selectedColor = 0xFF2196F3; // Default Blue
  int _step = 0; // 0=Name & Color, 1=Select Exercises
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<int> _colors = [
    0xFF2196F3, // Blue
    0xFFF44336, // Red
    0xFF4CAF50, // Green
    0xFFFFC107, // Amber
    0xFF9C27B0, // Purple
    0xFFFF5722, // Deep Orange
    0xFFE91E63, // Pink
    0xFF00BCD4, // Cyan
  ];

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
  final List<String> _selectedMuscleFilter = [];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleMuscleFilter(String muscle) {
    setState(() {
      if (_selectedMuscleFilter.contains(muscle)) {
        _selectedMuscleFilter.remove(muscle);
      } else {
        _selectedMuscleFilter.add(muscle);
      }
    });
  }

  void _saveRoutine() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine name')),
      );
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one exercise')),
      );
      return;
    }

    final routine = WorkoutRoutine(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      exerciseIds: _selectedExercises.map((e) => e.id).toList(),
      color: _selectedColor,
      targetMuscles: _selectedExercises.map((e) => e.bodyPart).toSet().toList(),
    );

    context.read<WorkoutProvider>().createRoutine(routine);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'New Routine' : 'Add Exercises'),
        centerTitle: true,
        actions: [
          if (_step == 1)
            TextButton(onPressed: _saveRoutine, child: const Text('Save')),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _step == 0 ? _buildStep1(theme) : _buildStep2(theme),
      ),
      floatingActionButton: _step == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a routine name'),
                    ),
                  );
                  return;
                }
                setState(() => _step = 1);
              },
              label: const Text('Next'),
              icon: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name your routine', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Routine Name',
              hintText: 'e.g., Push Day, Leg Destroyer',
              prefixIcon: Icon(Icons.edit),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 32),
          Text('Choose a color', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _colors.map((colorValue) {
              final isSelected = _selectedColor == colorValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorValue),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface,
                            width: 3,
                          )
                        : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: Color(colorValue).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    final provider = context.watch<ExerciseProvider>();
    final allExercises = provider.exercises;

    // Filter Logic
    final filteredExercises = allExercises.where((exercise) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          exercise.name.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesMuscle =
          _selectedMuscleFilter.isEmpty ||
          _selectedMuscleFilter.contains(exercise.bodyPart.toLowerCase());

      return matchesSearch && matchesMuscle;
    }).toList();

    // Sort logic reused from ExerciseProvider
    filteredExercises.sort((a, b) {
      // 1. Difficulty
      // We can't access private _getDifficultyRank but strict string compare is okayish or just skip
      // Actually let's just use name for simplicity here or rely on list order if already sorted
      return a.name.compareTo(b.name);
    });

    return Column(
      children: [
        // Search & Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SearchBar(
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
                onChanged: (value) => setState(() => _searchQuery = value),
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _muscleGroups.map((muscle) {
                    final isSelected = _selectedMuscleFilter.contains(muscle);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(muscle),
                        selected: isSelected,
                        onSelected: (_) => _toggleMuscleFilter(muscle),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Selected Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedExercises.length} exercises selected',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedExercises.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedExercises.clear()),
                  child: const Text('Clear All'),
                ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredExercises.length,
            itemBuilder: (context, index) {
              final exercise = filteredExercises[index];
              final isSelected = _selectedExercises.contains(exercise);
              final color = AppColors.getBodyPartColor(exercise.bodyPart);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? BorderSide(color: theme.colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
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
                        // Checkbox
                        SizedBox(
                          width: 24,
                          child: Checkbox(
                            value: isSelected,
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
                        // GIF thumbnail
                        Hero(
                          tag: 'routine-exercise-${exercise.id}',
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
                                child: Icon(Icons.fitness_center, color: color),
                              ),
                              errorWidget: (_, _, _) => Container(
                                width: 60,
                                height: 60,
                                color: color.withValues(alpha: 0.1),
                                child: Icon(Icons.fitness_center, color: color),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
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
                              Row(
                                children: [
                                  Text(
                                    _capitalize(exercise.bodyPart),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text('•', style: theme.textTheme.labelSmall),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _capitalize(exercise.equipment),
                                      style: theme.textTheme.labelSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                                  style: theme.textTheme.labelSmall?.copyWith(
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
                                builder: (_) =>
                                    ExerciseDetailScreen(exercise: exercise),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms);
            },
          ),
        ),
      ],
    );
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
