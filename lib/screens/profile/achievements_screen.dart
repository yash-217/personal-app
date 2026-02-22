import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../models/achievement.dart';
import '../../providers/achievement_provider.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AchievementProvider>();

    // Group badges by category
    const categoryOrder = ['consistency', 'volume', 'endurance', 'recovery'];
    const categoryLabels = {
      'consistency': 'Consistency',
      'volume': 'Volume',
      'endurance': 'Endurance',
      'recovery': 'Recovery',
    };
    const categoryIcons = {
      'consistency': Icons.local_fire_department_rounded,
      'volume': Icons.fitness_center_rounded,
      'endurance': Icons.directions_run_rounded,
      'recovery': Icons.bedtime_rounded,
    };

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Trophy Room',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress summary
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Progress ring
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: provider.totalCount > 0
                                        ? provider.unlockedCount /
                                              provider.totalCount
                                        : 0,
                                    strokeWidth: 6,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    valueColor: AlwaysStoppedAnimation(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${provider.unlockedCount}/${provider.totalCount}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getMotivationalText(
                                      provider.unlockedCount,
                                      provider.totalCount,
                                    ),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${provider.unlockedCount} badge${provider.unlockedCount == 1 ? '' : 's'} unlocked',
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
                    ).animate().fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),

            // Badge categories
            ...categoryOrder.expand((category) {
              final categoryBadges = AchievementProvider.allBadges
                  .where((b) => b.category == category)
                  .toList();
              if (categoryBadges.isEmpty) return <Widget>[];

              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          categoryIcons[category],
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          categoryLabels[category] ?? category,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final badge = categoryBadges[index];
                      final isUnlocked = provider.isUnlocked(badge.id);
                      final achievement = provider.getAchievement(badge.id);

                      return _BadgeTile(
                        badge: badge,
                        isUnlocked: isUnlocked,
                        achievement: achievement,
                        index: index,
                      );
                    }, childCount: categoryBadges.length),
                  ),
                ),
              ];
            }),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  String _getMotivationalText(int unlocked, int total) {
    final ratio = total > 0 ? unlocked / total : 0.0;
    if (ratio == 0) return 'Start your journey!';
    if (ratio < 0.25) return 'Getting started!';
    if (ratio < 0.5) return 'Making progress!';
    if (ratio < 0.75) return 'Almost there!';
    if (ratio < 1.0) return 'So close!';
    return 'Champion! 🎉';
  }
}

// ---------------------------------------------------------------------------
// Badge Tile
// ---------------------------------------------------------------------------
class _BadgeTile extends StatelessWidget {
  final BadgeDefinition badge;
  final bool isUnlocked;
  final Achievement? achievement;
  final int index;

  const _BadgeTile({
    required this.badge,
    required this.isUnlocked,
    this.achievement,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
          elevation: isUnlocked ? 2 : 0,
          color: isUnlocked
              ? null
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showBadgeDetail(context),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isUnlocked ? badge.emoji : '🔒',
                    style: TextStyle(fontSize: isUnlocked ? 32 : 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isUnlocked
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: (index * 50).ms)
        .scale(begin: const Offset(0.8, 0.8), duration: 300.ms);
  }

  void _showBadgeDetail(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Emoji
              Text(
                isUnlocked ? badge.emoji : '🔒',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                badge.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                badge.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Status
              if (isUnlocked && achievement != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Unlocked ${DateFormat.yMMMd().format(achievement!.dateUnlocked)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Not yet unlocked',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    // Mark as viewed
    if (isUnlocked && achievement != null && !achievement!.hasViewed) {
      context.read<AchievementProvider>().markViewed(badge.id);
    }
  }
}
