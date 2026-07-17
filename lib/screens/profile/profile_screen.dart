import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/profile_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/health_sync_service.dart';
import '../../services/storage_service.dart';
import 'widgets/profile_setup.dart';
import 'widgets/body_metrics_section.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/add_metrics_dialog.dart';
import 'profile_detail_screen.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile == null) {
      return ProfileSetup(
        onCreateProfile: () => showEditProfileDialog(context, null),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Profile',
                style: theme.textTheme.headlineMedium,
              ).animate().fadeIn(),

              const SizedBox(height: 16),

              // Profile card
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileDetailScreen(),
                      ),
                    );
                  },
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
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              // Achievements card
              Consumer<AchievementProvider>(
                builder: (context, achievements, _) {
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.emoji_events_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Achievements',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${achievements.unlockedCount} / ${achievements.totalCount} badges unlocked',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                value: achievements.totalCount > 0
                                    ? achievements.unlockedCount /
                                          achievements.totalCount
                                    : 0,
                                strokeWidth: 3,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms);
                },
              ),

              const SizedBox(height: 8),

              // Health Sync card
              _HealthSyncCard(
                isSyncing: _isSyncing,
                onSyncStart: () => setState(() => _isSyncing = true),
                onSyncEnd: () => setState(() => _isSyncing = false),
              ),

              // Body Metrics section
              BodyMetricsSection(
                onEdit: (metrics) =>
                    showAddMetricsDialog(context, provider, existing: metrics),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddMetricsDialog(context, provider),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// Health Connect / Apple Health sync settings card.
class _HealthSyncCard extends StatefulWidget {
  final bool isSyncing;
  final VoidCallback onSyncStart;
  final VoidCallback onSyncEnd;

  const _HealthSyncCard({
    required this.isSyncing,
    required this.onSyncStart,
    required this.onSyncEnd,
  });

  @override
  State<_HealthSyncCard> createState() => _HealthSyncCardState();
}

class _HealthSyncCardState extends State<_HealthSyncCard> {
  late HealthSyncService _healthSync;

  @override
  void initState() {
    super.initState();
    _healthSync = HealthSyncService(StorageService.instance);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Connect',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sync steps, distance & more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Health Sync'),
              value: _healthSync.isEnabled,
              onChanged: (val) async {
                if (val) {
                  final granted = await _healthSync.requestAuthorization();
                  if (!granted) return;
                }
                setState(() => _healthSync.isEnabled = val);
              },
            ),
            if (_healthSync.isEnabled) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sync on App Start'),
                subtitle: const Text('Fast 2-day sync, throttled to every 2h'),
                value: _healthSync.syncOnStart,
                onChanged: (val) {
                  setState(() => _healthSync.syncOnStart = val);
                },
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.isSyncing
                          ? null
                          : () async {
                              widget.onSyncStart();
                              try {
                                final records =
                                    await _healthSync.manualSync();
                                if (context.mounted && records.isNotEmpty) {
                                  final workout =
                                      context.read<WorkoutProvider>();
                                  await workout
                                      .applyHealthSyncRecords(records);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Synced ${records.length} days of health data',
                                        ),
                                      ),
                                    );
                                  }
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No new data to sync'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Sync error: $e')),
                                  );
                                }
                              }
                              widget.onSyncEnd();
                            },
                      icon: widget.isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync),
                      label: Text(widget.isSyncing ? 'Syncing...' : 'Sync Now'),
                    ),
                  ),
                ],
              ),
              if (_healthSync.lastSyncTime != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Last sync: ${_formatTime(_healthSync.lastSyncTime!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
