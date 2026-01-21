import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tutorial_service.dart';
import 'checkin/checkin_screen.dart';
import 'home/home_screen.dart';
import 'rewards/rewards_screen.dart';
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
  late PageController _pageController;

  final _screens = const [
    CheckinScreen(),
    HomeScreen(),
    RewardsScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartTutorial();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tutorialService.dispose();
    super.dispose();
  }

  void _animateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentIndex = index;
    });
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
        _animateToPage(tabIndex);
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
        _animateToPage(0);
        // Start tutorial after a short delay
        Future.delayed(const Duration(milliseconds: 300), () {
          _startTutorial();
        });
      }
    });

    // Watch for tab change requests (e.g., after check-in)
    ref.listen<int>(tabIndexProvider, (previous, next) {
      if (previous != next) {
        _animateToPage(next);
      }
    });

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // スワイプ無効
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          _animateToPage(index);
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
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'ごほうび',
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
