// lib/main.dart

import 'package:FocusBuddy/presentation/screens/tasks_screen.dart';
import 'package:FocusBuddy/service/eSenseService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importiere die Cubits
import 'core/app_router.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/theme/theme_cubit.dart';
import 'logic/history/history_cubit.dart';

// Importiere die Repositories und DataProviders
import 'data/data_providers/history_data_provider.dart';
import 'data/repositories/history_repository.dart';
import 'data/data_providers/tasks_data_provider.dart';
import 'data/repositories/tasks_repository.dart';

// Importiere die Screens
import 'presentation/screens/intro_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/bottom_nav_screen.dart';
import 'presentation/screens/pomodoro_screen.dart'; // PomodoroScreen importieren

// Importiere den navigatorKey
import 'core/app.dart'; // Importiere den navigatorKey

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Lese den gespeicherten Wert; standardmäßig false, damit der Intro-Screen angezeigt wird
  final introShown = prefs.getBool('introShown') ?? false;

  // Initialize Repositories
  final historyRepository = HistoryRepository(
    dataProvider: HistoryDataProvider(),
  );

  final tasksRepository = TasksRepository(
    dataProvider: TasksDataProvider(),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HistoryRepository>(
          create: (_) => historyRepository,
        ),
        RepositoryProvider<TasksRepository>(
          create: (_) => tasksRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HistoryCubit>(
            create: (context) => HistoryCubit(
              historyRepository: context.read<HistoryRepository>(),
            )..loadHistory(),
          ),
          BlocProvider<TasksCubit>(
            create: (context) => TasksCubit(
              tasksRepository: context.read<TasksRepository>(),
            )..loadTasks(),
          ),
          BlocProvider<ThemeCubit>(
            create: (_) => ThemeCubit(),
          ),
          BlocProvider<SettingsCubit>(
            create: (_) => SettingsCubit(ESenseService()),
          ),
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
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, historyState) {
        if (historyState is HistoryLoading) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (historyState is HistoryLoaded || historyState is HistoryError) {
          return FocusApp(showIntroScreen: showIntroScreen);
        } else {
          // Fallback
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Fehler beim Laden der Historie')),
            ),
          );
        }
      },
    );
  }
}

class FocusApp extends StatelessWidget {
  final bool showIntroScreen;

  const FocusApp({super.key, required this.showIntroScreen});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Focus App',
          theme: themeState.themeData,
          home: showIntroScreen ? const IntroScreen() : const BottomNavScreen(),
          routes: {
            '/tasks': (context) => const TaskScreen(),
            '/pomodoro': (context) => const PomodoroScreen(),
            '/history': (context) => const HistoryScreen(),
            // Füge weitere Routen hinzu, falls nötig
          },
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
