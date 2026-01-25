import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

class RewardDatasource {
  final SupabaseClient _client = SupabaseClientService.client;

  Future<List<Map<String, dynamic>>> getAll() async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return [];

    final response = await _client
        .from('rewards')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final response =
        await _client.from('rewards').select().eq('id', id).maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>> create({
    required String name,
    String? memo,
    String? imageUrl,
  }) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('rewards')
        .insert({
          'user_id': userId,
          'name': name,
          'memo': memo,
          'image_url': imageUrl,
        })
        .select()
        .single();

    return response;
  }

  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) async {
    data['updated_at'] = DateTime.now().toIso8601String();

    final response =
        await _client.from('rewards').update(data).eq('id', id).select().single();

    return response;
  }

  Future<void> delete(String id) async {
    await _client.from('rewards').delete().eq('id', id);
  }

  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    final userId = SupabaseClientService.userId;
    if (userId == null) return null;

    final path = '$userId/$fileName';
    await _client.storage.from('reward-images').uploadBinary(path, bytes);

    final url = _client.storage.from('reward-images').getPublicUrl(path);
    return url;
  }

  Future<void> deleteImage(String imageUrl) async {
    final uri = Uri.parse(imageUrl);
    final pathSegments = uri.pathSegments;
    final bucketIndex = pathSegments.indexOf('reward-images');
    if (bucketIndex >= 0 && bucketIndex < pathSegments.length - 1) {
      final path = pathSegments.sublist(bucketIndex + 1).join('/');
      await _client.storage.from('reward-images').remove([path]);
    }
  }
}
