import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/day_log.dart';
import '../../providers/workout_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/dashboard_stats_row.dart';
import 'widgets/steps_distance_card.dart';
import 'widgets/activity_stats_card.dart';
import 'widgets/dashboard_fab.dart';
import 'widgets/log_plank_dialog.dart';
import 'widgets/log_pushups_dialog.dart';
import '../workout/workout_session_screen.dart';
import 'add_activity_log_screen.dart';

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

            // Steps & Distance Card
            const SliverToBoxAdapter(child: StepsDistanceCard()),

            // Activity Stats (Activity This Month)
            const SliverToBoxAdapter(child: ActivityStatsCard()),

            // Calendar — scoped rebuild for workout data changes
            SliverToBoxAdapter(
              child: Consumer2<WorkoutProvider, SleepProvider>(
                builder: (context, workout, sleep, _) {
                  final events = workout.getCalendarEvents();
                  // Build a set of dates that have period == true
                  final periodDates = <DateTime>{};
                  for (final log in sleep.logs) {
                    if (log.period == true) {
                      periodDates.add(DateTime(
                        log.date.year,
                        log.date.month,
                        log.date.day,
                      ));
                    }
                  }
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
                          markersMaxCount: 7,
                        ),
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, date, _) {
                            final normalized = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            final activities = events[normalized];
                            final hasPeriod = periodDates.contains(normalized);
                            if ((activities == null || activities.isEmpty) && !hasPeriod) {
                              return null;
                            }
                            return Positioned(
                              bottom: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (activities != null)
                                    ...activities.map((type) {
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
                                        case ActivityType.football:
                                          color = AppColors.football;
                                          break;
                                        case ActivityType.tt:
                                          color = AppColors.tt;
                                          break;
                                        case ActivityType.badminton:
                                          color = AppColors.badminton;
                                          break;
                                        case ActivityType.hockey:
                                          color = AppColors.hockey;
                                          break;
                                      }
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 0.5,
                                        ),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                        ),
                                      );
                                    }),
                                    if (hasPeriod)
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 0.5,
                                        ),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFE91E63), // pink
                                        ),
                                      ),
                                ],
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
    final hasData = dayLog != null && (dayLog.activities.isNotEmpty || (dayLog.plankSeconds ?? 0) > 0 || (dayLog.pushupsCount ?? 0) > 0);
    if (!hasData) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            final currentLog = workout.getDayLogForDate(day);
            final hasCurrentData = currentLog != null && (currentLog.activities.isNotEmpty || (currentLog.plankSeconds ?? 0) > 0 || (currentLog.pushupsCount ?? 0) > 0);
            if (!hasCurrentData) {
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
                      case ActivityType.football:
                        icon = Icons.sports_soccer;
                        label = 'Football';
                        color = AppColors.football;
                        break;
                      case ActivityType.tt:
                        icon = Icons.sports_tennis;
                        label = 'Table Tennis';
                        color = AppColors.tt;
                        break;
                      case ActivityType.badminton:
                        icon = Icons.sports_tennis;
                        label = 'Badminton';
                        color = AppColors.badminton;
                        break;
                      case ActivityType.hockey:
                        icon = Icons.sports_hockey;
                        label = 'Hockey';
                        color = AppColors.hockey;
                        break;
                    }
                    // Look up activity log for detail subtitle
                    final activityLog = workout.getActivityLogForDate(day, type);
                    String? subtitle;
                    if (activityLog != null) {
                      subtitle = '${activityLog.formattedDuration} — RPE ${activityLog.perceivedEffort} (${activityLog.effortLabel})';
                    } else if (type == ActivityType.swim || type == ActivityType.football || type == ActivityType.tt || type == ActivityType.badminton || type == ActivityType.hockey) {
                      subtitle = 'No details recorded';
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
                        subtitle: subtitle != null ? Text(subtitle, style: Theme.of(ctx).textTheme.bodySmall) : null,
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
                            : (activityLog != null)
                                ? () {
                                    Navigator.of(ctx).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => AddActivityLogScreen(
                                          activityType: type,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                      ),
                    );
                  }),
                  // Plank entry (if logged)
                  if ((currentLog.plankSeconds ?? 0) > 0)
                    Slidable(
                      key: ValueKey('${day.toIso8601String()}-plank'),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              await workout.removeDailyPlank(day);
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
                            color: Colors.deepPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('🧘', style: TextStyle(fontSize: 18)),
                        ),
                        title: const Text('Plank'),
                        subtitle: Text(
                          '${currentLog.plankSeconds}s hold',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          showLogPlankDialog(context, date: day);
                        },
                      ),
                    ),
                  // Pushups entry (if logged)
                  if ((currentLog.pushupsCount ?? 0) > 0)
                    Slidable(
                      key: ValueKey('${day.toIso8601String()}-pushups'),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (context) async {
                              await workout.removeDailyPushups(day);
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
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('💪', style: TextStyle(fontSize: 18)),
                        ),
                        title: const Text('Pushups'),
                        subtitle: Text(
                          '${currentLog.pushupsCount} reps',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          showLogPushupsDialog(context, date: day);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
