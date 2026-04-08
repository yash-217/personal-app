import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/exercise_api_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/debug_log_service.dart';
import 'providers/theme_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/sleep_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intercept all debugPrint output for in-app viewing.
  DebugLogService.instance.install();

  // Initialize Firebase
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? AndroidDebugProvider()
        : AndroidPlayIntegrityProvider(),
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final storage = StorageService();
  await storage.init();

  final exerciseApi = ExerciseApiService(storage);

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

  final sleepProvider = SleepProvider(storage);
  final workoutProvider = WorkoutProvider(storage);
  final achievementProvider = AchievementProvider(storage);

  // Cross-link providers for coordinated notification rescheduling
  sleepProvider.setWorkoutProvider(workoutProvider);
  workoutProvider.setSleepProvider(sleepProvider);

  // Link achievement provider
  sleepProvider.setAchievementProvider(achievementProvider);
  workoutProvider.setAchievementProvider(achievementProvider);

  // Schedule notifications based on current data
  notificationService.rescheduleNotifications(
    sleepLogs: sleepProvider.logs,
    dayLogs: workoutProvider.dayLogs,
  );

  // Run initial achievement evaluation
  achievementProvider.evaluate(
    dayLogs: workoutProvider.dayLogs,
    sleepLogs: sleepProvider.logs,
    runLogs: workoutProvider.runLogs,
  );

  // Auth service
  final authService = AuthService();

  // Trigger weekly auto-backup (fire-and-forget, non-blocking)
  CloudSyncService(storage).autoBackupIfNeeded();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider.value(value: workoutProvider),
        ChangeNotifierProvider(
          create: (_) => ExerciseProvider(exerciseApi, storage),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider(storage)),
        ChangeNotifierProvider.value(value: sleepProvider),
        ChangeNotifierProvider.value(value: achievementProvider),
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
      ],
      child: const FitPrintApp(),
    ),
  );
}

class FitPrintApp extends StatelessWidget {
  const FitPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'FitPrint',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const MainShell(),
          navigatorObservers: [
            FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
          ],
        );
      },
    );
  }
}
