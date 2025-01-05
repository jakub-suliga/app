// lib/main.dart

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

// Importiere die Screens
import 'presentation/screens/intro_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/bottom_nav_screen.dart';

// Importiere den navigatorKey
import 'core/app.dart'; // Importiere den navigatorKey

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Lese den gespeicherten Wert; standardmäßig false, damit der Intro-Screen angezeigt wird
  final introShown = prefs.getBool('introShown') ?? false;

  final historyRepository = HistoryRepository(
    dataProvider: HistoryDataProvider(),
  );

  runApp(
    RepositoryProvider<HistoryRepository>(
      create: (_) => historyRepository,
      child: BlocProvider<HistoryCubit>(
        create: (context) => HistoryCubit(
          historyRepository: context.read<HistoryRepository>(),
        )..loadHistory(),
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
          return MultiBlocProvider(
            providers: [
              BlocProvider<TasksCubit>(
                create: (context) => TasksCubit(
                  historyCubit: context.read<HistoryCubit>(),
                )..loadTasks(),
              ),
              BlocProvider<ThemeCubit>(
                create: (_) => ThemeCubit(),
              ),
              BlocProvider<SettingsCubit>(
                create: (_) => SettingsCubit(ESenseService()),
              ),
            ],
            child: FocusApp(showIntroScreen: showIntroScreen),
          );
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
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
