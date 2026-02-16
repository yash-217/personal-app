import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/day_log.dart';
import '../../providers/workout_provider.dart';
import '../../providers/profile_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/dashboard_stats_row.dart';
import 'widgets/weekly_progress_card.dart';
import 'widgets/activity_stats_card.dart';
import 'widgets/dashboard_fab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
    final events = workout.getCalendarEvents();

    return Scaffold(
      floatingActionButton: const DashboardFab(),
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
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Stats Row (Streak Row)
            const SliverToBoxAdapter(child: DashboardStatsRow()),

            // Weekly Progress
            SliverToBoxAdapter(
              child: WeeklyProgressCard(weeklyGoal: weeklyGoal),
            ),

            // Activity Stats (Activity This Month)
            const SliverToBoxAdapter(child: ActivityStatsCard()),

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

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
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
                          await workout.toggleActivity(day, type);
                          setSheetState(() {});
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
