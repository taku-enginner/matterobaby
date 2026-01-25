import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class AttendanceDatasource {
  final SupabaseClient _client = SupabaseClientService.client;
  final Random _random = Random();

  /// スタンプの回転角度を生成
  /// 通常: -15° ~ +15° (ラジアン)
  /// レア(5%): 170° ~ 190° (逆さスタンプ)
  double _generateStampRotation() {
    if (_random.nextDouble() < 0.05) {
      // 5%の確率で逆さスタンプ (170° ~ 190°)
      return pi + (_random.nextDouble() - 0.5) * (20 * pi / 180);
    }
    // 通常: -15° ~ +15°
    return (_random.nextDouble() - 0.5) * (30 * pi / 180);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0])
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getByDate(DateTime date) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .eq('date', date.toIso8601String().split('T')[0]);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> create({
    required DateTime date,
    String? workplaceId,
    double? workHours,
  }) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final stampRotation = _generateStampRotation();

    final response = await _client
        .from('attendance_records')
        .insert({
          'user_id': userId,
          'date': date.toIso8601String().split('T')[0],
          'workplace_id': workplaceId,
          'work_hours': workHours,
          'stamp_rotation': stampRotation,
        })
        .select()
        .single();

    return response;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _client
        .from('attendance_records')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  Future<void> delete(String id) async {
    await _client.from('attendance_records').delete().eq('id', id);
  }

  Future<void> deleteByDate(DateTime date) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return;

    await _client
        .from('attendance_records')
        .delete()
        .eq('user_id', userId)
        .eq('date', date.toIso8601String().split('T')[0]);
  }

  Future<List<Map<String, dynamic>>> getUnusedForSpin({int limit = 3}) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('attendance_records')
        .select()
        .eq('user_id', userId)
        .isFilter('used_for_spin_id', null)
        .order('date', ascending: true)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> markAsUsedForSpin(List<String> ids, String spinId) async {
    await _client
        .from('attendance_records')
        .update({'used_for_spin_id': spinId})
        .inFilter('id', ids);
  }
}
