import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/exercise.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/exercise_provider.dart';
import '../../exercises/exercise_detail_screen.dart';

class ExerciseSelector extends StatefulWidget {
  final List<String> selectedMuscleGroups;
  final List<Exercise> initialSelectedExercises;
  final Function(List<Exercise>) onStart;

  const ExerciseSelector({
    super.key,
    required this.selectedMuscleGroups,
    required this.initialSelectedExercises,
    required this.onStart,
  });

  @override
  State<ExerciseSelector> createState() => _ExerciseSelectorState();
}

class _ExerciseSelectorState extends State<ExerciseSelector> {
  final List<Exercise> _selectedExercises = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedExercises.addAll(widget.initialSelectedExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExerciseProvider>();
    final allForMuscles = provider.getExercisesForMuscleGroups(
      widget.selectedMuscleGroups,
    );

    final filteredExercises = allForMuscles.where((e) {
      if (_searchQuery.isEmpty) return true;
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
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
                ? () => widget.onStart(_selectedExercises)
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
}
