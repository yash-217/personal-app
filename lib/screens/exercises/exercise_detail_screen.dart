import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/weight_entry.dart';
import '../../providers/exercise_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/profile_provider.dart';
import '../../providers/workout_provider.dart';
import '../workout/workout_session_screen.dart';
import '../../widgets/confirm_dialog.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExerciseProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final unit = profile?.weightUnit ?? 'kg';

    final history = exercise.history;
    final weightEntries = provider.getWeightEntries(exercise.id);
    final color = AppColors.getBodyPartColor(exercise.bodyPart);

    return Scaffold(
      appBar: AppBar(
        title: Text(_capitalize(exercise.name)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWeightDialog(context, provider),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GIF animation
            Hero(
              tag: 'exercise-${exercise.id}',
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: CachedNetworkImage(
                  imageUrl: exercise.gifUrl,
                  height: 300,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: color),
                    ),
                  ),
                  errorWidget: (_, _, _) => SizedBox(
                    height: 300,
                    child: Center(
                      child: Icon(Icons.fitness_center, size: 64, color: color),
                    ),
                  ),
                ),
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(theme, exercise.bodyPart, color),
                      _buildTag(
                        theme,
                        exercise.targetMuscle,
                        theme.colorScheme.primary,
                      ),
                      _buildTag(
                        theme,
                        exercise.equipment,
                        theme.colorScheme.secondary,
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  // Secondary muscles
                  if (exercise.secondaryMuscles.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Secondary Muscles',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: exercise.secondaryMuscles
                          .map(
                            (m) => Chip(
                              label: Text(_capitalize(m)),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // Instructions
                  if (exercise.instructions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Instructions', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: (200 + entry.key * 50).ms);
                    }),
                  ],

                  // Exercise History (New detailed tracking)
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Performance History',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (history.isNotEmpty)
                        Text(
                          'Last: ${unit == 'lbs' ? history.last.weightLbs.toStringAsFixed(1) : history.last.weightKg.toStringAsFixed(1)} $unit',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (history.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No performance data yet',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Complete a workout session to see history',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn()
                  else ...[
                    _buildPerformanceChart(theme, history, color, unit),
                    const SizedBox(height: 16),
                    ...history.reversed.map((e) {
                      return _buildHistoryEntryTile(
                        context,
                        theme,
                        e,
                        workoutProvider,
                        unit,
                      );
                    }),
                  ],

                  // Legacy Weight progression
                  if (weightEntries.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Manual Logs (Legacy)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...weightEntries.reversed
                        .take(5)
                        .map(
                          (e) => _buildWeightEntryTile(
                            context,
                            theme,
                            e,
                            provider,
                          ),
                        ),
                  ],

                  const SizedBox(height: 80), // FAB spacing
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(ThemeData theme, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _capitalize(text),
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Widget _buildPerformanceChart(
    ThemeData theme,
    List<ExerciseHistoryEntry> history,
    Color color,
    String unit,
  ) {
    final spots = history
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            unit == 'lbs' ? e.value.weightLbs : e.value.weightKg,
          ),
        )
        .toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()} $unit',
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, progress, bar, index) =>
                    FlDotCirclePainter(
                      radius: 4,
                      color: color,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = history[spot.x.toInt()];
                  final w = unit == 'lbs' ? entry.weightLbs : entry.weightKg;
                  return LineTooltipItem(
                    '${w.toStringAsFixed(1)} $unit\n${entry.reps} reps',
                    TextStyle(color: color, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryEntryTile(
    BuildContext context,
    ThemeData theme,
    ExerciseHistoryEntry entry,
    WorkoutProvider workoutProvider,
    String unit,
  ) {
    final weight = unit == 'lbs' ? entry.weightLbs : entry.weightKg;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          final sessionId = entry.sessionId;
          if (sessionId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutSessionScreen(
                  existingSession: workoutProvider.getSessionById(sessionId),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Session data not found')),
            );
          }
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              weight.toStringAsFixed(0),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          '${weight.toStringAsFixed(1)} $unit × ${entry.reps} reps',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildWeightEntryTile(
    BuildContext context,
    ThemeData theme,
    WeightEntry entry,
    ExerciseProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            entry.weight.toStringAsFixed(0),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          '${entry.weight} kg — ${entry.sets ?? '?'}×${entry.reps ?? '?'} reps',
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
          style: theme.textTheme.labelSmall,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () async {
            final confirm = await ConfirmDialog.show(
              context,
              title: 'Delete Entry',
              message: 'Are you sure you want to delete this weight entry?',
            );
            if (confirm) {
              provider.deleteWeightEntry(entry.id);
            }
          },
        ),
      ),
    );
  }

  void _showAddWeightDialog(BuildContext context, ExerciseProvider provider) {
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    final setsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log Weight', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: setsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Sets'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: repsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final weight = double.tryParse(weightCtrl.text);
                  if (weight == null || weight <= 0) return;
                  provider.addWeightEntry(
                    exerciseId: exercise.id,
                    weight: weight,
                    reps: int.tryParse(repsCtrl.text),
                    sets: int.tryParse(setsCtrl.text),
                  );
                  Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
