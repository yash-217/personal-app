import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
import '../workout/workout_session_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

    return Scaffold(
      floatingActionButton: const DashboardFab(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header — only rebuilds when profile name changes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<ProfileProvider>(
                      builder: (context, profile, _) {
                        final name = profile.profile?.name ?? 'there';
                        return Text(
                              '${_getGreeting()}, $name',
                              style: theme.textTheme.headlineMedium,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.1);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Stats Row (Streak Row)
            const SliverToBoxAdapter(child: DashboardStatsRow()),

            // Weekly Progress — scoped rebuild for goal changes
            SliverToBoxAdapter(
              child: Consumer<ProfileProvider>(
                builder: (context, profile, _) {
                  final weeklyGoal = profile.profile?.weeklyGoal ?? 4;
                  return WeeklyProgressCard(weeklyGoal: weeklyGoal);
                },
              ),
            ),

            // Activity Stats (Activity This Month)
            const SliverToBoxAdapter(child: ActivityStatsCard()),

            // Calendar — scoped rebuild for workout data changes
            SliverToBoxAdapter(
              child: Consumer<WorkoutProvider>(
                builder: (context, workout, _) {
                  final events = workout.getCalendarEvents();
                  return Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        selectedDayPredicate: (day) =>
                            isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _showDayDetail(selectedDay);
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
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
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
                },
              ),
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
            final theme = Theme.of(ctx);
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
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    '${day.day}/${day.month}/${day.year}',
                    style: theme.textTheme.headlineMedium,
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
                    return Slidable(
                      key: ValueKey('${day.toIso8601String()}-$type'),
                      startActionPane: type == ActivityType.gym
                          ? ActionPane(
                              motion: const ScrollMotion(),
                              extentRatio: 0.25,
                              children: [
                                SlidableAction(
                                  onPressed: (context) {
                                    final session = workout.getSessionForDate(
                                      day,
                                    );
                                    if (session != null) {
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WorkoutSessionScreen(
                                            existingSession: session,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  icon: Icons.edit_outlined,
                                  label: 'Edit',
                                ),
                              ],
                            )
                          : null,
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              await workout.removeActivity(day, type);
                              setSheetState(() {});
                            },
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            icon: Icons.delete_outline,
                            label: 'Delete',
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        title: Text(label),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        onTap: type == ActivityType.gym
                            ? () {
                                final session = workout.getSessionForDate(day);
                                if (session != null) {
                                  Navigator.of(ctx).pop(); // Close sheet
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => WorkoutSessionScreen(
                                        existingSession: session,
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
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
