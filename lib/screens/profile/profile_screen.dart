import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/profile_provider.dart';
import '../../providers/achievement_provider.dart';
import 'widgets/profile_setup.dart';
import 'widgets/body_metrics_section.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/add_metrics_dialog.dart';
import 'profile_detail_screen.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                            // Mini progress indicator
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
