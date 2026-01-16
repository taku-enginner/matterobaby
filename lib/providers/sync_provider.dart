import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_sync_service.dart';
import 'attendance_provider.dart';
import 'schedule_provider.dart';
import 'settings_provider.dart';
import 'progress_provider.dart';

// 同期状態
enum SyncStatus { idle, syncing, success, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

// パートナーモード（閲覧専用）
final partnerModeProvider = StateProvider<bool>((ref) => false);
final partnerCodeProvider = StateProvider<String?>((ref) => null);

// パートナーのデータを監視
final partnerDataProvider = StreamProvider.family<SharedData?, String>((ref, code) {
  final syncService = ref.watch(firestoreSyncServiceProvider);
  return syncService.watchData(code);
});

// 同期を実行するプロバイダー
final syncActionProvider = Provider<SyncAction>((ref) {
  return SyncAction(ref);
});

class SyncAction {
  final Ref _ref;

  SyncAction(this._ref);

  // データをFirestoreにアップロード
  Future<bool> syncToFirestore() async {
    final settings = _ref.read(settingsProvider);
    final shareCode = settings?.shareCode;

    if (shareCode == null || shareCode.isEmpty) {
      return false;
    }

    _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    try {
      final syncService = _ref.read(firestoreSyncServiceProvider);
      final attendance = _ref.read(attendanceProvider);
      final schedule = _ref.read(scheduleProvider);
      final progress = _ref.read(progressProvider);

      await syncService.uploadData(
        shareCode: shareCode,
        attendanceDates: attendance.map((r) => r.date).toList(),
        scheduledDates: schedule.map((r) => r.date).toList(),
        scheduledWeekdays: settings?.scheduledWeekdays ?? [],
        qualifyingMonths: progress?.qualifyingMonths ?? 0,
        startDate: settings?.periodStartDate,
      );

      _ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
      return true;
    } catch (e) {
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      return false;
    }
  }

  // 共有コードが有効か確認
  Future<bool> validateShareCode(String code) async {
    final syncService = _ref.read(firestoreSyncServiceProvider);
    return await syncService.checkCodeExists(code);
  }

  // パートナーモードを開始
  Future<bool> startPartnerMode(String code) async {
    final exists = await validateShareCode(code);
    if (!exists) return false;

    _ref.read(partnerModeProvider.notifier).state = true;
    _ref.read(partnerCodeProvider.notifier).state = code;
    return true;
  }

  // パートナーモードを終了
  void exitPartnerMode() {
    _ref.read(partnerModeProvider.notifier).state = false;
    _ref.read(partnerCodeProvider.notifier).state = null;
  }
}
