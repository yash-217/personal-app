import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_provider.dart';

/// Dialog for logging daily plank hold duration in seconds.
Future<void> showLogPlankDialog(BuildContext context, {DateTime? date}) async {
  final targetDate = date ?? DateTime.now();
  final workout = context.read<WorkoutProvider>();
  final existing = workout.getPlankSecondsForDate(targetDate);

  final controller = TextEditingController(
    text: existing > 0 ? '$existing' : '',
  );

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('🧘', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Text('Log Plank'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${targetDate.day}/${targetDate.month}/${targetDate.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Duration',
                suffixText: 'seconds',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'e.g. 60',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [30, 45, 60, 90, 120].map((s) {
                return ActionChip(
                  label: Text('${s}s'),
                  onPressed: () => controller.text = '$s',
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final seconds = int.tryParse(controller.text) ?? 0;
              if (seconds > 0) {
                workout.updateDailyPlank(targetDate, seconds);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
