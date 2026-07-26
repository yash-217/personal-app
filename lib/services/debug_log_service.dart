import 'package:flutter/foundation.dart';

/// In-memory ring-buffer that captures [debugPrint] output so it can be
/// viewed inside the app (Profile → Debug Logs).
///
/// Call [DebugLogService.install] once during app startup — it replaces
/// the global [debugPrint] function with one that also stores every
/// message in a capped list.
class DebugLogService {
  DebugLogService._();
  static final DebugLogService instance = DebugLogService._();

  /// Maximum number of entries kept in memory.
  static const int maxEntries = 500;

  final List<DebugLogEntry> _entries = [];

  /// Read-only view – newest first.
  List<DebugLogEntry> get entries => List.unmodifiable(_entries.reversed);

  /// Replace the global [debugPrint] with a version that also records
  /// every message into [_entries].
  void install() {
    final originalDebugPrint = debugPrint;

    debugPrint = (String? message, {int? wrapWidth}) {
      // Still send to the console via the original implementation.
      originalDebugPrint(message, wrapWidth: wrapWidth);

      if (message != null && message.isNotEmpty) {
        _entries.add(DebugLogEntry(DateTime.now(), message));
        if (_entries.length > maxEntries) {
          _entries.removeAt(0);
        }
      }
    };
  }

  void clear() => _entries.clear();
}

class DebugLogEntry {
  final DateTime timestamp;
  final String message;
  const DebugLogEntry(this.timestamp, this.message);
}
