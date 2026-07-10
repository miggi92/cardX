import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/shop/models/pack_model.dart';
import 'package:flutter/material.dart';

class SupabaseShopRepository {
  final _supabase = Supabase.instance.client;

  Future<List<PackModel>> getAvailablePacks() async {
    final response = await _supabase.from('packs').select();

    return response.map((json) {
      // Wandelt das Text-Array aus der DB in Flutter Color-Objekte um
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
    // Hier bestimmen wir dynamisch den Spaltennamen für die SQL-Where-Klausel
    String column;
    switch (type) {
      case PackType.club:
        column = 'club';
        break;
      case PackType.sport:
        column = 'sport';
        break;
      case PackType.league:
        column = 'league';
        break;
    }

    // Supabase filtert die Daten direkt auf dem Server
    return await _supabase.from('player_pool').select().eq(column, filterValue);
  }
}
