import 'package:FocusBuddy/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/history/history_cubit.dart';

import 'data/data_providers/settings_data_provider.dart';
import 'data/repositories/settings_repository.dart';
import 'data/data_providers/tasks_data_provider.dart';
import 'data/repositories/tasks_repository.dart';
import 'data/data_providers/history_data_provider.dart';
import 'data/repositories/history_repository.dart';

import 'presentation/screens/intro_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/bottom_nav_screen.dart';
import 'presentation/screens/pomodoro_screen.dart';

import 'core/app.dart';
import 'service/eSenseService.dart';

/// Main-Einstiegspunkt der App. 
/// Richtet Repositories und Bloc-Provider ein und zeigt entweder den Intro-Screen oder die Hauptnavigation an.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsRepository = SettingsRepository(dataProvider: SettingsDataProvider());
  final tasksRepository = TasksRepository(dataProvider: TasksDataProvider());
  final historyRepository = HistoryRepository(dataProvider: HistoryDataProvider());
  final eSenseService = ESenseService();

  final prefs = await SharedPreferences.getInstance();
  final introShown = prefs.getBool('introShown') ?? false;

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SettingsRepository>(create: (_) => settingsRepository),
        RepositoryProvider<TasksRepository>(create: (_) => tasksRepository),
        RepositoryProvider<HistoryRepository>(create: (_) => historyRepository),
        RepositoryProvider<ESenseService>(create: (_) => eSenseService),
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
        ],
        child: MyApp(showIntroScreen: !introShown),
      ),
    ),
  );
}

/// Haupt-Widget der App. 
/// Legt Thema, Lokalisierung und Routing fest.
class MyApp extends StatelessWidget {
  final bool showIntroScreen;

  const MyApp({super.key, required this.showIntroScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Focus App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'),
      ],
      theme: ThemeData(primarySwatch: Colors.blue),
      home: showIntroScreen ? const IntroScreen() : const BottomNavScreen(),
      routes: {
        '/tasks': (context) => const TaskScreen(),
        '/pomodoro': (context) => const PomodoroScreen(),
        '/history': (context) => const HistoryScreen(),
        '/intro': (context) => const IntroScreen(),
        '/bottomNav': (context) => const BottomNavScreen(),
      },
    );
  }
}
