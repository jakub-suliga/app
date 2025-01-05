// lib/main.dart

import 'package:FocusBuddy/presentation/screens/bottom_nav_screen.dart';
import 'package:FocusBuddy/service/eSenseService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importiere die Cubits
import 'core/app_router.dart';
import 'logic/settings/settings_cubit.dart';
import 'logic/tasks/tasks_cubit.dart';
import 'logic/theme/theme_cubit.dart';

// Importiere den navigatorKey
import 'core/app.dart'; // Importiere den navigatorKey

// Importiere IntroScreen
import 'presentation/screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Lese den gespeicherten Wert; standardmäßig false, damit der Intro-Screen angezeigt wird
  final introShown = prefs.getBool('introShown') ?? false;

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
          create: (_) => SettingsCubit(ESenseService()),
        ),
      ],
      child: FocusApp(showIntroScreen: !introShown), // Intro-Screen anzeigen, wenn introShown false ist
    ),
  );
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
