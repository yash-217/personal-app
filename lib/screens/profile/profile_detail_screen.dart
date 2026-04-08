import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/data_export_service.dart';
import '../../services/cloud_sync_service.dart';
import 'package:intl/intl.dart';
import 'widgets/edit_profile_dialog.dart';
import 'debug_log_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('No profile found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showEditProfileDialog(context, profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar and Name — show Google photo if signed in
            Center(
              child: Consumer<AuthProvider>(
                builder: (_, authProvider, _) {
                  final photoUrl = authProvider.photoUrl;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: theme.colorScheme.primary,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Text(
                                profile.name.isNotEmpty
                                    ? profile.name[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Info Sections
            _buildSectionHeader(theme, 'Personal Information'),
            _buildInfoCard(theme, [
              _buildInfoRow(
                theme,
                Icons.cake_outlined,
                'Date of Birth',
                '${profile.birthDate?.day ?? '??'}/${profile.birthDate?.month ?? '??'}/${profile.birthDate?.year ?? '??'} (${profile.calculatedAge} years)',
              ),
              _buildInfoRow(
                theme,
                Icons.height,
                'Height',
                '${profile.height.toStringAsFixed(0)} cm',
              ),
              _buildInfoRow(
                theme,
                Icons.monitor_weight_outlined,
                'Current Weight',
                '${profile.weight.toStringAsFixed(1)} kg (${(profile.weight * 2.20462).toStringAsFixed(1)} lbs)',
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionHeader(theme, 'Goals'),
            _buildInfoCard(theme, [
              _buildInfoRow(
                theme,
                Icons.flag_outlined,
                'Weekly Gym Goal',
                '${profile.weeklyGoal} days per week',
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionHeader(theme, 'Settings'),
            _buildInfoCard(theme, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.scale_outlined),
                title: const Text('Weight Unit'),
                trailing: DropdownButton<String>(
                  value: profile.weightUnit,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'kg',
                      child: Text('Kilograms (kg)'),
                    ),
                    DropdownMenuItem(value: 'lbs', child: Text('Pounds (lbs)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      context.read<ProfileProvider>().updateProfile(
                        name: profile.name,
                        height: profile.height,
                        weight: profile.weight,
                        birthDate: profile.birthDate,
                        weeklyGoal: profile.weeklyGoal,
                        weightUnit: val,
                      );
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              Consumer<ThemeProvider>(
                builder: (_, themeProvider, _) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode_outlined,
                  ),
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Cloud Sync Section
            _buildSectionHeader(theme, 'Cloud Sync'),
            Consumer<AuthProvider>(
              builder: (_, authProvider, _) {
                if (authProvider.isLoading) {
                  return _buildInfoCard(theme, [
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ]);
                }

                if (!authProvider.isSignedIn) {
                  return _buildInfoCard(theme, [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.login_rounded),
                      title: const Text('Sign in with Google'),
                      subtitle: const Text('Sync your data across devices'),
                      onTap: () async {
                        final user = await authProvider.signInWithGoogle();
                        if (user != null && context.mounted) {
                          // Update profile name from Google if the current one is generic
                          final profileProvider = context
                              .read<ProfileProvider>();
                          final currentProfile = profileProvider.profile;
                          if (currentProfile != null &&
                              user.displayName != null &&
                              user.displayName!.isNotEmpty) {
                            profileProvider.updateProfile(
                              name: user.displayName!,
                              height: currentProfile.height,
                              weight: currentProfile.weight,
                              birthDate: currentProfile.birthDate,
                              weeklyGoal: currentProfile.weeklyGoal,
                              weightUnit: currentProfile.weightUnit,
                            );
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Signed in as ${user.displayName ?? user.email}',
                                ),
                              ),
                            );
                          }
                        }
                        if (authProvider.error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sign-in failed: ${authProvider.error}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ]);
                }

                // Signed in — show user info & sync options
                return _buildInfoCard(theme, [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundImage: authProvider.photoUrl != null
                          ? NetworkImage(authProvider.photoUrl!)
                          : null,
                      child: authProvider.photoUrl == null
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                    title: Text(authProvider.displayName ?? 'Google User'),
                    subtitle: Text(authProvider.email ?? ''),
                  ),
                  const Divider(height: 1),
                  Builder(
                    builder: (ctx) {
                      final storage = ctx.read<ProfileProvider>().storage;
                      final lastAutoBackup =
                          CloudSyncService(storage).lastAutoBackupTime;
                      final label = lastAutoBackup != null
                          ? DateFormat.yMMMd().add_jm().format(lastAutoBackup)
                          : 'Not yet';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.autorenew_rounded),
                        title: const Text('Weekly Auto-Backup'),
                        subtitle: Text('Last: $label'),
                        dense: true,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_upload_rounded),
                    title: const Text('Backup to Cloud'),
                    subtitle: const Text('Upload all data to Firebase'),
                    onTap: () => _performBackup(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_download_rounded),
                    title: const Text('Restore from Cloud'),
                    subtitle: const Text('Check cloud for available backup'),
                    onTap: () => _peekCloudData(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.logout_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signed out')),
                        );
                      }
                    },
                  ),
                ]);
              },
            ),

            const SizedBox(height: 24),

            _buildSectionHeader(theme, 'Data'),
            _buildInfoCard(theme, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_file_rounded),
                title: const Text('Export Data'),
                subtitle: const Text('Save all data as JSON'),
                onTap: () async {
                  try {
                    final storage = context.read<ProfileProvider>().storage;
                    final exportService = DataExportService(storage);
                    await exportService.exportAndShare();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: $e')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download_rounded),
                title: const Text('Import Data'),
                subtitle: const Text('Restore from JSON backup'),
                onTap: () async {
                  try {
                    final storage = context.read<ProfileProvider>().storage;
                    final exportService = DataExportService(storage);
                    final counts = await exportService.importFromFile();
                    if (counts != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Found: ${counts.entries.where((e) => e.value > 0).map((e) => '${e.value} ${e.key}').join(', ')}',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Import failed: $e')),
                      );
                    }
                  }
                },
              ),
            ]),

            const SizedBox(height: 24),

            _buildSectionHeader(theme, 'Developer'),
            _buildInfoCard(theme, [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Debug Logs'),
                subtitle: const Text('View in-app diagnostic messages'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DebugLogScreen(),
                    ),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _performBackup(BuildContext context) async {
    try {
      final storage = context.read<ProfileProvider>().storage;
      final syncService = CloudSyncService(storage);

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backing up...')));
      }

      final counts = await syncService.backup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backup complete: ${counts.entries.where((e) => e.value > 0).map((e) => '${e.value} ${e.key}').join(', ')}',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _peekCloudData(BuildContext context) async {
    try {
      final storage = context.read<ProfileProvider>().storage;
      final syncService = CloudSyncService(storage);
      final counts = await syncService.peekCloudData();

      if (!context.mounted) return;

      if (counts == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No cloud backup found')));
        return;
      }

      final summary = counts.entries
          .where((e) => e.value > 0)
          .map((e) => '${e.value} ${e.key}')
          .join(', ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloud backup contains: $summary'),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to check cloud: $e')));
      }
    }
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
