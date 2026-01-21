import 'package:flutter/material.dart';

class TutorialKeys {
  TutorialKeys._();

  // Checkin Screen (Tab 0: 記録)
  static final checkinButton = GlobalKey();

  // Home Screen (Tab 1: 進捗)
  static final progressCard = GlobalKey();
  static final editModeSelector = GlobalKey();
  static final calendar = GlobalKey();
  static final scheduleSettingsButton = GlobalKey();
  static final barChart = GlobalKey();

  // Stamp Card Screen (Tab 2: スタンプ)
  static final stampCard = GlobalKey();
  static final gachaButton = GlobalKey();

  // Gacha Screen (Tab 3: ごほうび)
  static final rewardList = GlobalKey();

  // Settings Screen (Tab 4: 設定)
  static final periodStartDate = GlobalKey();
  static final workplaceSettings = GlobalKey();
}
