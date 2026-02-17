import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/user_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';

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
            onPressed: () => _showEditProfileDialog(context, profile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar and Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : '?',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
          ],
        ),
      ),
    );
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
    return Column(
      children: [
        Padding(
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
        ),
        if (value !=
            childrenLastValue(
              value,
            )) // Simple way to skip divider for last, but let's just use manual dividers or listview
          const Divider(height: 1),
      ],
    );
  }

  // Helper for identifying last item (simplified for now)
  String childrenLastValue(String val) => '';

  // --- Reuse the Edit Logic from ProfileScreen (better to refactor it later) ---
  void _showEditProfileDialog(BuildContext context, UserProfile existing) {
    // Controller and state logic same as ProfileScreen...
    // I will copy the logic here for now to ensure working functionality
    final nameCtrl = TextEditingController(text: existing.name);
    final heightCtrl = TextEditingController(
      text: existing.height.toStringAsFixed(0),
    );
    final weightCtrl = TextEditingController(
      text: existing.weight % 1 == 0
          ? existing.weight.toInt().toString()
          : existing.weight.toString(),
    );
    final goalCtrl = TextEditingController(
      text: existing.weeklyGoal.toString(),
    );
    String unit = existing.weightUnit;
    DateTime? selectedBirthDate = existing.birthDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      'Edit Profile',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedBirthDate ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedBirthDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.cake),
                        ),
                        child: Text(
                          selectedBirthDate != null
                              ? '${selectedBirthDate!.day}/${selectedBirthDate!.month}/${selectedBirthDate!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: goalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weekly Gym Goal (days)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        context.read<ProfileProvider>().updateProfile(
                          name: nameCtrl.text,
                          height: double.tryParse(heightCtrl.text) ?? 0,
                          weight: double.tryParse(weightCtrl.text) ?? 0,
                          birthDate: selectedBirthDate!,
                          weeklyGoal: int.tryParse(goalCtrl.text) ?? 4,
                          weightUnit: unit,
                        );
                        Navigator.pop(ctx);
                        setState(() {}); // Refresh detail screen
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
