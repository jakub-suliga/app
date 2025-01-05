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
          '1. Verbinde deine eSense-Kopfhörer über Bluetooth.\n\n2. Gehe dann in die App-Einstellungen und gib den Namen der eSense-Kopfhörer ein. Nur eSense-Kopfhörer sind kompatibel.',
    ),
    IntroPageData(
      title: 'Aufgaben erstellen',
      description:
          'Erstelle eine Aufgabe. Du kannst Priorität, Enddatum und benötigte Zeit angeben. Die App erkennt automatisch, welche Aufgabe du als nächstes bearbeiten solltest.',
    ),
    IntroPageData(
      title: 'Pomodoro-Einheit starten',
      description:
          'Nach dem Erstellen einer Aufgabe starte eine Pomodoro-Einheit, um fokussiert zu arbeiten. Die App überwacht deine Bewegungen per eSense, damit du in der Fokus-Phase möglichst ruhig bleibst.',
    ),
    IntroPageData(
      title: 'Feedback erhalten',
      description:
          'In den Pausen solltest du dich hingegen ausreichend bewegen. Je nach Bewegung gibt dir die App Feedback: Fokus während der Arbeit, Bewegung in der Pause.',
    ),
  ];

  Future<void> _setIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    if (_doNotShowAgain) {
      await prefs.setBool('introShown', true);
    }
  }

  void _navigateToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavScreen()),
    );
  }

  void _finishIntro() {
    _setIntroShown(); 
    _navigateToMain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar leicht angepasst (z. B. kleiner Schatten, zentrierter Titel)
      appBar: AppBar(
        title: const Text('Einführung'),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Das obere Flexible-Element: PageView mit den Einführungs-Seiten
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
                return _buildIntroPage(_pages[index]);
              },
            ),
          ),

          // Checkbox nur auf der letzten Seite
          if (_currentPage == _pages.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
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
            ),

          // Navigationsleiste unten (Dots + Weiter/Fertig-Button)
          _buildBottomControls(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hilfsmethode für eine einzelne Intro-Seite
  // ---------------------------------------------------------------------------
  Widget _buildIntroPage(IntroPageData pageData) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Optional: Füge ein passendes Icon oder Image hinzu, z.B.:
              Icon(
                Icons.lightbulb_outline,
                size: 80,
                color: Colors.blueAccent.shade100,
              ),
              const SizedBox(height: 20),
              Text(
                pageData.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                pageData.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigationsleiste unten: Dots + Weiter/Fertig-Button
  // ---------------------------------------------------------------------------
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // Leichter Schatten oder Divider oben
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: const Offset(0, -1),
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots
          Row(
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 14 : 8,
                height: _currentPage == index ? 14 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.blueAccent
                      : Colors.grey.shade400,
                ),
              );
            }),
          ),

          // Weiter/Fertig-Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
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
              _currentPage == _pages.length - 1 ? 'Fertig' : 'Weiter',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Modellklasse für die Seiten
// -----------------------------------------------------------------------------
class IntroPageData {
  final String title;
  final String description;

  IntroPageData({
    required this.title,
    required this.description,
  });
}
