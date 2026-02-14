import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/exercise.dart';
import '../models/day_log.dart';
import '../models/workout_session.dart';
import '../models/run_log.dart';
import '../models/weight_entry.dart';
import '../models/user_profile.dart';
import '../models/body_metrics.dart';
import '../models/workout_routine.dart';

class StorageService {
  static const String _exercisesBox = 'exercises';
  static const String _dayLogsBox = 'dayLogs';
  static const String _sessionsBox = 'workoutSessions';
  static const String _runLogsBox = 'runLogs';
  static const String _weightEntriesBox = 'weightEntries';
  static const String _profileBox = 'userProfile';
  static const String _bodyMetricsBox = 'bodyMetrics';
  static const String _settingsBox = 'settings';
  static const String _routinesBox = 'workoutRoutines';

  late Box<Exercise> exercisesBox;
  late Box<DayLog> dayLogsBox;
  late Box<WorkoutSession> sessionsBox;
  late Box<RunLog> runLogsBox;
  late Box<WeightEntry> weightEntriesBox;
  late Box<UserProfile> profileBox;
  late Box<BodyMetrics> bodyMetricsBox;
  late Box settingsBox;
  late Box<WorkoutRoutine> routinesBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(ActivityTypeAdapter());
    Hive.registerAdapter(DayLogAdapter());
    Hive.registerAdapter(WorkoutSessionAdapter());
    Hive.registerAdapter(RunLogAdapter());
    Hive.registerAdapter(WeightEntryAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(BodyMetricsAdapter());
    Hive.registerAdapter(WorkoutRoutineAdapter());
    Hive.registerAdapter(WorkoutSetAdapter());
    Hive.registerAdapter(ExerciseHistoryEntryAdapter());

    // Open boxes
    exercisesBox = await Hive.openBox<Exercise>(_exercisesBox);
    dayLogsBox = await Hive.openBox<DayLog>(_dayLogsBox);
    sessionsBox = await Hive.openBox<WorkoutSession>(_sessionsBox);
    runLogsBox = await Hive.openBox<RunLog>(_runLogsBox);
    weightEntriesBox = await Hive.openBox<WeightEntry>(_weightEntriesBox);
    profileBox = await Hive.openBox<UserProfile>(_profileBox);
    bodyMetricsBox = await Hive.openBox<BodyMetrics>(_bodyMetricsBox);
    settingsBox = await Hive.openBox(_settingsBox);
    routinesBox = await Hive.openBox<WorkoutRoutine>(_routinesBox);
  }

  // --- Exercises ---
  List<Exercise> getAllExercises() => exercisesBox.values.toList();

  Future<void> cacheExercises(List<Exercise> exercises) async {
    await exercisesBox.clear();
    for (final ex in exercises) {
      await exercisesBox.put(ex.id, ex);
    }
  }

  Future<void> saveExercise(Exercise ex) async {
    await exercisesBox.put(ex.id, ex);
  }

  bool get hasExercisesCache => exercisesBox.isNotEmpty;

  // --- Day Logs ---
  List<DayLog> getAllDayLogs() => dayLogsBox.values.toList();

  DayLog? getDayLog(String dateKey) {
    try {
      return dayLogsBox.values.firstWhere((d) => d.dateKey == dateKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDayLog(DayLog log) async {
    await dayLogsBox.put(log.id, log);
  }

  Future<void> deleteDayLog(String id) async {
    await dayLogsBox.delete(id);
  }

  // --- Workout Sessions ---
  List<WorkoutSession> getAllSessions() => sessionsBox.values.toList();

  WorkoutSession? getSession(String id) => sessionsBox.get(id);

  Future<void> saveSession(WorkoutSession session) async {
    await sessionsBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await sessionsBox.delete(id);
  }

  // --- Run Logs ---
  List<RunLog> getAllRunLogs() => runLogsBox.values.toList();

  RunLog? getRunLog(String id) => runLogsBox.get(id);

  Future<void> saveRunLog(RunLog log) async {
    await runLogsBox.put(log.id, log);
  }

  Future<void> deleteRunLog(String id) async {
    await runLogsBox.delete(id);
  }

  // --- Weight Entries ---
  List<WeightEntry> getAllWeightEntries() => weightEntriesBox.values.toList();

  List<WeightEntry> getWeightEntriesForExercise(String exerciseId) {
    return weightEntriesBox.values
        .where((e) => e.exerciseId == exerciseId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> saveWeightEntry(WeightEntry entry) async {
    await weightEntriesBox.put(entry.id, entry);
  }

  Future<void> deleteWeightEntry(String id) async {
    await weightEntriesBox.delete(id);
  }

  // --- User Profile ---
  UserProfile? getProfile() {
    if (profileBox.isEmpty) return null;
    return profileBox.values.first;
  }

  Future<void> saveProfile(UserProfile profile) async {
    await profileBox.clear();
    await profileBox.add(profile);
  }

  // --- Body Metrics ---
  List<BodyMetrics> getAllBodyMetrics() {
    return bodyMetricsBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> saveBodyMetrics(BodyMetrics metrics) async {
    await bodyMetricsBox.put(metrics.id, metrics);
  }

  Future<void> deleteBodyMetrics(String id) async {
    await bodyMetricsBox.delete(id);
  }

  // --- Settings ---
  bool get isDarkMode => settingsBox.get('isDarkMode', defaultValue: false);

  Future<void> setDarkMode(bool value) async {
    await settingsBox.put('isDarkMode', value);
  }

  // --- Workout Routines ---
  List<WorkoutRoutine> getAllRoutines() => routinesBox.values.toList();

  Future<void> saveRoutine(WorkoutRoutine routine) async {
    await routinesBox.put(routine.id, routine);
  }

  Future<void> deleteRoutine(String id) async {
    await routinesBox.delete(id);
  }
}
