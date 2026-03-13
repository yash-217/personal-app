import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/sleep_provider.dart';
import '../../models/sleep_log.dart';
import 'add_sleep_log_screen.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracker'), centerTitle: false),
      body: Consumer<SleepProvider>(
        builder: (context, provider, _) {
          if (provider.logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sleep logs yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _navigateToAddLog(context),
                    child: const Text('Add First Log'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCards(context, provider),
              const SizedBox(height: 24),
              _buildWeeklyChart(context, provider),
              const SizedBox(height: 24),
              Text(
                'Recent Sleep',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ...provider.logs.map((log) => _buildLogItem(context, log)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_sleep_log',
        onPressed: () => _navigateToAddLog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _navigateToAddLog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSleepLogScreen()),
    );
  }

  Widget _buildSummaryCards(BuildContext context, SleepProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Avg Duration',
            provider.avgDuration,
            Icons.access_time,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Avg Quality',
            provider.avgQuality.toStringAsFixed(1),
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'No Screen',
            '${provider.screentimeAvoidanceRate.toStringAsFixed(0)}%',
            Icons.phonelink_off,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, SleepProvider provider) {
    final windows = provider.weeklySleepWindows;
    final theme = Theme.of(context);

    final bounds = provider.sleepChartBounds;
    // Invert the chart: earlier times (lower numbers) at the top, later times at bottom.
    // In fl_chart, Y increases upwards, so we use negative values to reverse.
    final minY = -bounds.maxY;
    final maxY = -bounds.minY;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last 7 Days', style: theme.textTheme.titleMedium),
              const Icon(Icons.show_chart, size: 16, color: AppColors.seed),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: minY,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => theme.colorScheme.surfaceContainer,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final from = rod.fromY.abs();
                      final to = rod.toY.abs();
                      // In our inverted chart, fromY is bedtime, toY is wakeTime
                      final startH = from.toInt() % 24;
                      final startM = ((from - from.toInt()) * 60).toInt();
                      final endH = to.toInt() % 24;
                      final endM = ((to - to.toInt()) * 60).toInt();
                      return BarTooltipItem(
                        '${startH.toString().padLeft(2, '0')}:${startM.toString().padLeft(2, '0')} - '
                        '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}',
                        theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        if (value > maxY || value < minY) {
                          return const SizedBox.shrink();
                        }
                        final hour = value.abs().toInt() % 24;
                        return Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: -provider.avgBedtime,
                      color: Colors.red.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                    HorizontalLine(
                      y: -provider.avgWakeTime,
                      color: Colors.green.withValues(alpha: 0.5),
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                barGroups: windows.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        fromY: -e.value.from,
                        toY: -e.value.to,
                        color: AppColors.seed,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, SleepLog log) {
    final dateFormat = DateFormat.MMMd();
    final timeFormat = DateFormat.jm();

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Log?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<SleepProvider>().deleteLog(log.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(log.date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  log.formattedDuration,
                  style: const TextStyle(
                    color: AppColors.seed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.bedtime,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(timeFormat.format(log.bedtime)),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.wb_sunny,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(timeFormat.format(log.wakeTime)),
                ],
              ),
              if (log.notes != null || log.mood != null || log.morningErection == true) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (log.mood != null)
                      Chip(
                        label: Text(log.mood!),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                    if (log.morningErection == true)
                      Chip(
                        avatar: const Icon(Icons.check_circle, size: 14, color: Colors.green),
                        label: const Text('ME'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                      ),
                  ],
                ),
                if (log.notes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      log.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ],
          ),
          leading: CircleAvatar(
            backgroundColor: _getQualityColor(
              log.quality,
            ).withValues(alpha: 0.2),
            child: Text(
              log.quality.toString(),
              style: TextStyle(
                color: _getQualityColor(log.quality),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getQualityColor(int quality) {
    if (quality >= 8) return Colors.green;
    if (quality >= 5) return Colors.amber;
    return Colors.red;
  }
}
