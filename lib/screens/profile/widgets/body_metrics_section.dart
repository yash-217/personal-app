import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/profile_provider.dart';

import 'body_metrics_trends.dart';
import 'body_metrics_latest.dart';
import 'body_metrics_history.dart';

class BodyMetricsSection extends StatelessWidget {
  const BodyMetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final metrics = provider.bodyMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body Metrics', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),

        if (metrics.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.monitor_weight,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No body measurements yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'Tap + to add your first measurement',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Trend charts (separate)
          if (metrics.length > 1) BodyMetricsTrends(metrics: metrics),

          const SizedBox(height: 8),

          // Latest metrics with deltas
          if (provider.latestMetrics != null)
            BodyMetricsLatest(
              latest: provider.latestMetrics!,
              previous: metrics.length > 1 ? metrics[metrics.length - 2] : null,
            ),

          const SizedBox(height: 24),

          // History
          BodyMetricsHistory(metrics: metrics),
        ],
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}
