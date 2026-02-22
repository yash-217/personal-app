import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/body_metrics.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/inbody_ocr_service.dart';

/// Shows a bottom sheet dialog for adding or editing body metrics.
void showAddMetricsDialog(
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

  final ocrService = InBodyOcrService();
  bool isScanning = false;
  final formKey = GlobalKey<FormState>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);

          Future<void> pickAndScanImage(ImageSource source) async {
            setModalState(() => isScanning = true);
            try {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: source);

              if (picked != null) {
                final file = File(picked.path);
                final result = await ocrService.processImage(file);

                if (result != null) {
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
              child: Form(
                key: formKey,
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
                          child: TextFormField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              isDense: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final v = double.tryParse(value);
                              if (v == null || v <= 0) {
                                return 'Invalid weight';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: bodyFatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Body Fat (%)',
                              isDense: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final v = double.tryParse(value);
                              if (v == null || v < 0 || v > 100) {
                                return '0-100%';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
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
                        if (!formKey.currentState!.validate()) return;

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
            ),
          );
        },
      );
    },
  );
}
