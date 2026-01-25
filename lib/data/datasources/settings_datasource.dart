import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class SettingsDatasource {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<Map<String, dynamic>?> getSettings() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return null;

    final response = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>> createSettings({
    required DateTime periodStartDate,
  }) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_settings')
        .insert({
          'user_id': userId,
          'period_start_date': periodStartDate.toIso8601String().split('T')[0],
        })
        .select()
        .single();

    return response;
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> data) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_settings')
        .update(data)
        .eq('user_id', userId)
        .select()
        .single();

    return response;
  }
}
