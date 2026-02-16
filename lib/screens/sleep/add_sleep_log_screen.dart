import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/sleep_provider.dart';

class AddSleepLogScreen extends StatefulWidget {
  const AddSleepLogScreen({super.key});

  @override
  State<AddSleepLogScreen> createState() => _AddSleepLogScreenState();
}

class _AddSleepLogScreenState extends State<AddSleepLogScreen> {
  DateTime _date = DateTime.now();
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  bool _avoidedScreentime = false;
  double _quality = 5;
  String? _selectedMood;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _moods = [
    'Rested',
    'Groggy',
    'Tired',
    'Energized',
    'Anxious',
    'Calm',
  ];

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
    // Calculate actual datetimes
    // Bedtime is usually the night before the wake date
    // If bedtime hour is late (e.g. 22:00) and wake time is early (e.g. 07:00),
    // then bedtime is on (date - 1 day).
    // If bedtime is early morning (e.g. 01:00) and wake time is later (e.g. 09:00),
    // then bedtime is on the same day.

    // Simple logic: if bedtime > wakeTime, assume bedtime was yesterday
    // This logic is tricky. Let's assume the user enters the "Sleep Date" as the night they went to bed?
    // Or "Wake Date" as the morning they woke up?
    // The SleepLog model says "date: (The day the user woke up)".

    // So if I wake up on Oct 25th at 7am, date is Oct 25th.
    // Bedtime was likely Oct 24th 10pm.

    DateTime wakeDt = _combineDateAndTime(_date, _wakeTime);
    DateTime bedDt = _combineDateAndTime(_date, _bedtime);

    // If bedtime is after wake time (e.g. bed 22:00, wake 07:00), subtract a day from bedtime
    // Wait, comparing just times isn't enough.
    // Let's assume standard sleep schedule: Bedtime is usually PM, Wake is AM.
    // Or Bedtime AM (post-midnight), Wake AM (later).

    // If wake time is earlier in the day than bedtime, then bedtime must be previous day.
    // Example: Bed 23:00, Wake 07:00 -> Bed is previous day.
    // Example: Bed 01:00, Wake 09:00 -> Both same day.

    // Heuristic: If bedtime hour > wake time hour + 12 (allowing for long sleep), it's previous day?
    // Better: If (bedtime hour >= 12 and wake time hour < 12) -> previous day.
    // This covers standard 10pm -> 7am.

    if (_bedtime.hour > _wakeTime.hour + 8) {
      // Heuristic
      bedDt = bedDt.subtract(const Duration(days: 1));
    }

    // If the calculation results in negative duration, we probably guessed wrong or user entered weird times.
    // But `difference` handles dates correctly.
    // Let's refine:
    // User enters "Wake Date" (The date of the log).
    // User enters Bedtime (Time) and Wake Time (Time).
    // We construct WakeDateTime = WakeDate + WakeTime.
    // We construct BedDateTime = WakeDate + BedTime.
    // If BedDateTime > WakeDateTime, subtract 1 day from BedDateTime.

    if (bedDt.isAfter(wakeDt)) {
      bedDt = bedDt.subtract(const Duration(days: 1));
    }

    // One edge case: Nap? Bed 14:00, Wake 15:00.
    // Above logic: BedDt < WakeDt, so it keeps same day. Correct.

    context.read<SleepProvider>().addLog(
      date: _date,
      bedtime: bedDt,
      wakeTime: wakeDt,
      avoidedScreentime: _avoidedScreentime,
      quality: _quality.round(),
      mood: _selectedMood,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sleep Log'),
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
