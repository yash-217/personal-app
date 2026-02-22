import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/profile_provider.dart';

import 'body_metrics_trends.dart';
import 'body_metrics_latest.dart';
import 'body_metrics_history.dart';

import '../../../models/body_metrics.dart';

class BodyMetricsSection extends StatelessWidget {
  final Function(BodyMetrics)? onEdit;
  const BodyMetricsSection({super.key, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final metrics = provider.bodyMetrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          if (metrics.isNotEmpty)
            BodyMetricsLatest(
              metrics: metrics,
              userHeight: provider.profile?.height ?? 0,
            ),

          const SizedBox(height: 24),

          // History
          BodyMetricsHistory(metrics: metrics, onEdit: onEdit),
        ],
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}
