// lib/presentation/screens/intro_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_screen.dart'; // Importieren Sie den Haupt-Screen

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<IntroPageData> _pages = [
    IntroPageData(
      title: 'Willkommen bei FocusBuddy!',
      description:
          'Diese App hilft dir, fokussiert zu lernen und deine Aufgaben zu meistern.',
    ),
    IntroPageData(
      title: 'eSense-Kopfhörer verbinden',
      description:
          '1. Verbinde deine eSense-Kopfhörer zuerst über die Bluetooth-Einstellungen deines Handys. \n\n 2. Gehe dann in die App-Einstellungen und gib den Namen der eSense-Kopfhörer ein. Nur eSense-Kopfhörer funktionieren.',
    ),
    IntroPageData(
      title: 'Aufgaben erstellen',
      description:
          'Erstelle eine Aufgabe. Dabei kannst du die Priorität, ein Enddatum und die benötigte Zeit für die Aufgabe angeben. Basierend auf diesen Informationen erkennt die App automatisch die beste Aufgabe für dich, die du meistern sollst.',
    ),
    IntroPageData(
      title: 'Pomodoro-Einheit starten',
      description:
          'Nach dem erstellen einer Aufgabe, starte eine Pomodoro-Einheit, um fokussiert an der Aufgabe zu arbeiten. Während der Pomodoro-Einheit überwacht die App Ihre Bewegungen mithilfe der eSense-Kopfhörer, um sicherzustellen, dass Sie sich nicht zu viel bewegen und fokussiert bleiben. Um eine Pomodoro Einheit zu starten, musst du eine Aufgabe hinzufügen.',
    ),
    IntroPageData(
      title: 'Feedback erhalten',
      description:
          'In den Pausen überprüft die App deine Bewegung, um sicherzustellen, dass du dich ausreichend bewegst. Abhängig von den Bewegungen erhälst du entsprechendes Feedback: Während der Pomodoro-Einheit solltest du dich konzentrieren, und während der Pause solltest du dich mehr bewegen.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkIfIntroShown();
  }

  Future<void> _checkIfIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    final introShown = prefs.getBool('introShown') ?? false;

    if (introShown) {
      _navigateToMain();
    }
  }

  void _setIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('introShown', true);
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishIntro() {
    _setIntroShown();
    _navigateToMain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einführung'),
        actions: [
          TextButton(
            onPressed: _finishIntro,
            child: const Text(
              'Überspringen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Anzeigen des Bildes, falls vorhanden
                      if (_pages[index].imagePath != null)
                        Image.asset(
                          _pages[index].imagePath!,
                          height: 200,
                        ),
                      if (_pages[index].imagePath != null)
                        const SizedBox(height: 20),
                      Text(
                        _pages[index].title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _pages[index].description,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Seitenindikatoren
                Row(
                  children: List.generate(_pages.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 12 : 8,
                      height: _currentPage == index ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    );
                  }),
                ),
                // Weiter- oder Fertig-Button
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishIntro();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Text(
                      _currentPage == _pages.length - 1 ? 'Fertig' : 'Weiter'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPageData {
  final String title;
  final String description;
  final String? imagePath; // Optionales Bildfeld

  IntroPageData({
    required this.title,
    required this.description,
    this.imagePath, // Initialisierung des optionalen Bildes
  });
}
