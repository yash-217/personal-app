import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_provider.dart';

/// Dialog for logging daily pushup count.
Future<void> showLogPushupsDialog(BuildContext context, {DateTime? date}) async {
  final targetDate = date ?? DateTime.now();
  final workout = context.read<WorkoutProvider>();
  final existing = workout.getPushupsCountForDate(targetDate);

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
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('💪', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Text('Log Pushups'),
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
                labelText: 'Count',
                suffixText: 'reps',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'e.g. 25',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [10, 15, 20, 25, 50].map((c) {
                return ActionChip(
                  label: Text('$c'),
                  onPressed: () => controller.text = '$c',
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
              final count = int.tryParse(controller.text) ?? 0;
              if (count > 0) {
                workout.updateDailyPushups(targetDate, count);
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
