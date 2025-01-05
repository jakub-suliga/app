// lib/core/app_router.dart

import 'package:flutter/material.dart'; 
import '../presentation/screens/bottom_nav_screen.dart';
import '../presentation/screens/environment_screen.dart';
import '../presentation/screens/pomodoro_screen.dart';
import '../presentation/screens/tasks_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/screens/history_screen.dart'; // Importiere den HistoryScreen

class AppRouter {
  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const BottomNavScreen());

      case '/environment':
        return MaterialPageRoute(builder: (_) => const EnvironmentScreen());

      case '/pomodoro':
        return MaterialPageRoute(builder: (_) => const PomodoroScreen());

      case '/tasks':
        return MaterialPageRoute(builder: (_) => const TasksScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case '/history':
        return MaterialPageRoute(builder: (_) => const HistoryScreen()); // Neue Route

      default:
        return MaterialPageRoute(builder: (_) => const BottomNavScreen());
    }
  }
}
