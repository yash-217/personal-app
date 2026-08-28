import 'package:flutter_test/flutter_test.dart';
import 'package:fitprint/models/day_log.dart';
import 'package:fitprint/models/workout_session.dart';
import 'package:fitprint/models/run_log.dart';
import 'package:fitprint/models/workout_routine.dart';
import 'package:fitprint/models/activity_log.dart';
import 'package:fitprint/providers/workout_provider.dart';
import 'package:fitprint/services/storage_service.dart';

class MockWorkoutStorageService extends Fake implements StorageService {
  List<DayLog> _dayLogs = [];

  @override
  List<DayLog> getAllDayLogs() => List.from(_dayLogs);

  @override
  List<WorkoutSession> getAllSessions() => [];

  @override
  List<RunLog> getAllRunLogs() => [];

  @override
  List<WorkoutRoutine> getAllRoutines() => [];

  @override
  List<ActivityLog> getAllActivityLogs() => [];

  @override
  Future<void> saveDayLog(DayLog log) async {
    final index = _dayLogs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _dayLogs[index] = log;
    } else {
      _dayLogs.add(log);
    }
  }
}

class Fake implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

void main() {
  late MockWorkoutStorageService mockStorage;
  late WorkoutProvider provider;

  setUp(() {
    mockStorage = MockWorkoutStorageService();
  });

  test('allPlankEntries and allPushupEntries return chronological progress starting from first activity', () async {
    final day1 = DayLog(
      id: '2026-01-01',
      date: DateTime(2026, 1, 1),
      activities: [],
      plankSeconds: 30,
      pushupsCount: 15,
    );
    final day2 = DayLog(
      id: '2026-01-05',
      date: DateTime(2026, 1, 5),
      activities: [],
      plankSeconds: 0,
      pushupsCount: 20,
    );
    final day3 = DayLog(
      id: '2026-01-10',
      date: DateTime(2026, 1, 10),
      activities: [],
      plankSeconds: 45,
      pushupsCount: 25,
    );

    mockStorage._dayLogs = [day3, day1, day2]; // intentionally unordered
    provider = WorkoutProvider(mockStorage);

    final plankEntries = provider.allPlankEntries();
    expect(plankEntries.length, 2);
    expect(plankEntries[0].seconds, 30);
    expect(plankEntries[0].date, DateTime(2026, 1, 1));
    expect(plankEntries[1].seconds, 45);
    expect(plankEntries[1].date, DateTime(2026, 1, 10));

    final pushupEntries = provider.allPushupEntries();
    expect(pushupEntries.length, 3);
    expect(pushupEntries[0].count, 15);
    expect(pushupEntries[0].date, DateTime(2026, 1, 1));
    expect(pushupEntries[1].count, 20);
    expect(pushupEntries[1].date, DateTime(2026, 1, 5));
    expect(pushupEntries[2].count, 25);
    expect(pushupEntries[2].date, DateTime(2026, 1, 10));
  });
}
