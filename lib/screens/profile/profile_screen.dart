import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../models/body_metrics.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/inbody_ocr_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile == null) {
      return _buildSetupScreen(context, theme);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Profile', style: theme.textTheme.headlineMedium),
                  Row(
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (_, themeProvider, _) => IconButton(
                          icon: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showEditProfileDialog(context, profile),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // Profile card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${profile.age}y · ${profile.height.toStringAsFixed(0)}cm · ${profile.weight.toStringAsFixed(1)}kg',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              'Weekly goal: ${profile.weeklyGoal} gym days',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              // BMI card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('BMI', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            profile.bmi.toStringAsFixed(1),
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: _bmiColor(profile.bmi),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _bmiColor(
                                profile.bmi,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile.bmiCategory,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _bmiColor(profile.bmi),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              // Body Metrics section
              _buildBodyMetricsSection(context, theme, provider),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMetricsDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSetupScreen(BuildContext context, ThemeData theme) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to FitPrint!',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Set up your profile to get started.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => _showEditProfileDialog(context, null),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create Profile'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyMetricsSection(
    BuildContext context,
    ThemeData theme,
    ProfileProvider provider,
  ) {
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
          if (metrics.length > 1) _buildSeparateTrendCharts(theme, metrics),

          const SizedBox(height: 8),

          // Latest metrics with deltas
          if (provider.latestMetrics != null)
            _buildLatestMetrics(
              theme,
              provider.latestMetrics!,
              metrics.length > 1 ? metrics[metrics.length - 2] : null,
            ),

          const SizedBox(height: 24),

          // History
          _buildHistoryList(theme, metrics),
        ],
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildSeparateTrendCharts(ThemeData theme, List<BodyMetrics> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trends', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        // Weight Chart
        _buildSingleTrendChart(
          theme,
          title: 'Weight',
          unit: 'kg',
          color: theme.colorScheme.primary,
          data: metrics.map((m) => m.weight).toList(),
          isDashed: false,
        ),
        const SizedBox(height: 12),
        // Body Fat % Chart
        if (metrics.any((m) => m.bodyFatPercentage > 0))
          _buildSingleTrendChart(
            theme,
            title: 'Body Fat',
            unit: '%',
            color: Colors.orange,
            data: metrics.map((m) => m.bodyFatPercentage).toList(),
            isDashed: true,
          ),
        const SizedBox(height: 12),
        // Protein Chart
        if (metrics.any((m) => m.protein > 0))
          _buildSingleTrendChart(
            theme,
            title: 'Protein',
            unit: 'kg',
            color: Colors.blue,
            data: metrics.map((m) => m.protein).toList(),
            isDashed: false,
            isCurved: false, // Dotted/Straight style
          ),
      ],
    );
  }

  Widget _buildSingleTrendChart(
    ThemeData theme, {
    required String title,
    required String unit,
    required Color color,
    required List<double> data,
    bool isDashed = false,
    bool isCurved = true,
  }) {
    final validData = data.where((v) => v > 0).toList();
    if (validData.length < 2) return const SizedBox.shrink();

    final spots = validData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final maxY = validData.reduce((curr, next) => curr > next ? curr : next);
    final minY = validData.reduce((curr, next) => curr < next ? curr : next);
    final interval = (maxY - minY) == 0 ? 1.0 : (maxY - minY) / 4;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title ($unit)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval > 0 ? interval : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.1),
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
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value == minY || value == maxY) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                value.toStringAsFixed(1),
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => theme.colorScheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit',
                            theme.textTheme.labelSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: isCurved,
                      color: color,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      dashArray: isDashed ? [5, 5] : null,
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: minY * 0.95,
                  maxY: maxY * 1.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(ThemeData theme, List<BodyMetrics> metrics) {
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

  Widget _buildLatestMetrics(
    ThemeData theme,
    BodyMetrics latest,
    BodyMetrics? previous,
  ) {
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

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _showEditProfileDialog(BuildContext context, UserProfile? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl = TextEditingController(text: existing?.age.toString() ?? '');
    final heightCtrl = TextEditingController(
      text: existing?.height.toStringAsFixed(0) ?? '',
    );
    final weightCtrl = TextEditingController(
      text: existing?.weight.toStringAsFixed(1) ?? '',
    );
    final goalCtrl = TextEditingController(
      text: (existing?.weeklyGoal ?? 4).toString(),
    );

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Create Profile' : 'Edit Profile',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: goalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Weekly Goal',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final profile = UserProfile(
                      name: name,
                      age: int.tryParse(ageCtrl.text) ?? 25,
                      height: double.tryParse(heightCtrl.text) ?? 170,
                      weight: double.tryParse(weightCtrl.text) ?? 70,
                      gender: 'male',
                      weeklyGoal: int.tryParse(goalCtrl.text) ?? 4,
                    );
                    context.read<ProfileProvider>().saveProfile(profile);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMetricsDialog(BuildContext context, ProfileProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _AddMetricsSheet(provider: provider);
      },
    );
  }
}

// --- Modern Add Metrics Bottom Sheet ---
class _AddMetricsSheet extends StatefulWidget {
  final ProfileProvider provider;

  const _AddMetricsSheet({required this.provider});

  @override
  State<_AddMetricsSheet> createState() => _AddMetricsSheetState();
}

class _AddMetricsSheetState extends State<_AddMetricsSheet> {
  final _weightCtrl = TextEditingController();
  final _bfCtrl = TextEditingController();
  final _bmrCtrl = TextEditingController();
  final _bmiCtrl = TextEditingController();
  final _bfMassCtrl = TextEditingController();
  final _tbwCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _mineralsCtrl = TextEditingController();
  final _visceralCtrl = TextEditingController();
  final _whrCtrl = TextEditingController();
  final _calorieCtrl = TextEditingController();

  final _ocrService = InBodyOcrService();
  bool _isProcessing = false;
  DateTime? _ocrTestDate;
  File? _selectedImage;
  bool _showSecondary = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _bfCtrl.dispose();
    _bmrCtrl.dispose();
    _bmiCtrl.dispose();
    _bfMassCtrl.dispose();
    _tbwCtrl.dispose();
    _proteinCtrl.dispose();
    _mineralsCtrl.dispose();
    _visceralCtrl.dispose();
    _whrCtrl.dispose();
    _calorieCtrl.dispose();
    super.dispose();
  }

  Future<void> _importFromInBody() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _isProcessing = true;
      _ocrTestDate = null;
    });

    final result = await _ocrService.processImage(File(picked.path));

    if (result != null && mounted) {
      setState(() {
        if (result.weight != null) {
          _weightCtrl.text = result.weight!.toStringAsFixed(1);
        }
        if (result.bodyFatPercentage != null) {
          _bfCtrl.text = result.bodyFatPercentage!.toStringAsFixed(1);
        }
        if (result.basalMetabolicRate != null) {
          _bmrCtrl.text = result.basalMetabolicRate!.toStringAsFixed(0);
        }
        if (result.bmi != null) {
          _bmiCtrl.text = result.bmi!.toStringAsFixed(1);
        }
        if (result.bodyFatMass != null) {
          _bfMassCtrl.text = result.bodyFatMass!.toStringAsFixed(1);
        }
        if (result.totalBodyWater != null) {
          _tbwCtrl.text = result.totalBodyWater!.toStringAsFixed(1);
        }
        if (result.protein != null) {
          _proteinCtrl.text = result.protein!.toStringAsFixed(1);
        }
        if (result.minerals != null) {
          _mineralsCtrl.text = result.minerals!.toStringAsFixed(2);
        }
        if (result.visceralFatLevel != null) {
          _visceralCtrl.text = result.visceralFatLevel!.toStringAsFixed(0);
        }
        if (result.waistHipRatio != null) {
          _whrCtrl.text = result.waistHipRatio!.toStringAsFixed(2);
        }
        if (result.recommendedCalorieIntake != null) {
          _calorieCtrl.text = result.recommendedCalorieIntake!.toStringAsFixed(
            0,
          );
        }
        // Store test date from OCR for saving
        if (result.testDate != null) {
          _ocrTestDate = result.testDate;
        }
        // Show secondary fields if OCR found them
        if (result.bmi != null ||
            result.bodyFatMass != null ||
            result.totalBodyWater != null) {
          _showSecondary = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ InBody data extracted successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not extract data. Try a clearer image.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    setState(() => _isProcessing = false);
  }

  void _save() {
    final weight = double.tryParse(_weightCtrl.text);
    if (weight == null || weight <= 0) return;
    widget.provider.addBodyMetrics(
      weight: weight,
      bodyFatPercentage: double.tryParse(_bfCtrl.text) ?? 0,
      basalMetabolicRate: double.tryParse(_bmrCtrl.text) ?? 0,
      bmi: double.tryParse(_bmiCtrl.text) ?? 0,
      bodyFatMass: double.tryParse(_bfMassCtrl.text) ?? 0,
      totalBodyWater: double.tryParse(_tbwCtrl.text) ?? 0,
      protein: double.tryParse(_proteinCtrl.text) ?? 0,
      minerals: double.tryParse(_mineralsCtrl.text) ?? 0,
      visceralFatLevel: double.tryParse(_visceralCtrl.text) ?? 0,
      waistHipRatio: double.tryParse(_whrCtrl.text) ?? 0,
      recommendedCalorieIntake: double.tryParse(_calorieCtrl.text) ?? 0,
      date: _ocrTestDate,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        0,
        0,
        MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.monitor_weight_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Body Measurement',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          'Record or import your stats',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Import from InBody button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _importFromInBody,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(_isProcessing ? 'Processing...' : 'Import'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Primary Metrics
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Metrics',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModernField(
                        controller: _weightCtrl,
                        label: 'Weight',
                        suffix: 'kg',
                        icon: Icons.monitor_weight_outlined,
                        autofocus: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernField(
                              controller: _bfCtrl,
                              label: 'Body Fat',
                              suffix: '%',
                              icon: Icons.pie_chart_outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernField(
                              controller: _bmiCtrl,
                              label: 'BMI',
                              icon: Icons.speed_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernField(
                              controller: _bmrCtrl,
                              label: 'BMR',
                              suffix: 'kcal',
                              icon: Icons.local_fire_department_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildModernField(
                              controller: _visceralCtrl,
                              label: 'Visceral Fat',
                              suffix: 'lvl',
                              icon: Icons.warning_amber_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Secondary metrics toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showSecondary = !_showSecondary),
                icon: Icon(
                  _showSecondary ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                label: Text(
                  _showSecondary
                      ? 'Hide Additional Metrics'
                      : 'Show Additional Metrics',
                ),
              ),
            ),

            if (_showSecondary) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Additional Metrics',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                controller: _bfMassCtrl,
                                label: 'Fat Mass',
                                suffix: 'kg',
                                icon: Icons.scale_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                controller: _tbwCtrl,
                                label: 'Total Body Water',
                                suffix: 'L',
                                icon: Icons.water_drop_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildModernField(
                                controller: _proteinCtrl,
                                label: 'Protein',
                                suffix: 'kg',
                                icon: Icons.egg_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildModernField(
                                controller: _mineralsCtrl,
                                label: 'Minerals',
                                suffix: 'kg',
                                icon: Icons.diamond_outlined,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildModernField(
                                controller: _whrCtrl,
                                label: 'Waist-Hip',
                                suffix: 'ratio',
                                icon: Icons.straighten_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildModernField(
                          controller: _calorieCtrl,
                          label: 'Recommended Calories',
                          suffix: 'kcal',
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Save Measurement'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    required IconData icon,
    bool autofocus = false,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }
}
