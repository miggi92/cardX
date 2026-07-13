import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCoinRepository {
  final _supabase = Supabase.instance.client;

  Future<int> getCoins() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('profiles')
        .select('coins')
        .eq('id', userId)
        .single();

    return response['coins'] as int;
  }

  Future<void> saveCoins(int amount) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('profiles').update({'coins': amount}).eq('id', userId);
  }

  Future<DateTime?> getLastFreePackDate() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('profiles')
        .select('last_free_pack')
        .eq('id', userId)
        .single();

    if (response['last_free_pack'] == null) return null;
    return DateTime.parse(response['last_free_pack'] as String);
  }

  Future<void> updateLastFreePackDate() async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase
        .from('profiles')
        .update({'last_free_pack': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }
}
