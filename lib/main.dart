// lib/main.dart

import 'package:FocusBuddy/service/eSenseService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importiere die Cubits
import 'core/app_router.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/theme/theme_cubit.dart';

// Importiere den navigatorKey
import 'core/app.dart'; // Importiere den navigatorKey

// Importiere IntroScreen
import 'presentation/screens/intro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();


  // Initialisiere ESenseService
  final eSenseService = ESenseService();

  runApp(
    MultiBlocProvider(
      providers: [
        // BlocProvider für TasksCubit mit TasksRepository
        BlocProvider<TasksCubit>(
          create: (_) => TasksCubit()..loadTasks(),
        ),
        // BlocProvider für ThemeCubit
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(),
        ),
        // BlocProvider für SettingsCubit mit ESenseService
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(eSenseService),
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
        );
      },
    );
  }
}
