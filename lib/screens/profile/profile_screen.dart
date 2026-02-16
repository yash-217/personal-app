import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';

import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/inbody_ocr_service.dart';
import 'widgets/profile_setup.dart';
import 'widgets/body_metrics_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile == null) {
      return ProfileSetup(
        onCreateProfile: () => _showEditProfileDialog(context, null),
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
                              profile.weightUnit == 'lbs'
                                  ? '${profile.calculatedAge}y · ${profile.height.toStringAsFixed(0)}cm · ${(profile.weight * 2.20462).toStringAsFixed(1)}lbs (${profile.weight.toStringAsFixed(1)}kg)'
                                  : '${profile.calculatedAge}y · ${profile.height.toStringAsFixed(0)}cm · ${profile.weight.toStringAsFixed(1)}kg (${(profile.weight * 2.20462).toStringAsFixed(1)}lbs)',
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
              const BodyMetricsSection(),
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

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _showEditProfileDialog(BuildContext context, UserProfile? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final heightCtrl = TextEditingController(
      text: existing?.height.toStringAsFixed(0) ?? '',
    );
    final weightCtrl = TextEditingController(
      text: existing?.weight.toStringAsFixed(1) ?? '',
    );
    final goalCtrl = TextEditingController(
      text: (existing?.weeklyGoal ?? 4).toString(),
    );
    String unit = existing?.weightUnit ?? 'kg';
    DateTime? selectedBirthDate = existing?.birthDate;

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
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate:
                                    selectedBirthDate ??
                                    DateTime(now.year - 25, now.month, now.day),
                                firstDate: DateTime(1900),
                                lastDate: now,
                                helpText: 'Select Date of Birth',
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
                                style: selectedBirthDate != null
                                    ? Theme.of(ctx).textTheme.bodyMedium
                                    : Theme.of(
                                        ctx,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(ctx).hintColor,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(ctx).hintColor),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: unit,
                              items: const [
                                DropdownMenuItem(
                                  value: 'kg',
                                  child: Text('kg'),
                                ),
                                DropdownMenuItem(
                                  value: 'lbs',
                                  child: Text('lbs'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setModalState(() => unit = val!),
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
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              prefixIcon: Icon(Icons.height),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Weight ($unit)',
                              prefixIcon: const Icon(Icons.monitor_weight),
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
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty ||
                            heightCtrl.text.isEmpty ||
                            weightCtrl.text.isEmpty ||
                            selectedBirthDate == null) {
                          return;
                        }

                        final height = double.tryParse(heightCtrl.text) ?? 0;
                        var weight = double.tryParse(weightCtrl.text) ?? 0;
                        final goal = int.tryParse(goalCtrl.text) ?? 4;

                        // Convert weight to kg if entered in lbs
                        if (unit == 'lbs') {
                          weight = weight / 2.20462;
                        }

                        context.read<ProfileProvider>().updateProfile(
                          name: nameCtrl.text,
                          height: height,
                          weight: weight,
                          birthDate: selectedBirthDate!,
                          weeklyGoal: goal,
                          weightUnit: unit,
                        );

                        Navigator.pop(ctx);
                      },
                      child: const Text('Save Profile'),
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

  void _showAddMetricsDialog(BuildContext context, ProfileProvider provider) {
    final weightCtrl = TextEditingController();
    final bodyFatCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final bmrCtrl = TextEditingController();
    final visceralCtrl = TextEditingController();
    final tbwCtrl = TextEditingController();
    final fatMassCtrl = TextEditingController();
    final muscleMassCtrl = TextEditingController();

    // InBody OCR Service
    final ocrService = InBodyOcrService();
    bool isScanning = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);

            // Function to handle image picking and OCR
            Future<void> pickAndScanImage(ImageSource source) async {
              setModalState(() => isScanning = true);
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: source);

                if (picked != null) {
                  final file = File(picked.path);
                  final result = await ocrService.processImage(file);

                  if (result != null) {
                    // Populate fields with extracted data
                    if (result.weight != null) {
                      weightCtrl.text = result.weight.toString();
                    }
                    if (result.bodyFatPercentage != null) {
                      bodyFatCtrl.text = result.bodyFatPercentage.toString();
                    }
                    // SMM removed
                    if (result.basalMetabolicRate != null) {
                      bmrCtrl.text = result.basalMetabolicRate.toString();
                    }
                    if (result.visceralFatLevel != null) {
                      visceralCtrl.text = result.visceralFatLevel.toString();
                    }
                    if (result.protein != null) {
                      proteinCtrl.text = result.protein.toString();
                    }
                    if (result.totalBodyWater != null) {
                      tbwCtrl.text = result.totalBodyWater.toString();
                    }
                    if (result.bodyFatMass != null) {
                      fatMassCtrl.text = result.bodyFatMass.toString();
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Scanned successfully! Verify values before saving.',
                          ),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not extract data. Please enter manually.',
                          ),
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error scanning: $e')));
                }
              } finally {
                setModalState(() => isScanning = false);
              }
            }

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Measurements',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (isScanning)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          PopupMenuButton<ImageSource>(
                            icon: const Icon(Icons.camera_alt),
                            tooltip: 'Scan InBody Sheet',
                            onSelected: pickAndScanImage,
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: ImageSource.camera,
                                child: Row(
                                  children: [
                                    Icon(Icons.camera),
                                    SizedBox(width: 8),
                                    Text('Take Photo'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: ImageSource.gallery,
                                child: Row(
                                  children: [
                                    Icon(Icons.photo_library),
                                    SizedBox(width: 8),
                                    Text('Choose from Gallery'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: bodyFatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Body Fat (%)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: muscleMassCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Skeletal Muscle Mass (kg)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: proteinCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Protein (kg)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: bmrCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'BMR (kcal)',
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
                            controller: visceralCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Visceral Fat',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: tbwCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'TBW (L)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fatMassCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Body Fat Mass (kg)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        final weight = double.tryParse(weightCtrl.text);
                        if (weight == null) return;

                        provider.addBodyMetrics(
                          weight: weight,
                          bodyFatPercentage:
                              double.tryParse(bodyFatCtrl.text) ?? 0,
                          // SMM removed
                          basalMetabolicRate:
                              double.tryParse(bmrCtrl.text) ?? 0,
                          visceralFatLevel:
                              double.tryParse(visceralCtrl.text) ?? 0,
                          protein: double.tryParse(proteinCtrl.text) ?? 0,
                          totalBodyWater: double.tryParse(tbwCtrl.text) ?? 0,
                          bodyFatMass: double.tryParse(fatMassCtrl.text) ?? 0,
                        );

                        Navigator.pop(ctx);
                      },
                      child: const Text('Save Measurements'),
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
