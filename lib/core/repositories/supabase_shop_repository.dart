import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';
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

  Future<List<CardModel>> generateRandomCardsFromFilteredPool(
    PackType type,
    String filterValue, {
    int count = 10,
  }) async {
    final filteredPool = await getFilteredPlayerPool(type, filterValue);
    return _generateRandomCardsFromPool(filteredPool, count: count);
  }

  Future<List<CardModel>> generateRandomCardsFromAllPlayers({
    int count = 10,
  }) async {
    final allPlayers = await getAllPlayers();
    return _generateRandomCardsFromPool(allPlayers, count: count);
  }

  List<CardModel> _generateRandomCardsFromPool(
    List<Map<String, dynamic>> playerPool, {
    required int count,
  }) {
    final availablePlayers = playerPool
        .where((player) => player['clubs'] != null)
        .toList();

    if (availablePlayers.isEmpty) {
      return [];
    }

    final random = Random();
    final pulledCards = <CardModel>[];

    for (int i = 0; i < count; i++) {
      final player = availablePlayers[random.nextInt(availablePlayers.length)];
      final club = player['clubs'] as Map<String, dynamic>;
      final rarity = _rollRarity(random);

      pulledCards.add(
        CardModel(
          id: '${player['id']}_${rarity.name}',
          playerName: player['name'] as String,
          position: player['position'] as String,
          teamName: club['name'] as String,
          teamLogoUrl: _supabase.storage
              .from('club-logos')
              .getPublicUrl('${club['id']}.png'),
          playerImageUrl: _supabase.storage
              .from('player-images')
              .getPublicUrl('${player['id']}.png'),
          rarity: rarity,
          stats: PlayerStats(
            goals: (player['goals'] as num).toInt(),
            games: (player['games'] as num).toInt(),
          ),
        ),
      );
    }

    return pulledCards;
  }

  CardRarity _rollRarity(Random random) {
    final roll = random.nextDouble();

    if (roll < 0.05) {
      return CardRarity.legendary;
    }
    if (roll < 0.20) {
      return CardRarity.epic;
    }
    if (roll < 0.50) {
      return CardRarity.rare;
    }

    return CardRarity.common;
  }
}
