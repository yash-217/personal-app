import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../../models/body_metrics.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../providers/profile_provider.dart';

class BodyMetricsHistory extends StatelessWidget {
  final List<BodyMetrics> metrics;
  final Function(BodyMetrics)? onEdit;

  const BodyMetricsHistory({super.key, required this.metrics, this.onEdit});

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

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Slidable(
                key: Key(item.id),
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        if (onEdit != null) {
                          onEdit!(item);
                        }
                      },
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      icon: Icons.edit,
                      label: 'Edit',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  extentRatio: 0.25,
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      title: Row(
                        children: [
                          Text(
                            '${item.date.day}/${item.date.month}/${item.date.year}',
                            style: theme.textTheme.titleSmall,
                          ),
                          if (item.recommendedCalorieIntake > 0) ...[
                            const SizedBox(width: 12),
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
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildHistoryItem(
                                theme,
                                'Weight',
                                '${item.weight} kg',
                                item.weight,
                                nextItem?.weight,
                                lowerIsBetter: true,
                              ),
                            ),
                            if (item.bodyFatPercentage > 0)
                              Expanded(
                                child: _buildHistoryItem(
                                  theme,
                                  'Body Fat',
                                  '${item.bodyFatPercentage}%',
                                  item.bodyFatPercentage,
                                  nextItem?.bodyFatPercentage,
                                  lowerIsBetter: true,
                                ),
                              ),
                            if (item.protein > 0)
                              Expanded(
                                child: _buildHistoryItem(
                                  theme,
                                  'Protein',
                                  '${item.protein} kg',
                                  item.protein,
                                  nextItem?.protein,
                                  lowerIsBetter: false,
                                ),
                              ),
                          ],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                theme,
                                'BMR',
                                '${item.basalMetabolicRate.toStringAsFixed(0)} kcal',
                              ),
                              _buildDetailRow(
                                theme,
                                'Visceral Fat',
                                item.visceralFatLevel.toStringAsFixed(0),
                              ),
                              _buildDetailRow(
                                theme,
                                'Total Body Water',
                                '${item.totalBodyWater.toStringAsFixed(1)} L',
                              ),
                              _buildDetailRow(
                                theme,
                                'Body Fat Mass',
                                '${item.bodyFatMass.toStringAsFixed(1)} kg',
                              ),
                              _buildDetailRow(
                                theme,
                                'BMI',
                                item.bmi.toStringAsFixed(1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
