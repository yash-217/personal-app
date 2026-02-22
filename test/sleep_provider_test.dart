import 'package:flutter_test/flutter_test.dart';
import 'package:fitprint/models/sleep_log.dart';
import 'package:fitprint/providers/sleep_provider.dart';
import 'package:fitprint/services/storage_service.dart';

// Manual Mock
class MockStorageService extends Fake implements StorageService {
  List<SleepLog> _logs = [];

  @override
  List<SleepLog> getAllSleepLogs() => List.from(_logs);

  @override
  Future<void> saveSleepLog(SleepLog log) async {
    // Simulate saving by updating internal list if needed,
    // but Provider manages its own list too.
    // In a real app, Provider reloads or updates its list.
    // strict implementation:
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
    } else {
      _logs.add(log);
    }
  }

  @override
  Future<void> deleteSleepLog(String id) async {
    _logs.removeWhere((l) => l.id == id);
  }
}

// Minimal implementation of Fake to avoid implementing all overrides if `implements` was used.
// But since we extend Fake, we only need to override what we use.
class Fake implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

void main() {
  late MockStorageService mockStorage;
  late SleepProvider provider;

  setUp(() {
    mockStorage = MockStorageService();
    provider = SleepProvider(mockStorage);
  });

  test('Initial state is empty', () {
    expect(provider.logs, isEmpty);
    expect(provider.avgDuration, '0h 0m');
    expect(provider.avgQuality, 0);
    expect(provider.screentimeAvoidanceRate, 0);
  });

  test('Adding a log updates stats', () async {
    final now = DateTime.now();
    final bed = now.subtract(const Duration(hours: 8));
    final wake = now;

    await provider.addLog(
      date: now,
      bedtime: bed,
      wakeTime: wake,
      avoidedScreentime: true,
      quality: 8,
    );

    expect(provider.logs.length, 1);
    expect(provider.avgDuration, '8h 0m');
    expect(provider.avgQuality, 8.0);
    expect(provider.screentimeAvoidanceRate, 100.0);
  });

  test('Stats calculation with multiple logs', () {
    // We need to pre-populate the mock and then init provider
    final log1 = SleepLog(
      id: '1',
      date: DateTime(2023, 1, 1),
      bedtime: DateTime(2023, 1, 1, 22),
      wakeTime: DateTime(2023, 1, 2, 6), // 8 hours
      avoidedScreentime: true,
      quality: 8,
    );

    final log2 = SleepLog(
      id: '2',
      date: DateTime(2023, 1, 2),
      bedtime: DateTime(2023, 1, 2, 23),
      wakeTime: DateTime(2023, 1, 3, 5), // 6 hours
      avoidedScreentime: false,
      quality: 6,
    );

    mockStorage._logs = [log1, log2];
    provider = SleepProvider(mockStorage); // Loads data from mock

    expect(provider.logs.length, 2);
    // Avg duration: (8+6)/2 = 7 hours
    expect(provider.avgDuration, '7h 0m');
    // Avg quality: (8+6)/2 = 7
    expect(provider.avgQuality, 7.0);
    // Screentime: 1/2 = 50%
    expect(provider.screentimeAvoidanceRate, 50.0);
  });
}
