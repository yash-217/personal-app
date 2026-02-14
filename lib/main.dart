import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/exercise_api_service.dart';
import 'providers/theme_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  final exerciseApi = ExerciseApiService(storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(storage)),
        ChangeNotifierProvider(
          create: (_) => ExerciseProvider(exerciseApi, storage),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider(storage)),
      ],
      child: const GymTrackerApp(),
    ),
  );
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

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
        );
      },
    );
  }
}
