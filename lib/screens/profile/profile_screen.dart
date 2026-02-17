import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../models/body_metrics.dart';

import '../../providers/profile_provider.dart';
import '../../services/inbody_ocr_service.dart';
import 'widgets/profile_setup.dart';
import 'widgets/body_metrics_section.dart';
import 'profile_detail_screen.dart';

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

              // Body Metrics section
              BodyMetricsSection(
                onEdit: (metrics) =>
                    _showAddMetricsDialog(context, provider, existing: metrics),
              ),
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

  void _showEditProfileDialog(BuildContext context, UserProfile? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final heightCtrl = TextEditingController(
      text: existing?.height.toStringAsFixed(0) ?? '',
    );
    final weightCtrl = TextEditingController(
      text: existing != null
          ? (existing.weight % 1 == 0
                ? existing.weight.toInt().toString()
                : existing.weight.toString())
          : '',
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
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: Icon(Icons.monitor_weight),
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
                        final weight = double.tryParse(weightCtrl.text) ?? 0;
                        final goal = int.tryParse(goalCtrl.text) ?? 4;

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

  void _showAddMetricsDialog(
    BuildContext context,
    ProfileProvider provider, {
    BodyMetrics? existing,
  }) {
    final weightCtrl = TextEditingController(
      text: existing?.weight.toString() ?? '',
    );
    final bodyFatCtrl = TextEditingController(
      text: existing != null && existing.bodyFatPercentage > 0
          ? existing.bodyFatPercentage.toString()
          : '',
    );
    final recommendedCaloriesCtrl = TextEditingController(
      text: existing != null && existing.recommendedCalorieIntake > 0
          ? existing.recommendedCalorieIntake.toInt().toString()
          : '',
    );
    final proteinCtrl = TextEditingController(
      text: existing != null && existing.protein > 0
          ? existing.protein.toString()
          : '',
    );
    final bmrCtrl = TextEditingController(
      text: existing != null && existing.basalMetabolicRate > 0
          ? existing.basalMetabolicRate.toString()
          : '',
    );
    final visceralCtrl = TextEditingController(
      text: existing != null && existing.visceralFatLevel > 0
          ? existing.visceralFatLevel.toString()
          : '',
    );
    final tbwCtrl = TextEditingController(
      text: existing != null && existing.totalBodyWater > 0
          ? existing.totalBodyWater.toString()
          : '',
    );
    final fatMassCtrl = TextEditingController(
      text: existing != null && existing.bodyFatMass > 0
          ? existing.bodyFatMass.toString()
          : '',
    );

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
                    if (result.recommendedCalorieIntake != null) {
                      recommendedCaloriesCtrl.text = result
                          .recommendedCalorieIntake!
                          .toInt()
                          .toString();
                    }
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
                          existing == null
                              ? 'Add Measurements'
                              : 'Edit Measurements',
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

                    // Primary Metrics
                    Text(
                      'Primary Metrics',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              isDense: true,
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
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: recommendedCaloriesCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Recommended Daily Calories (kcal)',
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          'Additional Metrics',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: bmrCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'BMR (kcal)',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: visceralCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Visceral Fat',
                                    isDense: true,
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
                                  controller: proteinCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Protein (kg)',
                                    isDense: true,
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
                                    isDense: true,
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
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        final weight = double.tryParse(weightCtrl.text);
                        if (weight == null) return;

                        if (existing != null) {
                          provider.updateBodyMetrics(
                            existing.copyWith(
                              weight: weight,
                              bodyFatPercentage:
                                  double.tryParse(bodyFatCtrl.text) ?? 0,
                              recommendedCalorieIntake:
                                  double.tryParse(
                                    recommendedCaloriesCtrl.text,
                                  ) ??
                                  0,
                              basalMetabolicRate:
                                  double.tryParse(bmrCtrl.text) ?? 0,
                              visceralFatLevel:
                                  double.tryParse(visceralCtrl.text) ?? 0,
                              protein: double.tryParse(proteinCtrl.text) ?? 0,
                              totalBodyWater:
                                  double.tryParse(tbwCtrl.text) ?? 0,
                              bodyFatMass:
                                  double.tryParse(fatMassCtrl.text) ?? 0,
                            ),
                          );
                        } else {
                          provider.addBodyMetrics(
                            weight: weight,
                            bodyFatPercentage:
                                double.tryParse(bodyFatCtrl.text) ?? 0,
                            recommendedCalorieIntake:
                                double.tryParse(recommendedCaloriesCtrl.text) ??
                                0,
                            basalMetabolicRate:
                                double.tryParse(bmrCtrl.text) ?? 0,
                            visceralFatLevel:
                                double.tryParse(visceralCtrl.text) ?? 0,
                            protein: double.tryParse(proteinCtrl.text) ?? 0,
                            totalBodyWater: double.tryParse(tbwCtrl.text) ?? 0,
                            bodyFatMass: double.tryParse(fatMassCtrl.text) ?? 0,
                          );
                        }

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
