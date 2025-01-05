// lib/screens/bottom_nav_screen.dart

import 'package:flutter/material.dart';
import 'pomodoro_screen.dart';
import 'tasks_screen.dart';
import 'environment_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart'; // Importiere den HistoryScreen

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  final List<_NavItem> allItems = [
    _NavItem(label: 'Environment', icon: Icons.graphic_eq, widget: const EnvironmentScreen()),
    _NavItem(label: 'Pomodoro', icon: Icons.timer, widget: const PomodoroScreen()),
    _NavItem(label: 'Aufgabenliste', icon: Icons.check_box_outlined, widget: const TaskScreen()),
    _NavItem(label: 'Historie', icon: Icons.history, widget: const HistoryScreen()), // Neuer Navigationspunkt
    _NavItem(label: 'Settings', icon: Icons.settings, widget: const SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = allItems.map((e) => e.widget).toList();
    final items = allItems
        .map((e) => BottomNavigationBarItem(icon: Icon(e.icon), label: e.label))
        .toList();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget widget;

  _NavItem({required this.label, required this.icon, required this.widget});
}
