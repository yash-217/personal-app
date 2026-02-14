import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/exercise.dart';
import '../../models/weight_entry.dart';
import '../../providers/exercise_provider.dart';
import '../../core/theme/app_colors.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExerciseProvider>();
    final weightEntries = provider.getWeightEntries(exercise.id);
    final color = AppColors.getBodyPartColor(exercise.bodyPart);

    return Scaffold(
      appBar: AppBar(title: Text(_capitalize(exercise.name))),
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

                  // Weight progression
                  const SizedBox(height: 24),
                  Text(
                    'Weight Progression',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  if (weightEntries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.show_chart,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No entries yet',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Tap + to log your weight for this exercise',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _buildWeightChart(theme, weightEntries, color),
                    const SizedBox(height: 16),
                    ...weightEntries.reversed
                        .take(10)
                        .map((e) => _buildWeightEntryTile(theme, e, provider)),
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

  Widget _buildWeightChart(
    ThemeData theme,
    List<WeightEntry> entries,
    Color color,
  ) {
    final spots = entries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
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
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()} kg',
                  style: theme.textTheme.labelSmall,
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
              barWidth: 3,
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
                color: color.withValues(alpha: 0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = entries[spot.x.toInt()];
                  return LineTooltipItem(
                    '${entry.weight} kg\n${entry.reps ?? '-'}×${entry.sets ?? '-'}',
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

  Widget _buildWeightEntryTile(
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
          onPressed: () => provider.deleteWeightEntry(entry.id),
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
