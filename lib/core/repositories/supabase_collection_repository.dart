import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';
import '../providers/storage_image_provider.dart';

class SupabaseCollectionRepository {
  SupabaseCollectionRepository({
    required SupabaseStorageImageResolver imageResolver,
    SupabaseClient? supabase,
  }) : _imageResolver = imageResolver,
       _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final SupabaseStorageImageResolver _imageResolver;

  Future<List<CardModel>> getCards() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('user_cards')
        .select('*, player_pool(*, clubs(*))')
        .eq('user_id', userId);

    final cards = <CardModel>[];
    for (final json in response) {
      final player = json['player_pool'];
      final club = player['clubs'];

      final logoUrl = await _imageResolver.resolveImageUrl(
        bucketName: 'club-logos',
        objectId: '${club['id']}',
        isPublic: true,
      );
      final playerImageUrl = await _imageResolver.resolveImageUrl(
        bucketName: 'player-images',
        objectId: '${player['id']}',
        isPublic: false,
      );

      final logicalCardId = '${player['id']}_${json['rarity']}';

      cards.add(
        CardModel(
          id: logicalCardId,
          playerName: player['name'],
          position: player['position'],
          teamName: club['name'],
          teamLogoUrl: logoUrl,
          playerImageUrl: playerImageUrl,
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
