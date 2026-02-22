import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A configurable rest timer widget for use between workout sets.
/// Shows a circular countdown with duration selection chips.
class RestTimerWidget extends StatefulWidget {
  final VoidCallback? onDismiss;

  const RestTimerWidget({super.key, this.onDismiss});

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget>
    with SingleTickerProviderStateMixin {
  static const List<int> _presets = [30, 60, 90, 120];

  int _selectedSeconds = 60;
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _selectedSeconds;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resume() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _onComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _selectedSeconds;
      _isRunning = false;
    });
  }

  void _onComplete() {
    setState(() {
      _remainingSeconds = 0;
      _isRunning = false;
    });
    // Haptic feedback
    HapticFeedback.heavyImpact();
    // Pulse animation
    _pulseController.forward(from: 0);
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _selectedSeconds > 0
        ? _remainingSeconds / _selectedSeconds
        : 0.0;
    final isDone = !_isRunning && _remainingSeconds == 0 && _timer == null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.timer_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rest Timer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: widget.onDismiss,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Circular timer
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        isDone
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    isDone ? 'GO!' : _formatTime(_remainingSeconds),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDone
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Duration chips
            Wrap(
              spacing: 8,
              children: _presets.map((seconds) {
                final isSelected = _selectedSeconds == seconds;
                return ChoiceChip(
                  label: Text('${seconds}s'),
                  selected: isSelected,
                  onSelected: _isRunning
                      ? null
                      : (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSeconds = seconds;
                              _remainingSeconds = seconds;
                            });
                          }
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRunning && _remainingSeconds == _selectedSeconds) ...[
                  // Start
                  FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                  ),
                ] else if (_isRunning) ...[
                  // Pause + Reset
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _pause,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pause'),
                  ),
                ] else ...[
                  // Resume + Reset (paused or done)
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                  ),
                  if (_remainingSeconds > 0) ...[
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _resume,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Resume'),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
