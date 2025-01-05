import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_nav_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _doNotShowAgain = false; // Checkbox-Status

  final List<IntroPageData> _pages = [
    IntroPageData(
      title: 'Willkommen bei FocusBuddy!',
      description:
          'Diese App hilft dir, fokussiert zu lernen und deine Aufgaben zu meistern.',
    ),
    IntroPageData(
      title: 'eSense-Kopfhörer verbinden',
      description:
          '1. Verbinde deine eSense-Kopfhörer zuerst über die Bluetooth-Einstellungen deines Handys. \n\n 2. Gehe dann in die App-Einstellungen und gib den Namen der eSense-Kopfhörer ein. Du kannst nur eSense-Kopfhörer verwenden.',
    ),
    IntroPageData(
      title: 'Aufgaben erstellen',
      description:
          'Erstelle eine Aufgabe. Dabei kannst du die Priorität, ein Enddatum und die benötigte Zeit für die Aufgabe angeben. Basierend auf diesen Informationen erkennt die App automatisch die beste Aufgabe für dich, die du meistern kannst.',
    ),
    IntroPageData(
      title: 'Pomodoro-Einheit starten',
      description:
          'Nach dem Erstellen einer Aufgabe starte eine Pomodoro-Einheit, um fokussiert an der Aufgabe zu arbeiten. Während der Pomodoro-Einheit überwacht die App deine Bewegungen mithilfe der eSense-Kopfhörer, um sicherzustellen, dass du dich nicht zu viel bewegst und fokussiert bleibst. Um eine Pomodoro Einheit zu starten, musst du eine Aufgabe hinzufügen.',
    ),
    IntroPageData(
      title: 'Feedback erhalten',
      description:
          'In den Pausen überprüft die App deine Bewegung, um sicherzustellen, dass du dich ausreichend bewegst. Abhängig von den Bewegungen erhälst du entsprechendes Feedback: Während der Pomodoro-Einheit solltest du dich konzentrieren, und während der Pause solltest du dich bewegen.',
    ),
  ];

  Future<void> _setIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('introShown', _doNotShowAgain); // Speichere nur, wenn der Haken gesetzt wurde
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
    );
  }

  void _finishIntro() {
    _setIntroShown(); // Speichere den Haken-Status
    _navigateToMain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einführung'),
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
          if (_currentPage == _pages.length - 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _doNotShowAgain,
                  onChanged: (bool? value) {
                    setState(() {
                      _doNotShowAgain = value ?? false;
                    });
                  },
                ),
                const Text('Nicht mehr anzeigen'),
              ],
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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

  IntroPageData({
    required this.title,
    required this.description,
  });
}
