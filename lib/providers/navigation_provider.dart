import 'package:flutter_riverpod/flutter_riverpod.dart';

// タブインデックス: 0=記録, 1=ホーム, 2=ごほうび, 3=統計, 4=設定
final tabIndexProvider = StateProvider<int>((ref) => 0);

// スタンプアニメーションをトリガーするフラグ
final stampAnimationTriggerProvider = StateProvider<bool>((ref) => false);
