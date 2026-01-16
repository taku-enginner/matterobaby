import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreSyncServiceProvider = Provider<FirestoreSyncService>((ref) {
  return FirestoreSyncService();
});

class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 共有コードでデータをアップロード
  Future<void> uploadData({
    required String shareCode,
    required List<DateTime> attendanceDates,
    required List<DateTime> scheduledDates,
    required List<int> scheduledWeekdays,
    required int qualifyingMonths,
    required DateTime? startDate,
  }) async {
    await _firestore.collection('shared_data').doc(shareCode).set({
      'attendanceDates': attendanceDates.map((d) => d.toIso8601String()).toList(),
      'scheduledDates': scheduledDates.map((d) => d.toIso8601String()).toList(),
      'scheduledWeekdays': scheduledWeekdays,
      'qualifyingMonths': qualifyingMonths,
      'startDate': startDate?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 共有コードでデータを取得
  Future<SharedData?> fetchData(String shareCode) async {
    final doc = await _firestore.collection('shared_data').doc(shareCode).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    return SharedData(
      attendanceDates: (data['attendanceDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      scheduledDates: (data['scheduledDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      scheduledWeekdays: (data['scheduledWeekdays'] as List<dynamic>?)
              ?.map((d) => d as int)
              .toList() ??
          [],
      qualifyingMonths: data['qualifyingMonths'] as int? ?? 0,
      startDate: data['startDate'] != null
          ? DateTime.parse(data['startDate'] as String)
          : null,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // リアルタイムでデータを監視
  Stream<SharedData?> watchData(String shareCode) {
    return _firestore
        .collection('shared_data')
        .doc(shareCode)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;

      final data = doc.data()!;
      return SharedData(
        attendanceDates: (data['attendanceDates'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            [],
        scheduledDates: (data['scheduledDates'] as List<dynamic>?)
                ?.map((d) => DateTime.parse(d as String))
                .toList() ??
            [],
        scheduledWeekdays: (data['scheduledWeekdays'] as List<dynamic>?)
                ?.map((d) => d as int)
                .toList() ??
            [],
        qualifyingMonths: data['qualifyingMonths'] as int? ?? 0,
        startDate: data['startDate'] != null
            ? DateTime.parse(data['startDate'] as String)
            : null,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    });
  }

  // 共有コードが存在するか確認
  Future<bool> checkCodeExists(String shareCode) async {
    final doc = await _firestore.collection('shared_data').doc(shareCode).get();
    return doc.exists;
  }
}

class SharedData {
  final List<DateTime> attendanceDates;
  final List<DateTime> scheduledDates;
  final List<int> scheduledWeekdays;
  final int qualifyingMonths;
  final DateTime? startDate;
  final DateTime? updatedAt;

  SharedData({
    required this.attendanceDates,
    required this.scheduledDates,
    required this.scheduledWeekdays,
    required this.qualifyingMonths,
    this.startDate,
    this.updatedAt,
  });
}
