import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/tutorial_service.dart';
import 'checkin/checkin_screen.dart';
import 'home/home_screen.dart';
import 'statistics/statistics_screen.dart';
import 'settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  final TutorialService _tutorialService = TutorialService();
  bool _tutorialStarted = false;

  final _screens = const [
    CheckinScreen(),
    HomeScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartTutorial();
    });
  }

  @override
  void dispose() {
    _tutorialService.dispose();
    super.dispose();
  }

  void _checkAndStartTutorial() {
    final settings = ref.read(settingsProvider);
    if (settings != null && !settings.hasSeenOnboarding && !_tutorialStarted) {
      _startTutorial();
    }
  }

  void _startTutorial() {
    _tutorialStarted = true;
    _tutorialService.showTutorial(
      context: context,
      onTabChange: (tabIndex) {
        setState(() {
          _currentIndex = tabIndex;
        });
      },
      onFinish: () {
        ref.read(settingsProvider.notifier).markTutorialSeen();
        _tutorialStarted = false;
      },
      onSkip: () {
        ref.read(settingsProvider.notifier).markTutorialSeen();
        _tutorialStarted = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for tutorial restart requests
    ref.listen<bool>(tutorialRestartRequestProvider, (previous, next) {
      if (next && !_tutorialStarted) {
        ref.read(tutorialRestartRequestProvider.notifier).state = false;
        // Navigate to home tab first
        setState(() {
          _currentIndex = 0;
        });
        // Start tutorial after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          _startTutorial();
        });
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.touch_app_outlined),
            selectedIcon: Icon(Icons.touch_app),
            label: '記録',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '統計',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
