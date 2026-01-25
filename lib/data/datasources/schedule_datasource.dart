import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class ScheduleDatasource {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('scheduled_work')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('scheduled_work')
        .select()
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T')[0])
        .lte('date', end.toIso8601String().split('T')[0]);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> create(DateTime date) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('scheduled_work')
        .insert({
          'user_id': userId,
          'date': date.toIso8601String().split('T')[0],
        })
        .select()
        .single();

    return response;
  }

  Future<void> delete(String id) async {
    await _client.from('scheduled_work').delete().eq('id', id);
  }

  Future<void> deleteByDate(DateTime date) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return;

    await _client
        .from('scheduled_work')
        .delete()
        .eq('user_id', userId)
        .eq('date', date.toIso8601String().split('T')[0]);
  }
}
