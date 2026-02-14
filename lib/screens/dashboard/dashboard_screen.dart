import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/day_log.dart';
import '../../providers/workout_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import '../workout/workout_session_screen.dart';
import 'run_import_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workout = context.watch<WorkoutProvider>();
    final profile = context.watch<ProfileProvider>();
    final name = profile.profile?.name ?? 'there';
    final weeklyGoal = profile.profile?.weeklyGoal ?? 4;
    final gymThisWeek = workout.gymDaysThisWeek();
    final events = workout.getCalendarEvents();

    return Scaffold(
      floatingActionButton: _buildExpandableFab(workout),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, $name',
                      style: theme.textTheme.headlineMedium,
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 4),
                    Text(
                      '🔥 ${workout.currentStreak} day streak',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Calendar
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _showDayDetail(selectedDay);
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      markersMaxCount: 3,
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, _) {
                        final normalized = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        final activities = events[normalized];
                        if (activities == null || activities.isEmpty) {
                          return null;
                        }
                        return Positioned(
                          bottom: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: activities.map((type) {
                              Color color;
                              switch (type) {
                                case ActivityType.gym:
                                  color = AppColors.gym;
                                  break;
                                case ActivityType.run:
                                  color = AppColors.run;
                                  break;
                                case ActivityType.swim:
                                  color = AppColors.swim;
                                  break;
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
            ),

            // Weekly Progress
            SliverToBoxAdapter(
              child: _buildWeeklyProgress(
                theme,
                gymThisWeek,
                weeklyGoal,
                workout,
              ),
            ),

            // Activity Stats
            SliverToBoxAdapter(child: _buildActivityStats(theme, workout)),

            // Stats Row
            SliverToBoxAdapter(child: _buildStatsRow(theme, workout)),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(
    ThemeData theme,
    int gymThisWeek,
    int weeklyGoal,
    WorkoutProvider workout,
  ) {
    final progress = weeklyGoal > 0
        ? (gymThisWeek / weeklyGoal).clamp(0.0, 1.0)
        : 0.0;
    final exceeded = gymThisWeek > weeklyGoal;
    final adherence = workout.weeklyAdherenceLastFourWeeks();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weekly Progress', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation(
                          exceeded
                              ? AppColors.success
                              : theme.colorScheme.primary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$gymThisWeek/$weeklyGoal',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (exceeded)
                            Text('🎉', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (weeklyGoal + 2).toDouble(),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
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
                                const weeks = ['W1', 'W2', 'W3', 'W4'];
                                return Text(
                                  weeks[value.toInt()],
                                  style: theme.textTheme.labelSmall,
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        barGroups: List.generate(4, (i) {
                          final val = adherence.length > i
                              ? adherence[i].toDouble()
                              : 0.0;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: val,
                                color: val >= weeklyGoal
                                    ? AppColors.success
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(4),
                                width: 16,
                              ),
                            ],
                          );
                        }),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: weeklyGoal.toDouble(),
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.5,
                              ),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  Widget _buildActivityStats(ThemeData theme, WorkoutProvider workout) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity This Month', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActivityStat(
                  theme,
                  icon: Icons.directions_run,
                  color: AppColors.run,
                  label: 'Runs',
                  value: '${workout.runsThisMonth}',
                  subtitle:
                      '${workout.totalRunDistanceThisMonth.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 16),
                _buildActivityStat(
                  theme,
                  icon: Icons.pool,
                  color: AppColors.swim,
                  label: 'Swims',
                  value: '${workout.swimsThisMonth}',
                  subtitle: 'this month',
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildActivityStat(
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(color: color),
                ),
                Text(subtitle, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, WorkoutProvider workout) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildStatCard(
            theme,
            'Total\nWorkouts',
            '${workout.totalGymDays}',
            Icons.fitness_center,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            'Current\nStreak',
            '${workout.currentStreak}',
            Icons.local_fire_department,
          ),
          const SizedBox(width: 8),
          _buildStatCard(
            theme,
            'Best\nStreak',
            '${workout.bestStreak}',
            Icons.emoji_events,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 400.ms);
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Expandable FAB ---
  Widget _buildExpandableFab(WorkoutProvider workout) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs
        ..._buildMiniFabs(workout),
        const SizedBox(height: 12),
        // Main FAB
        FloatingActionButton(
          heroTag: 'dashboardMainFab',
          onPressed: _toggleFab,
          child: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (_, child) {
              return Transform.rotate(
                angle: _fabAnimation.value * pi * 0.75,
                child: child,
              );
            },
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMiniFabs(WorkoutProvider workout) {
    final items = [
      _FabItem(
        icon: Icons.fitness_center,
        label: 'Gym',
        color: AppColors.gym,
        onTap: () {
          _toggleFab();
          _showGymOptions();
        },
      ),
      _FabItem(
        icon: Icons.directions_run,
        label: 'Run',
        color: AppColors.run,
        onTap: () {
          _toggleFab();
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RunImportScreen()));
        },
      ),
      _FabItem(
        icon: Icons.pool,
        label: 'Swim',
        color: AppColors.swim,
        onTap: () {
          _toggleFab();
          workout.toggleActivity(DateTime.now(), ActivityType.swim);
        },
      ),
    ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      return AnimatedBuilder(
        animation: _fabAnimation,
        builder: (_, child) {
          final delay = (items.length - 1 - index) * 0.15;
          final progress =
              (_fabAnimation.value - delay).clamp(0.0, 1.0) /
              (1.0 - delay).clamp(0.01, 1.0);
          return Transform.translate(
            offset: Offset(0, (1 - progress) * 20),
            child: Opacity(opacity: progress.clamp(0.0, 1.0), child: child),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                heroTag: 'fab_${item.label}',
                backgroundColor: item.color,
                foregroundColor: Colors.white,
                onPressed: item.onTap,
                child: Icon(item.icon),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _showGymOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final workout = ctx.watch<WorkoutProvider>();
        final routines = workout.routines;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Start Workout',
                  style: Theme.of(ctx).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.gym.withValues(alpha: 0.1),
                  child: const Icon(Icons.add, color: AppColors.gym),
                ),
                title: const Text('Empty Workout'),
                subtitle: const Text('Start from scratch'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WorkoutSessionScreen(),
                    ),
                  );
                },
              ),
              if (routines.isNotEmpty) ...[
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    'Quick Start Routine',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: routines.length,
                    itemBuilder: (context, index) {
                      final routine = routines[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Card(
                          color: Color(routine.color).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Color(
                                routine.color,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WorkoutSessionScreen(
                                    initialExercises: routine.exerciseIds,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    routine.name,
                                    style: Theme.of(ctx).textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${routine.estimatedDuration} min',
                                    style: Theme.of(ctx).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // --- Day Detail Sheet ---
  void _showDayDetail(DateTime day) {
    final workout = context.read<WorkoutProvider>();
    final dayLog = workout.getDayLogForDate(day);
    if (dayLog == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final currentLog = workout.getDayLogForDate(day);
            if (currentLog == null || currentLog.activities.isEmpty) {
              Navigator.of(ctx).pop();
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    '${day.day}/${day.month}/${day.year}',
                    style: Theme.of(ctx).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  ...currentLog.activities.map((type) {
                    IconData icon;
                    String label;
                    Color color;
                    switch (type) {
                      case ActivityType.gym:
                        icon = Icons.fitness_center;
                        label = 'Gym';
                        color = AppColors.gym;
                        break;
                      case ActivityType.run:
                        icon = Icons.directions_run;
                        label = 'Run';
                        color = AppColors.run;
                        break;
                      case ActivityType.swim:
                        icon = Icons.pool;
                        label = 'Swim';
                        color = AppColors.swim;
                        break;
                    }
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      title: Text(label),
                      contentPadding: EdgeInsets.zero,
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(ctx).colorScheme.error,
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Delete Activity'),
                              content: Text('Remove $label from this day?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dCtx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(dCtx).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      dCtx,
                                    ).colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await workout.removeActivity(day, type);
                            if (ctx.mounted) {
                              setSheetState(() {});
                            }
                          }
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _FabItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FabItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
