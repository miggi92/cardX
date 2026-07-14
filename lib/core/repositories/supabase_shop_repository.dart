import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cardx/features/cards/models/card_model.dart';
import 'package:cardx/features/cards/models/card_rarity.dart';
import 'package:cardx/features/cards/models/player_stats.dart';
import 'package:cardx/features/shop/models/pack_model.dart';
import 'package:flutter/material.dart';
import 'package:cardx/core/providers/storage_image_provider.dart';

class SupabaseShopRepository {
  SupabaseShopRepository({
    required this._imageResolver,
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

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
    final filteredPool = await _getRandomCardsFromRpc(
      packType: type.name,
      filterValue: filterValue,
      count: count,
    );
    return await _buildCardsFromPool(filteredPool);
  }

  Future<List<CardModel>> generateRandomCardsFromAllPlayers({
    int count = 10,
  }) async {
    final allPlayers = await _getRandomCardsFromRpc(
      packType: 'all',
      filterValue: null,
      count: count,
    );
    return await _buildCardsFromPool(allPlayers);
  }

  Future<List<Map<String, dynamic>>> _getRandomCardsFromRpc({
    required String packType,
    required String? filterValue,
    required int count,
  }) async {
    final response = await _supabase.rpc(
      'pull_random_cards',
      params: {
        'p_pack_type': packType,
        'p_filter_value': filterValue,
        'p_count': count,
      },
    );

    return (response as List)
        .map(
          (row) => {
            'id': row['player_id'],
            'name': row['player_name'],
            'position': row['player_position'],
            'sport': row['player_sport'],
            'goals': row['player_goals'],
            'games': row['player_games'],
            'rarity': row['rarity'],
            'clubs': {'id': row['club_id'], 'name': row['club_name']},
          },
        )
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Future<List<CardModel>> _buildCardsFromPool(
    List<Map<String, dynamic>> playerPool,
  ) async {
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

    final pulledCards = <CardModel>[];

    for (final player in availablePlayers) {
      final club = player['clubs'] as Map<String, dynamic>;
      final rarity = CardRarity.values.byName(player['rarity'] as String);

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
}
