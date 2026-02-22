import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../providers/exercise_provider.dart';
import '../../core/theme/app_colors.dart';
import 'exercise_detail_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExerciseProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
              child: Row(
                children: [
                  const BackButton(),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Exercise Library',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => provider.setSearchQuery(q),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            provider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Body Part filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: provider.selectedBodyPart == null,
                    onSelected: (_) => provider.setBodyPartFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...provider.bodyParts.map(
                    (part) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_capitalize(part)),
                        selected: provider.selectedBodyPart == part,
                        onSelected: (_) => provider.setBodyPartFilter(
                          provider.selectedBodyPart == part ? null : part,
                        ),
                        avatar: CircleAvatar(
                          backgroundColor: AppColors.getBodyPartColor(part),
                          radius: 6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Difficulty filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All Levels'),
                    selected: provider.selectedDifficulty == null,
                    onSelected: (_) => provider.setDifficultyFilter(null),
                  ),
                  const SizedBox(width: 8),
                  ...ExerciseProvider.difficultyLevels.map(
                    (level) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${_difficultyEmoji(level)} $level'),
                        selected: provider.selectedDifficulty == level,
                        onSelected: (_) => provider.setDifficultyFilter(
                          provider.selectedDifficulty == level ? null : level,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Exercise list
            Expanded(child: _buildContent(theme, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ExerciseProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && !provider.hasData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text('No exercises loaded', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Could not load exercises. Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (provider.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => provider.refreshExercises(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.exercises.isEmpty) {
      return Center(
        child: Text('No exercises found', style: theme.textTheme.bodyMedium),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshExercises(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.exercises.length,
        itemBuilder: (context, index) {
          final exercise = provider.exercises[index];
          return _buildExerciseCard(theme, exercise, index);
        },
      ),
    );
  }

  Widget _buildExerciseCard(ThemeData theme, Exercise exercise, int index) {
    final color = AppColors.getBodyPartColor(exercise.bodyPart);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(exercise: exercise),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // GIF thumbnail
              Hero(
                tag: 'exercise-${exercise.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: exercise.gifUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.fitness_center, color: color),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.fitness_center, color: color),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _capitalize(exercise.bodyPart),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _capitalize(exercise.targetMuscle),
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _capitalize(exercise.equipment),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor(
                              exercise.difficulty,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_difficultyEmoji(exercise.difficulty)} ${exercise.difficulty}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _difficultyColor(exercise.difficulty),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
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
