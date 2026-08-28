import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fitprint/models/day_log.dart';
import 'package:fitprint/models/workout_session.dart';
import 'package:fitprint/models/run_log.dart';
import 'package:fitprint/models/workout_routine.dart';
import 'package:fitprint/models/activity_log.dart';
import 'package:fitprint/providers/workout_provider.dart';
import 'package:fitprint/screens/profile/widgets/plank_pushup_trends.dart';
import 'package:fitprint/services/storage_service.dart';
import 'package:fl_chart/fl_chart.dart';

class MockStorage extends Fake implements StorageService {
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
}

class Fake implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(invocation.memberName.toString());
  }
}

void main() {
  testWidgets('PlankPushupTrends displays 7d, 30d, and Progress views with line charts simultaneously', (tester) async {
    final mockStorage = MockStorage();
    final now = DateTime.now();

    mockStorage._dayLogs = [
      DayLog(
        id: '1',
        date: now.subtract(const Duration(days: 10)),
        activities: [],
        plankSeconds: 30,
        pushupsCount: 15,
      ),
      DayLog(
        id: '2',
        date: now.subtract(const Duration(days: 2)),
        activities: [],
        plankSeconds: 45,
        pushupsCount: 25,
      ),
      DayLog(
        id: '3',
        date: now,
        activities: [],
        plankSeconds: 60,
        pushupsCount: 35,
      ),
    ];

    final workoutProvider = WorkoutProvider(mockStorage);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<WorkoutProvider>.value(
            value: workoutProvider,
            child: const SingleChildScrollView(
              child: PlankPushupTrends(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and titles exist
    expect(find.text('Plank & Pushups'), findsOneWidget);
    expect(find.text('🧘 Plank Hold'), findsOneWidget);
    expect(find.text('💪 Pushups'), findsOneWidget);

    // Initial state is 7d (both are BarCharts)
    expect(find.byType(BarChart), findsNWidgets(2));
    expect(find.byType(LineChart), findsNothing);

    // Find the single Progress segment button in the section header and tap it
    final progressButton = find.text('Progress');
    expect(progressButton, findsOneWidget);

    await tester.tap(progressButton);
    await tester.pumpAndSettle();

    // Both pushup and plank charts simultaneously switch to LineChart
    expect(find.byType(LineChart), findsNWidgets(2));
    expect(find.byType(BarChart), findsNothing);

    // Switch back to 30d
    final thirtyDaysButton = find.text('30d');
    await tester.tap(thirtyDaysButton);
    await tester.pumpAndSettle();

    // Both switch back to BarChart simultaneously
    expect(find.byType(BarChart), findsNWidgets(2));
    expect(find.byType(LineChart), findsNothing);
  });
}
