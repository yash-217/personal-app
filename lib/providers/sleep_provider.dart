import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_log.dart';
import '../services/storage_service.dart';

class SleepProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final StorageService _storage;
  List<SleepLog> _logs = [];

  SleepProvider(this._storage) {
    _loadData();
  }

  List<SleepLog> get logs => _logs;

  void _loadData() {
    _logs = _storage.getAllSleepLogs();
    notifyListeners();
  }

  Future<void> addLog({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    bool avoidedScreentime = false,
    int quality = 5,
    String? mood,
    String? notes,
  }) async {
    final log = SleepLog(
      id: _uuid.v4(),
      date: date,
      bedtime: bedtime,
      wakeTime: wakeTime,
      avoidedScreentime: avoidedScreentime,
      quality: quality,
      mood: mood,
      notes: notes,
    );
    await _storage.saveSleepLog(log);
    _logs.insert(0, log);
    notifyListeners();
  }

  Future<void> updateLog(SleepLog log) async {
    await _storage.saveSleepLog(log);
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
      notifyListeners();
    }
  }

  Future<void> deleteLog(String id) async {
    await _storage.deleteSleepLog(id);
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  // --- Stats ---

  String get avgDuration {
    if (_logs.isEmpty) return '0h 0m';
    final totalMinutes = _logs.fold(0, (sum, log) => sum + log.durationMinutes);
    final avgMinutes = totalMinutes ~/ _logs.length;
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  double get avgQuality {
    if (_logs.isEmpty) return 0;
    final totalQuality = _logs.fold(0, (sum, log) => sum + log.quality);
    return totalQuality / _logs.length;
  }

  /// Percentage of logs where screentime was avoided
  double get screentimeAvoidanceRate {
    if (_logs.isEmpty) return 0;
    final avoidedCount = _logs.where((l) => l.avoidedScreentime).length;
    return (avoidedCount / _logs.length) * 100;
  }

  /// Returns sleep duration for the last 7 days for charting
  List<double> get weeklySleepDuration {
    // Return last 7 days of data, filling missing days with 0
    // This is a simplified version, ideally we'd map to specific days
    return _logs
        .take(7)
        .map((l) => l.durationMinutes / 60.0)
        .toList()
        .reversed
        .toList();
  }
}
