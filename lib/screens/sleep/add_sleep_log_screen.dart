import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/sleep_log.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sleep_provider.dart';

class AddSleepLogScreen extends StatefulWidget {
  final SleepLog? existingLog;

  const AddSleepLogScreen({super.key, this.existingLog});

  @override
  State<AddSleepLogScreen> createState() => _AddSleepLogScreenState();
}

class _AddSleepLogScreenState extends State<AddSleepLogScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  bool _avoidedScreentime = false;
  bool _periodToggle = false;
  int _meRating = 0;
  double _quality = 5;
  String? _selectedMood;
  final TextEditingController _notesController = TextEditingController();

  bool get _isEditing => widget.existingLog != null;

  final List<String> _moods = [
    'Rested',
    'Groggy',
    'Tired',
    'Energized',
    'Anxious',
    'Calm',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _date = log.date;
      _bedtime = TimeOfDay.fromDateTime(log.bedtime);
      _wakeTime = TimeOfDay.fromDateTime(log.wakeTime);
      _avoidedScreentime = log.avoidedScreentime;
      _quality = log.quality.toDouble();
      _selectedMood = log.mood;
      _notesController.text = log.notes ?? '';
      _meRating = log.morningErection ?? 0;
      _periodToggle = log.period ?? false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime(bool isBedtime) async {
    final initial = isBedtime ? _bedtime : _wakeTime;
    final picked = await showTimePicker(context: context, initialTime: initial);

    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _save() {
    DateTime wakeDt = _combineDateAndTime(_date, _wakeTime);
    DateTime bedDt = _combineDateAndTime(_date, _bedtime);

    if (_bedtime.hour > _wakeTime.hour + 8) {
      bedDt = bedDt.subtract(const Duration(days: 1));
    }

    if (bedDt.isAfter(wakeDt)) {
      bedDt = bedDt.subtract(const Duration(days: 1));
    }

    final gender =
        context.read<ProfileProvider>().profile?.gender ?? '';

    if (_isEditing) {
      final updated = widget.existingLog!.copyWith(
        date: _date,
        bedtime: bedDt,
        wakeTime: wakeDt,
        avoidedScreentime: _avoidedScreentime,
        quality: _quality.round(),
        mood: _selectedMood,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        morningErection: gender == 'Male' ? _meRating : null,
        period: gender == 'Female' ? _periodToggle : null,
      );
      context.read<SleepProvider>().updateLog(updated);
    } else {
      context.read<SleepProvider>().addLog(
        date: _date,
        bedtime: bedDt,
        wakeTime: wakeDt,
        avoidedScreentime: _avoidedScreentime,
        quality: _quality.round(),
        mood: _selectedMood,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        morningErection: gender == 'Male' ? _meRating : null,
        period: gender == 'Female' ? _periodToggle : null,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Sleep Log' : 'Add Sleep Log'),
        actions: [IconButton(icon: const Icon(Icons.check), onPressed: _save)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            _buildSectionTitle('Date (Morning of)'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(DateFormat.yMMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const Divider(),

            // Times
            _buildSectionTitle('Sleep Schedule'),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bedtime'),
                    subtitle: Text(_bedtime.format(context)),
                    onTap: () => _pickTime(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Wake Up'),
                    subtitle: Text(_wakeTime.format(context)),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Screentime
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Avoided Screentime'),
              subtitle: const Text('1 hour before bed'),
              value: _avoidedScreentime,
              onChanged: (val) => setState(() => _avoidedScreentime = val),
              activeTrackColor: AppColors.seed,
            ),
            // Sex-specific toggle
            Builder(
              builder: (context) {
                final gender =
                    context.watch<ProfileProvider>().profile?.gender ?? '';
                if (gender == 'Male') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Morning Erection: $_meRating/5'),
                      Row(
                        children: List.generate(5, (i) {
                          final starIndex = i + 1;
                          return IconButton(
                            icon: Icon(
                              starIndex <= _meRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: starIndex <= _meRating
                                  ? Colors.amber
                                  : Theme.of(context).colorScheme.outline,
                              size: 32,
                            ),
                            onPressed: () {
                              setState(() {
                                // Tap same star to deselect
                                _meRating =
                                    _meRating == starIndex ? 0 : starIndex;
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  );
                } else if (gender == 'Female') {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Period?'),
                    value: _periodToggle,
                    onChanged: (val) =>
                        setState(() => _periodToggle = val),
                    activeTrackColor: AppColors.seed,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(),

            // Quality
            _buildSectionTitle('Quality: ${_quality.round()}/10'),
            Slider(
              value: _quality,
              min: 1,
              max: 10,
              divisions: 9,
              label: _quality.round().toString(),
              onChanged: (val) => setState(() => _quality = val),
            ),
            const Divider(),

            // Mood
            _buildSectionTitle('Morning Mood'),
            Wrap(
              spacing: 8,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood;
                return ChoiceChip(
                  label: Text(mood),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedMood = selected ? mood : null);
                  },
                );
              }).toList(),
            ),
            const Divider(),

            // Notes
            _buildSectionTitle('Notes'),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Dreams, interruptions, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
