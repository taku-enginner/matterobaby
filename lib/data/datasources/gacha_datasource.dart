import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class GachaDatasource {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('gacha_history')
        .select()
        .eq('user_id', userId)
        .order('spun_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getRecent({int limit = 10}) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('gacha_history')
        .select()
        .eq('user_id', userId)
        .order('spun_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> create({
    required String rewardId,
    required String rewardName,
    bool isTestMode = false,
  }) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('gacha_history')
        .insert({
          'user_id': userId,
          'reward_id': rewardId,
          'reward_name': rewardName,
          'is_test_mode': isTestMode,
        })
        .select()
        .single();

    return response;
  }

  Future<void> deleteAll() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return;

    await _client.from('gacha_history').delete().eq('user_id', userId);
  }
}
