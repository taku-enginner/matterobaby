import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tutorial_service.dart';
import 'checkin/checkin_screen.dart';
import 'home/home_screen.dart';
import 'stamp/stamp_card_screen.dart';
import 'gacha/gacha_screen.dart';
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
    StampCardScreen(),
    GachaScreen(),
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

  void _animateToPage(int index) {
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
      body: IndexedStack(
        index: _currentIndex,
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
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: '進捗',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'スタンプ',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'ごほうび',
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
