// lib/main.dart

import 'package:FocusBuddy/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importiere die Cubits
import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/history/history_cubit.dart';

// Importiere die Repositories und DataProviders
import 'data/data_providers/settings_data_provider.dart';
import 'data/repositories/settings_repository.dart';
import 'data/data_providers/tasks_data_provider.dart';
import 'data/repositories/tasks_repository.dart';
import 'data/data_providers/history_data_provider.dart';
import 'data/repositories/history_repository.dart';

// Importiere die Screens
import 'presentation/screens/intro_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/bottom_nav_screen.dart';
import 'presentation/screens/pomodoro_screen.dart';

// Importiere den navigatorKey
import 'core/app.dart'; // Stelle sicher, dass dieser Pfad korrekt ist

// Importiere die eSenseService
import 'service/eSenseService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere Repositories
  final settingsRepository = SettingsRepository(
    dataProvider: SettingsDataProvider(),
  );

  final tasksRepository = TasksRepository(
    dataProvider: TasksDataProvider(),
  );

  final historyRepository = HistoryRepository(
    dataProvider: HistoryDataProvider(),
  );

  // Initialisiere eSenseService
  final eSenseService = ESenseService();

  // Lade den introShown-Status
  final prefs = await SharedPreferences.getInstance();
  final introShown = prefs.getBool('introShown') ?? false;

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SettingsRepository>(
          create: (_) => settingsRepository,
        ),
        RepositoryProvider<TasksRepository>(
          create: (_) => tasksRepository,
        ),
        RepositoryProvider<HistoryRepository>(
          create: (_) => historyRepository,
        ),
        RepositoryProvider<ESenseService>(
          create: (_) => eSenseService,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>(
            create: (context) => SettingsCubit(
              settingsRepository: context.read<SettingsRepository>(),
              eSenseService: context.read<ESenseService>(),
            ),
          ),
          BlocProvider<TasksCubit>(
            create: (context) => TasksCubit(
              tasksRepository: context.read<TasksRepository>(),
            ),
          ),
          BlocProvider<HistoryCubit>(
            create: (context) => HistoryCubit(
              historyRepository: context.read<HistoryRepository>(),
            ),
          ),
          // Füge weitere Cubits hier hinzu, falls nötig
        ],
        child: MyApp(showIntroScreen: !introShown),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showIntroScreen;

  const MyApp({super.key, required this.showIntroScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Focus App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: showIntroScreen ? const IntroScreen() : const BottomNavScreen(),
      routes: {
        '/tasks': (context) => const TaskScreen(),
        '/pomodoro': (context) => const PomodoroScreen(),
        '/history': (context) => const HistoryScreen(),
        '/intro': (context) => const IntroScreen(),
        '/bottomNav': (context) => const BottomNavScreen(),
        // Füge weitere Routen hinzu, falls nötig
      },
      // Optional: onGenerateRoute nutzen, falls nötig
    );
  }
}
