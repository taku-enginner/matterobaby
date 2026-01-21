import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../data/models/attendance_record.dart';
import '../data/models/gacha_history.dart';
import 'attendance_provider.dart';
import 'gacha_provider.dart';

/// 1つのスタンプスロットのデータ
class StampSlotData {
  final int slotIndex;
  final DateTime? stampDate;
  final bool isStamped;
  final bool isUsed;

  const StampSlotData({
    required this.slotIndex,
    this.stampDate,
    required this.isStamped,
    required this.isUsed,
  });
}

/// 1ページ分のスタンプデータ
class StampPageData {
  final int pageIndex;
  final List<StampSlotData> slots;
  final bool isCurrentPage;
  final String? spinId;
  final DateTime? spinDate;

  const StampPageData({
    required this.pageIndex,
    required this.slots,
    required this.isCurrentPage,
    this.spinId,
    this.spinDate,
  });

  bool get isUsed => spinId != null;
}

/// スタンプページ一覧を計算するProvider
final stampPagesProvider = Provider<List<StampPageData>>((ref) {
  final attendance = ref.watch(attendanceProvider);
  final gachaHistory = ref.watch(gachaHistoryProvider);
  return _computePages(attendance, gachaHistory);
});

/// 現在のページ数
final stampPageCountProvider = Provider<int>((ref) {
  final pages = ref.watch(stampPagesProvider);
  return pages.length;
});

List<StampPageData> _computePages(
  List<AttendanceRecord> attendance,
  List<GachaHistory> gachaHistory,
) {
  // spinIdからスピン日時を取得するマップを作成
  final spinDateMap = <String, DateTime>{};
  for (final history in gachaHistory) {
    spinDateMap[history.id] = history.spunAt;
  }
  if (attendance.isEmpty) {
    // 出勤記録がない場合は空のページを1つ表示
    return [
      StampPageData(
        pageIndex: 0,
        slots: List.generate(
          AppConstants.stampsPerSpin,
          (i) => StampSlotData(
            slotIndex: i,
            isStamped: false,
            isUsed: false,
          ),
        ),
        isCurrentPage: true,
      ),
    ];
  }

  // 日付順にソート（古い順）
  final sortedAttendance = List<AttendanceRecord>.from(attendance)
    ..sort((a, b) => a.date.compareTo(b.date));

  // 使用済みスタンプと未使用スタンプを分離
  final usedStamps = sortedAttendance.where((r) => r.isUsed).toList();
  final unusedStamps = sortedAttendance.where((r) => !r.isUsed).toList();

  final pages = <StampPageData>[];

  // 使用済みスタンプをspinIdでグループ化してページを作成
  final usedBySpinId = <String, List<AttendanceRecord>>{};
  for (final stamp in usedStamps) {
    final spinId = stamp.usedForSpinId!;
    usedBySpinId.putIfAbsent(spinId, () => []).add(stamp);
  }

  // spinIdごとにページを作成（時系列順）
  final spinIds = usedBySpinId.keys.toList();
  // spinIdに基づいて時系列順にソート（最古のスタンプの日付で）
  spinIds.sort((a, b) {
    final aDate = usedBySpinId[a]!.first.date;
    final bDate = usedBySpinId[b]!.first.date;
    return aDate.compareTo(bDate);
  });

  for (final spinId in spinIds) {
    final stampsForSpin = usedBySpinId[spinId]!;
    // 日付順にソート
    stampsForSpin.sort((a, b) => a.date.compareTo(b.date));

    final slots = <StampSlotData>[];
    for (var i = 0; i < AppConstants.stampsPerSpin; i++) {
      if (i < stampsForSpin.length) {
        slots.add(StampSlotData(
          slotIndex: i,
          stampDate: stampsForSpin[i].date,
          isStamped: true,
          isUsed: true,
        ));
      } else {
        slots.add(StampSlotData(
          slotIndex: i,
          isStamped: false,
          isUsed: false,
        ));
      }
    }

    pages.add(StampPageData(
      pageIndex: pages.length,
      slots: slots,
      isCurrentPage: false,
      spinId: spinId,
      spinDate: spinDateMap[spinId],
    ));
  }

  // 未使用スタンプでページを作成（3個ごとに1ページ）
  // 日付順にソート（古い順）
  unusedStamps.sort((a, b) => a.date.compareTo(b.date));

  // 未使用スタンプを stampsPerSpin ごとにグループ化
  final unusedPageCount = (unusedStamps.length / AppConstants.stampsPerSpin).ceil();
  final totalUnusedPages = unusedPageCount == 0 ? 1 : unusedPageCount;

  for (var pageIdx = 0; pageIdx < totalUnusedPages; pageIdx++) {
    final startIdx = pageIdx * AppConstants.stampsPerSpin;
    final currentSlots = <StampSlotData>[];

    for (var i = 0; i < AppConstants.stampsPerSpin; i++) {
      final stampIdx = startIdx + i;
      if (stampIdx < unusedStamps.length) {
        currentSlots.add(StampSlotData(
          slotIndex: i,
          stampDate: unusedStamps[stampIdx].date,
          isStamped: true,
          isUsed: false,
        ));
      } else {
        currentSlots.add(StampSlotData(
          slotIndex: i,
          isStamped: false,
          isUsed: false,
        ));
      }
    }

    final isLastPage = pageIdx == totalUnusedPages - 1;
    pages.add(StampPageData(
      pageIndex: pages.length,
      slots: currentSlots,
      isCurrentPage: isLastPage,
    ));
  }

  return pages;
}
