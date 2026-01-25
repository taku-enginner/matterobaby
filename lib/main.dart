import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'data/models/attendance_record.dart';
import 'data/models/gacha_history.dart';
import 'data/models/reward.dart';
import 'data/models/scheduled_work.dart';
import 'data/models/user_settings.dart';
import 'data/models/workplace.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ja_JP', null);

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Initialize Hive (legacy - for migration)
  await Hive.initFlutter();
  Hive.registerAdapter(AttendanceRecordAdapter());
  Hive.registerAdapter(UserSettingsAdapter());
  Hive.registerAdapter(ScheduledWorkAdapter());
  Hive.registerAdapter(RewardAdapter());
  Hive.registerAdapter(GachaHistoryAdapter());
  Hive.registerAdapter(WorkplaceAdapter());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '出勤カウント',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B9D),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Hiragino Sans',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ja', 'JP'),
      home: const SplashScreen(),
    );
  }
}
