import 'package:flutter/material.dart';
import '../../../models/body_metrics.dart';

class BodyMetricsLatest extends StatelessWidget {
  final List<BodyMetrics> metrics;
  final double userHeight;

  const BodyMetricsLatest({
    super.key,
    required this.metrics,
    required this.userHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    final sorted = List<BodyMetrics>.from(metrics)
      ..sort((a, b) => a.date.compareTo(b.date));
    final latestEntry = sorted.last;

    // Helper to calculate BMI if needed
    double calculateBmi(BodyMetrics m) {
      if (m.bmi > 0) return m.bmi;
      if (userHeight > 0 && m.weight > 0) {
        final heightM = userHeight / 100;
        return m.weight / (heightM * heightM);
      }
      return 0;
    }

    // Helper to find latest non-zero value and its predecessor for delta
    Map<String, double> getMetricWithPrev(
      double Function(BodyMetrics) selector,
    ) {
      double latestVal = selector(latestEntry);
      double? prevVal;

      // If latest is zero, find the actual latest non-zero
      if (latestVal == 0) {
        for (int i = sorted.length - 1; i >= 0; i--) {
          if (selector(sorted[i]) > 0) {
            latestVal = selector(sorted[i]);
            // Now find the one before THIS one for delta
            for (int j = i - 1; j >= 0; j--) {
              if (selector(sorted[j]) > 0) {
                prevVal = selector(sorted[j]);
                break;
              }
            }
            break;
          }
        }
      } else {
        // Latest is non-zero, find the one before it
        for (int i = sorted.length - 2; i >= 0; i--) {
          if (selector(sorted[i]) > 0) {
            prevVal = selector(sorted[i]);
            break;
          }
        }
      }
      return {'current': latestVal, 'prev': prevVal ?? 0};
    }

    final weightData = getMetricWithPrev((m) => m.weight);
    final fatData = getMetricWithPrev((m) => m.bodyFatPercentage);
    final bmrData = getMetricWithPrev((m) => m.basalMetabolicRate);
    final proteinData = getMetricWithPrev((m) => m.protein);
    final tbwData = getMetricWithPrev((m) => m.totalBodyWater);
    final fatMassData = getMetricWithPrev((m) => m.bodyFatMass);
    final visceralData = getMetricWithPrev((m) => m.visceralFatLevel);
    // BMI is now calculated dynamically if missing
    final bmiData = getMetricWithPrev((m) => calculateBmi(m));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Body Metrics', style: theme.textTheme.titleMedium),
            Text(
              '${latestEntry.date.day}/${latestEntry.date.month}/${latestEntry.date.year}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Primary Metrics Row (3 Columns)
                Row(
                  children: [
                    Expanded(
                      child: _buildPrimaryMetric(
                        theme,
                        Icons.monitor_weight_outlined,
                        'Weight',
                        weightData['current']!.toString(),
                        'kg',
                        weightData['current']!,
                        weightData['prev'],
                        lowerIsBetter: true,
                      ),
                    ),
                    const SizedBox(height: 40, child: VerticalDivider()),
                    Expanded(
                      child: _buildPrimaryMetric(
                        theme,
                        Icons.percent,
                        'Body Fat',
                        fatData['current']!.toString(),
                        '%',
                        fatData['current']!,
                        fatData['prev'],
                        lowerIsBetter: true,
                        visible: fatData['current']! > 0,
                      ),
                    ),
                    const SizedBox(height: 40, child: VerticalDivider()),
                    Expanded(
                      child: _buildPrimaryMetric(
                        theme,
                        Icons.speed,
                        'BMI',
                        bmiData['current']!.toStringAsFixed(1),
                        '',
                        bmiData['current']!,
                        bmiData['prev'],
                        lowerIsBetter: true,
                        visible: bmiData['current']! > 0,
                      ),
                    ),
                  ],
                ),
                if (proteinData['current']! > 0 ||
                    bmrData['current']! > 0 ||
                    tbwData['current']! > 0 ||
                    fatMassData['current']! > 0 ||
                    visceralData['current']! > 0) ...[
                  const Divider(height: 32),
                  // Secondary Metrics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      if (proteinData['current']! > 0)
                        _buildSecondaryMetric(
                          theme,
                          'Protein',
                          '${proteinData['current']}kg',
                          proteinData['current']!,
                          proteinData['prev'],
                          false,
                        ),
                      if (bmrData['current']! > 0)
                        _buildSecondaryMetric(
                          theme,
                          'BMR',
                          bmrData['current']!.toStringAsFixed(0),
                          bmrData['current']!,
                          bmrData['prev'],
                          false,
                        ),
                      if (tbwData['current']! > 0)
                        _buildSecondaryMetric(
                          theme,
                          'TBW',
                          '${tbwData['current']}L',
                          tbwData['current']!,
                          tbwData['prev'],
                          false,
                        ),
                      if (fatMassData['current']! > 0)
                        _buildSecondaryMetric(
                          theme,
                          'Fat Mass',
                          '${fatMassData['current']}kg',
                          fatMassData['current']!,
                          fatMassData['prev'],
                          true,
                        ),
                      if (visceralData['current']! > 0)
                        _buildSecondaryMetric(
                          theme,
                          'Visceral',
                          'Lvl ${visceralData['current']!.toStringAsFixed(0)}',
                          visceralData['current']!,
                          visceralData['prev'],
                          true,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryMetric(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    String unit,
    double current,
    double? prev, {
    required bool lowerIsBetter,
    bool visible = true,
  }) {
    if (!visible) return const SizedBox();
    final hasDelta = prev != null && prev > 0 && current != prev;
    final delta = hasDelta ? current - prev : 0.0;
    final isImproving = lowerIsBetter ? delta < 0 : delta > 0;
    final deltaColor = isImproving ? Colors.green : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (hasDelta)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: deltaColor,
              ),
              const SizedBox(width: 2),
              Text(
                delta.abs().toStringAsFixed(1),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSecondaryMetric(
    ThemeData theme,
    String label,
    String value,
    double current,
    double? prev,
    bool lowerIsBetter,
  ) {
    if (current == 0) return const SizedBox();
    final hasDelta = prev != null && prev > 0 && current != prev;
    final delta = hasDelta ? current - prev : 0.0;
    final isImproving = lowerIsBetter ? delta < 0 : delta > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasDelta) ...[
              const SizedBox(width: 2),
              Icon(
                delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                size: 10,
                color: isImproving ? Colors.green : Colors.red,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
