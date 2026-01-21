import 'package:flutter_riverpod/flutter_riverpod.dart';

// タブインデックス: 0=記録, 1=進捗, 2=スタンプ, 3=ごほうび, 4=設定
final tabIndexProvider = StateProvider<int>((ref) => 0);

// スタンプアニメーションをトリガーするフラグ
final stampAnimationTriggerProvider = StateProvider<bool>((ref) => false);
