import 'package:flutter/material.dart';
import '../../../models/body_metrics.dart';

class BodyMetricsLatest extends StatelessWidget {
  final BodyMetrics latest;
  final BodyMetrics? previous;

  const BodyMetricsLatest({super.key, required this.latest, this.previous});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Latest Measurement', style: theme.textTheme.titleSmall),
                Text(
                  '${latest.date.day}/${latest.date.month}/${latest.date.year}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChipWithDelta(
                  theme,
                  'Weight',
                  '${latest.weight} kg',
                  latest.weight,
                  previous?.weight,
                  lowerIsBetter: true,
                ),
                if (latest.bodyFatPercentage > 0)
                  _metricChipWithDelta(
                    theme,
                    'Body Fat',
                    '${latest.bodyFatPercentage}%',
                    latest.bodyFatPercentage,
                    previous?.bodyFatPercentage,
                    lowerIsBetter: true,
                  ),

                if (latest.basalMetabolicRate > 0)
                  _metricChipWithDelta(
                    theme,
                    'BMR',
                    '${latest.basalMetabolicRate.toStringAsFixed(0)} kcal',
                    latest.basalMetabolicRate,
                    previous?.basalMetabolicRate,
                    lowerIsBetter: false,
                  ),
                if (latest.visceralFatLevel > 0)
                  _metricChipWithDelta(
                    theme,
                    'Visceral Fat',
                    '${latest.visceralFatLevel}',
                    latest.visceralFatLevel,
                    previous?.visceralFatLevel,
                    lowerIsBetter: true,
                  ),
                if (latest.totalBodyWater > 0)
                  _metricChipWithDelta(
                    theme,
                    'TBW',
                    '${latest.totalBodyWater} L',
                    latest.totalBodyWater,
                    previous?.totalBodyWater,
                    lowerIsBetter: false,
                  ),
                if (latest.bodyFatMass > 0)
                  _metricChipWithDelta(
                    theme,
                    'Fat Mass',
                    '${latest.bodyFatMass} kg',
                    latest.bodyFatMass,
                    previous?.bodyFatMass,
                    lowerIsBetter: true,
                  ),
                if (latest.protein > 0)
                  _metricChipWithDelta(
                    theme,
                    'Protein',
                    '${latest.protein} kg',
                    latest.protein,
                    previous?.protein,
                    lowerIsBetter: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChipWithDelta(
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasDelta) ...[
                const SizedBox(width: 4),
                Icon(
                  delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isImproving ? Colors.green : Colors.red,
                ),
              ],
            ],
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
