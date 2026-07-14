import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';
import '../../features/shop/models/pack_model.dart';
import 'package:flutter/material.dart';
import '../providers/storage_image_provider.dart';

class SupabaseShopRepository {
  SupabaseShopRepository({
    required SupabaseStorageImageResolver imageResolver,
    SupabaseClient? supabase,
  }) : _imageResolver = imageResolver,
       _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final SupabaseStorageImageResolver _imageResolver;

  Future<List<PackModel>> getAvailablePacks() async {
    final response = await _supabase
        .from('packs')
        .select('id, name, price, type, filter_value, gradient_colors');
    final clubPacks = response
        .where((json) => json['type'] == PackType.club.name)
        .toList();

    final clubNames = clubPacks
        .map((json) => json['filter_value'] as String?)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final Map<String, String> clubLogoByName = {};
    if (clubNames.isNotEmpty) {
      final clubsResponse = await _supabase
          .from('clubs')
          .select('id, name')
          .inFilter('name', clubNames);

      for (final club in clubsResponse) {
        final clubName = club['name'] as String?;
        final clubId = club['id'];
        if (clubName != null && clubId != null) {
          clubLogoByName[clubName] = await _imageResolver.resolveImageUrl(
            bucketName: 'club-logos',
            objectId: '$clubId',
            isPublic: true,
          );
        }
      }
    }

    return response.map((json) {
      final List<dynamic> colorsList = json['gradient_colors'];
      final List<Color> colors = colorsList.map((hex) {
        final hexColor = hex.replaceAll('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      }).toList();

      final type = PackType.values.byName(json['type'] as String);
      final filterValue = json['filter_value'] as String;

      return PackModel(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        type: type,
        filterValue: filterValue,
        logoUrl: type == PackType.club ? clubLogoByName[filterValue] : null,
        gradientColors: colors,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getFilteredPlayerPool(
    PackType type,
    String filterValue,
  ) async {
    const playerPoolSelect =
        'id, name, position, sport, goals, games, clubs!inner(id, name)';

    if (type == PackType.club) {
      return await _supabase
          .from('player_pool')
          .select(playerPoolSelect)
          .eq('clubs.name', filterValue);
    }

    final String column = type == PackType.sport ? 'sport' : 'league';
    return await _supabase
        .from('player_pool')
        .select(playerPoolSelect)
        .eq(column, filterValue);
  }

  Future<List<Map<String, dynamic>>> getAllPlayers() async {
    return await _supabase
        .from('player_pool')
        .select('id, name, position, sport, goals, games, clubs(id, name)');
  }

  Future<List<CardModel>> generateRandomCardsFromFilteredPool(
    PackType type,
    String filterValue, {
    int count = 10,
  }) async {
    final filteredPool = await getFilteredPlayerPool(type, filterValue);
    return await _generateRandomCardsFromPool(filteredPool, count: count);
  }

  Future<List<CardModel>> generateRandomCardsFromAllPlayers({
    int count = 10,
  }) async {
    final allPlayers = await getAllPlayers();
    return await _generateRandomCardsFromPool(allPlayers, count: count);
  }

  Future<List<CardModel>> _generateRandomCardsFromPool(
    List<Map<String, dynamic>> playerPool, {
    required int count,
  }) async {
    final availablePlayers = playerPool
        .where((player) => player['clubs'] != null)
        .toList();

    if (availablePlayers.isEmpty) {
      return [];
    }

    final clubLogoById = <String, String>{};
    final playerImageById = <String, String>{};

    final clubIds = availablePlayers
        .map((player) => '${(player['clubs'] as Map<String, dynamic>)['id']}')
        .toSet();
    final playerIds = availablePlayers
        .map((player) => '${player['id']}')
        .toSet();

    await Future.wait(
      clubIds.map((clubId) async {
        clubLogoById[clubId] = await _imageResolver.resolveImageUrl(
          bucketName: 'club-logos',
          objectId: clubId,
          isPublic: true,
        );
      }),
    );

    await Future.wait(
      playerIds.map((playerId) async {
        playerImageById[playerId] = await _imageResolver.resolveImageUrl(
          bucketName: 'player-images',
          objectId: playerId,
          isPublic: false,
        );
      }),
    );

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
          teamLogoUrl: clubLogoById['${club['id']}']!,
          playerImageUrl: playerImageById['${player['id']}']!,
          rarity: rarity,
          stats: PlayerStats(
            goals: (player['goals'] as num).toInt(),
            games: (player['games'] as num).toInt(),
          ),
          sport: (player['sport'] as String?) ?? '',
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
