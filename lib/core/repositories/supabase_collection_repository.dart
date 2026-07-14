import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';
import '../providers/storage_image_provider.dart';

class SupabaseCollectionRepository {
  SupabaseCollectionRepository({
    required this._imageResolver,
    SupabaseClient? supabase,
  }) : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final SupabaseStorageImageResolver _imageResolver;

  Future<List<CardModel>> getCards() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('user_cards')
        .select(
          'rarity, player_pool(id, name, position, goals, games, sport, clubs(id, name))',
        )
        .eq('user_id', userId);

    final clubIds = response
        .map((json) => json['player_pool']?['clubs']?['id'])
        .where((id) => id != null)
        .map((id) => '$id')
        .toSet();
    final playerIds = response
        .map((json) => json['player_pool']?['id'])
        .where((id) => id != null)
        .map((id) => '$id')
        .toSet();

    final clubLogoById = <String, String>{};
    final playerImageById = <String, String>{};

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

    final cards = <CardModel>[];
    for (final json in response) {
      final player = json['player_pool'];
      final club = player['clubs'];

      final logicalCardId = '${player['id']}_${json['rarity']}';

      cards.add(
        CardModel(
          id: logicalCardId,
          playerName: player['name'],
          position: player['position'],
          teamName: club['name'],
          teamLogoUrl: clubLogoById['${club['id']}'] ?? '',
          playerImageUrl: playerImageById['${player['id']}'] ?? '',
          rarity: CardRarity.values.byName(json['rarity']),
          stats: PlayerStats(goals: player['goals'], games: player['games']),
          sport: (player['sport'] as String?) ?? '',
        ),
      );
    }

    return cards;
  }

  Future<void> addCards(List<CardModel> cards) async {
    final userId = _supabase.auth.currentUser!.id;

    final insertData = cards
        .map(
          (card) => {
            'user_id': userId,
            'player_id': card.id.split('_')[0],
            'rarity': card.rarity.name,
          },
        )
        .toList();

    await _supabase.from('user_cards').insert(insertData);
  }

  Future<void> removeCard(String cardId) async {
    final userId = _supabase.auth.currentUser!.id;

    final targetPlayerId = cardId.split('_')[0];
    final targetRarity = cardId.split('_')[1];

    final response = await _supabase
        .from('user_cards')
        .select('id')
        .eq('user_id', userId)
        .eq('player_id', targetPlayerId)
        .eq('rarity', targetRarity)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      await _supabase.from('user_cards').delete().eq('id', response['id']);
    }
  }

  Future<void> syncCollection(List<CardModel> uniqueCards) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_cards').delete().eq('user_id', userId);
    if (uniqueCards.isNotEmpty) {
      await addCards(uniqueCards);
    }
  }
}
