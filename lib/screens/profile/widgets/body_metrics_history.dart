import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/body_metrics.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../providers/profile_provider.dart'; // Import provider for delete action

class BodyMetricsHistory extends StatelessWidget {
  final List<BodyMetrics> metrics;

  const BodyMetricsHistory({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Reverse sort for display (newest first)
    final sorted = List<BodyMetrics>.from(metrics).reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final item = sorted[index];
            final nextItem = index + 1 < sorted.length
                ? sorted[index + 1]
                : null;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.date.day}/${item.date.month}/${item.date.year}',
                          style: theme.textTheme.titleSmall,
                        ),
                        if (item.recommendedCalorieIntake > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${item.recommendedCalorieIntake.toStringAsFixed(0)} kcal',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            final confirm = await ConfirmDialog.show(
                              context,
                              title: 'Delete Measurement',
                              message:
                                  'Are you sure you want to delete this record?',
                            );
                            if (confirm && context.mounted) {
                              context.read<ProfileProvider>().deleteBodyMetrics(
                                item.id,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHistoryItem(
                          theme,
                          'Weight',
                          '${item.weight} kg',
                          item.weight,
                          nextItem?.weight,
                          lowerIsBetter: true,
                        ),
                        if (item.bodyFatPercentage > 0)
                          _buildHistoryItem(
                            theme,
                            'Body Fat',
                            '${item.bodyFatPercentage}%',
                            item.bodyFatPercentage,
                            nextItem?.bodyFatPercentage,
                            lowerIsBetter: true,
                          ),
                        if (item.protein > 0)
                          _buildHistoryItem(
                            theme,
                            'Protein',
                            '${item.protein} kg',
                            item.protein,
                            nextItem?.protein,
                            lowerIsBetter: false,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
    ThemeData theme,
    String label,
    String value,
    double current,
    double? prev, {
    required bool lowerIsBetter,
  }) {
    final hasDelta = prev != null && prev > 0 && current != prev;
    final delta = hasDelta ? current - prev : 0.0;
    final isImproving = lowerIsBetter ? delta < 0 : delta > 0;
    final deltaColor = isImproving ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: theme.textTheme.bodyMedium),
            if (hasDelta) ...[
              const SizedBox(width: 4),
              Icon(
                delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: deltaColor,
              ),
              Text(
                delta.abs().toStringAsFixed(1),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
