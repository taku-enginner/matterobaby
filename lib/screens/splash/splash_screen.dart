import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../main_screen.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/gacha_provider.dart';
import '../../providers/point_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workplace_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeProviders() async {
    await ref.read(settingsProvider.notifier).init();
    await ref.read(attendanceProvider.notifier).init();
    await ref.read(scheduleProvider.notifier).init();
    await ref.read(rewardProvider.notifier).init();
    await ref.read(pointProvider.notifier).init();
    await ref.read(gachaHistoryProvider.notifier).init();
    await ref.read(workplaceProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<AuthState>(authProvider, (previous, next) async {
      final navigator = Navigator.of(context);
      if (next.status == AuthStatus.authenticated) {
        await _initializeProviders();
        if (!mounted) return;
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else if (next.status == AuthStatus.unauthenticated) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              '出勤カウント',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 48),
            if (authState.status == AuthStatus.initial ||
                authState.status == AuthStatus.loading)
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
