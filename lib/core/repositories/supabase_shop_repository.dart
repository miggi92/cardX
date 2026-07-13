import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/shop/models/pack_model.dart';
import 'package:flutter/material.dart';

class SupabaseShopRepository {
  final _supabase = Supabase.instance.client;

  Future<List<PackModel>> getAvailablePacks() async {
    final response = await _supabase.from('packs').select();
    return response.map((json) {
      final List<dynamic> colorsList = json['gradient_colors'];
      final List<Color> colors = colorsList.map((hex) {
        final hexColor = hex.replaceAll('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      }).toList();

      return PackModel(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        type: PackType.values.byName(json['type']),
        filterValue: json['filter_value'],
        gradientColors: colors,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFilteredPlayerPool(
    PackType type,
    String filterValue,
  ) async {
    if (type == PackType.club) {
      return await _supabase
          .from('player_pool')
          .select('*, clubs!inner(*)')
          .eq('clubs.name', filterValue);
    }

    final String column = type == PackType.sport ? 'sport' : 'league';
    return await _supabase
        .from('player_pool')
        .select('*, clubs(*)')
        .eq(column, filterValue);
  }

  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    return await _supabase.from('player_pool').select('*, clubs(*)');
  }
}
