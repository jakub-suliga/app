// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importiere die Cubits
import 'core/router/app_router.dart';
import 'logic/tasks/tasks_settings_cubit.dart';
import 'logic/esense/esense_cubit.dart';
import 'logic/motion/motion_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/volume/volume_cubit.dart';
import 'logic/pomodoro/pomodoro_cubit.dart';
import 'logic/theme/theme_cubit.dart';

// Importiere die DataProviders und Repositories
import 'data/data_providers/motion_data_provider.dart';
import 'data/data_providers/tasks_data_provider.dart';
import 'data/data_providers/volume_data_provider.dart';
import 'data/data_providers/esense_data_provider.dart'; // Annahme

// Importiere die Repositories
import 'data/repositories/motion_repository.dart';
import 'data/repositories/tasks_repository.dart';
import 'data/repositories/volume_repository.dart';
import 'data/repositories/esense_repository.dart'; // Annahme

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisiere DataProviders
  final motionDataProvider = MotionDataProvider();
  final tasksDataProvider = TasksDataProvider();
  final volumeDataProvider = VolumeDataProvider();
  final esenseDataProvider = ESenseDataProvider(deviceName: 'eSense-0332'); 

  // Initialisiere Repositories
  final motionRepo = MotionRepository(dataProvider: motionDataProvider);
  final tasksRepo = TasksRepository(dataProvider: tasksDataProvider);
  final volumeRepo = VolumeRepository(dataProvider: volumeDataProvider);
  final esenseRepo = ESenseRepository(dataProvider: esenseDataProvider); // Annahme

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ESenseCubit>(
          create: (_) => ESenseCubit(esenseRepo: esenseRepo), // Übergabe des Repositories
        ),
        BlocProvider<MotionCubit>(
          create: (_) => MotionCubit(motionRepo: motionRepo),
        ),
        BlocProvider<TasksCubit>(
          create: (_) => TasksCubit(tasksRepo: tasksRepo)..loadTasks(),
        ),
        BlocProvider<VolumeCubit>(
          create: (_) => VolumeCubit(),
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
      ],
      child: const FocusApp(),
    ),
  );
}

class FocusApp extends StatelessWidget {
  const FocusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Focus App',
          theme: themeState.themeData, // Verwende das aktuelle Theme aus ThemeCubit
          onGenerateRoute: AppRouter.onGenerateRoute,
          initialRoute: '/',
        );
      },
    );
  }
}
