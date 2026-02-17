import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/body_metrics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/profile_provider.dart';

class BodyMetricsTrends extends StatefulWidget {
  final List<BodyMetrics> metrics;

  const BodyMetricsTrends({super.key, required this.metrics});

  @override
  State<BodyMetricsTrends> createState() => _BodyMetricsTrendsState();
}

class _BodyMetricsTrendsState extends State<BodyMetricsTrends> {
  String _selectedMetric = 'Weight';
  String _selectedRange = 'All'; // '7D', '30D', '90D', 'All'

  final List<String> _metricsList = ['Weight', 'Body Fat %', 'BMI'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredMetrics = _getFilteredMetrics();

    if (filteredMetrics.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Progress Analytics', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildMetricSelector(theme),
        const SizedBox(height: 12),
        _buildTrendInsights(theme, filteredMetrics),
        const SizedBox(height: 12),
        _buildInteractiveChart(theme, filteredMetrics),
        const SizedBox(height: 12),
        _buildRangeSelector(theme),
      ],
    );
  }

  Widget _buildMetricSelector(ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _metricsList.map((metric) {
          final isSelected = _selectedMetric == metric;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(metric, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedMetric = metric);
              },
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRangeSelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ['7D', '30D', '90D', 'All'].map((range) {
        final isSelected = _selectedRange == range;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: InkWell(
            onTap: () => setState(() => _selectedRange = range),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                range,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendInsights(ThemeData theme, List<BodyMetrics> metrics) {
    final first = _getMetricValue(metrics.first);
    final last = _getMetricValue(metrics.last);
    final diff = last - first;
    final color = diff <= 0 ? Colors.green : Colors.red;
    final unit = _getUnit();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              theme,
              'Total Change',
              '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} $unit',
              color: color,
            ),
            _buildStatItem(
              theme,
              'Starting',
              '${first.toStringAsFixed(1)} $unit',
            ),
            _buildStatItem(theme, 'Latest', '${last.toStringAsFixed(1)} $unit'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveChart(ThemeData theme, List<BodyMetrics> metrics) {
    if (metrics.length < 2) {
      return Card(
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Need at least 2 entries for trend line',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final spots = metrics.map((m) {
      final x = m.date.millisecondsSinceEpoch.toDouble();
      final y = _getMetricValue(m);
      return FlSpot(x, y);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yPadding = (maxY - minY) * 0.15;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.dividerColor.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        value.toInt(),
                      );
                      if (meta.min == value || meta.max == value) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat.MMMd().format(date),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.seed,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.seed,
                          strokeWidth: 2,
                          strokeColor:
                              theme.cardTheme.color ??
                              theme.colorScheme.surface,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.seed.withValues(alpha: 0.2),
                        AppColors.seed.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.surfaceContainer,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        spot.x.toInt(),
                      );
                      return LineTooltipItem(
                        '${DateFormat.MMMd().format(date)}\n${spot.y.toStringAsFixed(1)} ${_getUnit()}',
                        theme.textTheme.labelSmall!.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              minY: minY - yPadding,
              maxY: maxY + yPadding,
            ),
          ),
        ),
      ),
    );
  }

  List<BodyMetrics> _getFilteredMetrics() {
    // Sort by date ascending for the chart
    final list = List<BodyMetrics>.from(widget.metrics);
    list.sort((a, b) => a.date.compareTo(b.date));

    // Filter out entries where the selected metric is 0 (missing data)
    final listWithData = list.where((m) => _getMetricValue(m) > 0).toList();

    if (_selectedRange == 'All') return listWithData;

    final now = DateTime.now();
    final days = _selectedRange == '7D'
        ? 7
        : (_selectedRange == '30D' ? 30 : 90);
    final cutoff = now.subtract(Duration(days: days));

    return listWithData.where((m) => m.date.isAfter(cutoff)).toList();
  }

  double _getMetricValue(BodyMetrics m) {
    switch (_selectedMetric) {
      case 'Weight':
        return m.weight;
      case 'Body Fat %':
        return m.bodyFatPercentage;
      case 'BMI':
        if (m.bmi > 0) return m.bmi;
        // Fallback calculation if BMI is not stored
        final profile = context.read<ProfileProvider>().profile;
        if (profile != null && profile.height > 0) {
          final heightM = profile.height / 100;
          return m.weight / (heightM * heightM);
        }
        return 0;
      default:
        return 0;
    }
  }

  String _getUnit() {
    switch (_selectedMetric) {
      case 'Weight':
        return 'kg';
      case 'Body Fat %':
        return '%';
      case 'BMI':
        return '';
      default:
        return '';
    }
  }
}
