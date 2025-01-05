import 'package:flutter/material.dart';
import 'pomodoro_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';

/// Hauptbildschirm mit einer unteren Navigationsleiste.
class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

/// Steuert die Navigation zwischen den verschiedenen Teil-Screens.
class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  final List<_NavItem> allItems = [
    _NavItem(
      label: 'Pomodoro',
      icon: Icons.timer,
      widget: const PomodoroScreen(),
    ),
    _NavItem(
      label: 'Aufgabenliste',
      icon: Icons.check_box_outlined,
      widget: const TaskScreen(),
    ),
    _NavItem(
      label: 'Historie',
      icon: Icons.history,
      widget: const HistoryScreen(),
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings,
      widget: const SettingsScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = allItems.map((e) => e.widget).toList();
    final items = allItems
        .map((e) => BottomNavigationBarItem(
              icon: Icon(e.icon),
              label: e.label,
            ))
        .toList();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      /// Rundet oben die Navigationsleiste ab.
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: BottomNavigationBar(
          items: items,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 8,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

/// Definiert die Eigenschaften eines Navigationselements (Label, Icon und Screen).
class _NavItem {
  final String label;
  final IconData icon;
  final Widget widget;

  _NavItem({
    required this.label,
    required this.icon,
    required this.widget,
  });
}
