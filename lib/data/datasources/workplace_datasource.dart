import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class WorkplaceDatasource {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('workplaces')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final response = await _client
        .from('workplaces')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>> create({
    required String name,
    required int colorValue,
    bool isDefault = false,
  }) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('workplaces')
        .insert({
          'user_id': userId,
          'name': name,
          'color_value': colorValue,
          'is_default': isDefault,
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
        .from('workplaces')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return response;
  }

  Future<void> delete(String id) async {
    await _client.from('workplaces').delete().eq('id', id);
  }

  Future<void> clearDefaultFlag() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return;

    await _client
        .from('workplaces')
        .update({'is_default': false})
        .eq('user_id', userId)
        .eq('is_default', true);
  }
}
