// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importiere die Cubits
import 'core/router/app_router.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_settings_cubit.dart';
import 'logic/esense/esense_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/pomodoro/pomodoro_cubit.dart';
import 'logic/theme/theme_cubit.dart';

// Importiere die DataProviders und Repositories
import 'data/data_providers/tasks_data_provider.dart';
import 'data/data_providers/esense_data_provider.dart';
import 'data/repositories/tasks_repository.dart';
import 'data/repositories/esense_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere DataProviders
  final tasksDataProvider = TasksDataProvider();
  final esenseDataProvider = ESenseDataProvider(deviceName: 'eSense-0332');

  // Initialisiere Repositories
  final tasksRepo = TasksRepository(dataProvider: tasksDataProvider);
  final esenseRepo = ESenseRepository(dataProvider: esenseDataProvider);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ESenseCubit>(
          create: (_) => ESenseCubit(),
        ),
        BlocProvider<TasksCubit>(
          create: (_) => TasksCubit(tasksRepo: tasksRepo)..loadTasks(),
        ),
        BlocProvider<PomodoroCubit>(
          create: (_) => PomodoroCubit(),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        BlocProvider<TasksSettingsCubit>(
          create: (_) => TasksSettingsCubit(),
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
          title: 'Focus App',
          theme: themeState.themeData,
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: '/',
        );
      },
    );
  }
}
