import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile.dart';
import '../../../providers/profile_provider.dart';

/// Shows a bottom sheet dialog for creating or editing a user profile.
void showEditProfileDialog(BuildContext context, UserProfile? existing) {
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
  String selectedGender = existing?.gender ?? '';
  DateTime? selectedBirthDate = existing?.birthDate;

  final formKey = GlobalKey<FormState>();

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
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null ? 'Create Profile' : 'Edit Profile',
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
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
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender.isEmpty ? null : selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Sex',
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (val) =>
                          setModalState(() => selectedGender = val ?? ''),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: heightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Height (cm)',
                              prefixIcon: Icon(Icons.height),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final v = double.tryParse(value);
                              if (v == null || v <= 0 || v > 300) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: weightCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: Icon(Icons.monitor_weight),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final v = double.tryParse(value);
                              if (v == null || v <= 0 || v > 500) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: goalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weekly Gym Goal (days)',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final v = int.tryParse(value);
                        if (v == null || v < 1 || v > 7) {
                          return '1-7 days';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        if (selectedBirthDate == null) return;

                        final height = double.tryParse(heightCtrl.text) ?? 0;
                        final weight = double.tryParse(weightCtrl.text) ?? 0;
                        final goal = int.tryParse(goalCtrl.text) ?? 4;

                        context.read<ProfileProvider>().updateProfile(
                          name: nameCtrl.text.trim(),
                          height: height,
                          weight: weight,
                          gender: selectedGender,
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
            ),
          );
        },
      );
    },
  );
}
