import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/exercise.dart';
import '../../../models/workout_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/profile_provider.dart';

class ExerciseTrackCard extends StatefulWidget {
  final Exercise exercise;
  final int index;
  final List<WorkoutSet> initialSets;
  final Function(List<WorkoutSet>) onChanged;

  const ExerciseTrackCard({
    super.key,
    required this.exercise,
    required this.index,
    required this.initialSets,
    required this.onChanged,
  });

  @override
  State<ExerciseTrackCard> createState() => _ExerciseTrackCardState();
}

class _ExerciseTrackCardState extends State<ExerciseTrackCard> {
  late List<WorkoutSet> _sets;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _sets = List<WorkoutSet>.from(widget.initialSets);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

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
                        'Weight',
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
                  final setIndex = entry.key;
                  final setData = entry.value;
                  final profile = context.watch<ProfileProvider>().profile;
                  final unit = profile?.weightUnit ?? 'kg';

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${setIndex + 1}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 36,
                              child: Builder(
                                builder: (context) {
                                  final text = unit == 'lbs'
                                      ? (setData.weightLbs > 0
                                            ? setData.weightLbs.toStringAsFixed(
                                                1,
                                              )
                                            : '')
                                      : (setData.weightKg > 0
                                            ? setData.weightKg.toStringAsFixed(
                                                1,
                                              )
                                            : '');
                                  return TextField(
                                    controller:
                                        TextEditingController(text: text)
                                          ..selection =
                                              TextSelection.fromPosition(
                                                TextPosition(
                                                  offset: text.length,
                                                ),
                                              ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: unit,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (v) {
                                      final val = double.tryParse(v) ?? 0;
                                      double lbs, kg;
                                      if (unit == 'lbs') {
                                        lbs = val;
                                        kg = val / 2.20462;
                                      } else {
                                        kg = val;
                                        lbs = val * 2.20462;
                                      }
                                      setState(() {
                                        _sets[setIndex] = WorkoutSet(
                                          weightLbs: lbs,
                                          weightKg: kg,
                                          reps: setData.reps,
                                        );
                                      });
                                      widget.onChanged(_sets);
                                    },
                                  );
                                },
                              ),
                            ),
                            Text(
                              unit == 'lbs'
                                  ? '${setData.weightKg.toStringAsFixed(1)} kg'
                                  : '${setData.weightLbs.toStringAsFixed(1)} lbs',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: SizedBox(
                          height: 36,
                          child: Builder(
                            builder: (context) {
                              final text = setData.reps > 0
                                  ? setData.reps.toString()
                                  : '';
                              return TextField(
                                controller: TextEditingController(text: text)
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(offset: text.length),
                                  ),
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
                                onChanged: (v) {
                                  final val = int.tryParse(v) ?? 0;
                                  setState(() {
                                    _sets[setIndex] = WorkoutSet(
                                      weightLbs: setData.weightLbs,
                                      weightKg: setData.weightKg,
                                      reps: val,
                                    );
                                  });
                                  widget.onChanged(_sets);
                                },
                              );
                            },
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
              onPressed: () {
                setState(
                  () =>
                      _sets.add(WorkoutSet(weightLbs: 0, weightKg: 0, reps: 0)),
                );
                widget.onChanged(_sets);
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Set'),
            ),
          ],
        ),
      ),
    );
  }
}
