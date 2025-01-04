// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importiere die Cubits
import 'core/app_router.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/theme/theme_cubit.dart';

// Importiere die DataProviders und Repositories
import 'data/data_providers/tasks_data_provider.dart';
import 'data/repositories/tasks_repository.dart';

// Importiere den navigatorKey
import 'core/app.dart'; // Importiere den navigatorKey

// Importiere IntroScreen
import 'presentation/screens/intro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere DataProviders
  final tasksDataProvider = TasksDataProvider();

  // Initialisiere Repositories
  final tasksRepo = TasksRepository(dataProvider: tasksDataProvider);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<TasksCubit>(
          create: (_) => TasksCubit()..loadTasks(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(),
        ),
      ],
      child: const FocusApp(),
    ),
  );
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Setze den navigatorKey hier
          title: 'Focus App',
          theme: themeState.themeData,
          home: const IntroScreen(), // Setze IntroScreen als Start-Widget
          onGenerateRoute: AppRouter.onGenerateRoute,
          // initialRoute: '/', // Entferne initialRoute, wenn Sie home verwenden
        );
      },
    );
  }
}
