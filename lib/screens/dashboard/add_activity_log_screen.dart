import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/day_log.dart';
import '../../models/activity_log.dart';
import '../../providers/workout_provider.dart';
import '../../core/theme/app_colors.dart';

class AddActivityLogScreen extends StatefulWidget {
  final ActivityType activityType;

  const AddActivityLogScreen({super.key, required this.activityType});

  @override
  State<AddActivityLogScreen> createState() => _AddActivityLogScreenState();
}

class _AddActivityLogScreenState extends State<AddActivityLogScreen> {
  final _durationController = TextEditingController(text: '60');
  final _notesController = TextEditingController();
  int _perceivedEffort = 5;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _activityName {
    switch (widget.activityType) {
      case ActivityType.swim:
        return 'Swim';
      case ActivityType.football:
        return 'Football';
      case ActivityType.tt:
        return 'Table Tennis';
      case ActivityType.badminton:
        return 'Badminton';
      case ActivityType.hockey:
        return 'Hockey';
      default:
        return 'Activity';
    }
  }

  IconData get _activityIcon {
    switch (widget.activityType) {
      case ActivityType.swim:
        return Icons.pool;
      case ActivityType.football:
        return Icons.sports_soccer;
      case ActivityType.tt:
        return Icons.sports_tennis;
      case ActivityType.badminton:
        return Icons.sports_tennis;
      case ActivityType.hockey:
        return Icons.sports_hockey;
      default:
        return Icons.sports;
    }
  }

  Color get _activityColor {
    switch (widget.activityType) {
      case ActivityType.swim:
        return AppColors.swim;
      case ActivityType.football:
        return AppColors.football;
      case ActivityType.tt:
        return AppColors.tt;
      case ActivityType.badminton:
        return AppColors.badminton;
      case ActivityType.hockey:
        return AppColors.hockey;
      default:
        return AppColors.swim;
    }
  }

  String _effortLabel(int value) {
    switch (value) {
      case 1:
      case 2:
        return 'Very Light';
      case 3:
      case 4:
        return 'Light';
      case 5:
      case 6:
        return 'Moderate';
      case 7:
      case 8:
        return 'Hard';
      case 9:
        return 'Very Hard';
      case 10:
        return 'Max Effort';
      default:
        return 'Moderate';
    }
  }

  Future<void> _save() async {
    final duration = int.tryParse(_durationController.text) ?? 0;

    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a duration')),
      );
      return;
    }

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final log = ActivityLog(
      id: const Uuid().v4(),
      date: dateTime,
      type: widget.activityType,
      durationMinutes: duration,
      perceivedEffort: _perceivedEffort,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    await context.read<WorkoutProvider>().addActivityLog(log);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _activityColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Log $_activityName'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Activity header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_activityIcon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _activityName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),

            // Time picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),

            const SizedBox(height: 16),

            // Duration
            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                prefixIcon: Icon(Icons.timer),
              ),
            ),

            const SizedBox(height: 24),

            // RPE Slider
            Text(
              'Perceived Effort',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _perceivedEffort.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: color,
                    label: '$_perceivedEffort',
                    onChanged: (value) {
                      setState(() => _perceivedEffort = value.round());
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_perceivedEffort — ${_effortLabel(_perceivedEffort)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes — optional',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
