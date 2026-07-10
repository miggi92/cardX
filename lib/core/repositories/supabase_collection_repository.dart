import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/cards/models/card_model.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/cards/models/player_stats.dart';

class SupabaseCollectionRepository {
  final _supabase = Supabase.instance.client;

  Future<List<CardModel>> getCards() async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase
        .from('user_cards')
        .select('*, player_pool(*, clubs(*))')
        .eq('user_id', userId);

    return response.map((json) {
      final player = json['player_pool'];
      final club = player['clubs'];

      final logoUrl = _supabase.storage
          .from('club-logos')
          .getPublicUrl('${club['id']}.png');
      final playerImageUrl = _supabase.storage
          .from('player-images')
          .getPublicUrl('${player['id']}.png');

      return CardModel(
        id: json['card_id'],
        playerName: player['name'],
        position: player['position'],
        teamName: club['name'],
        teamLogoUrl: logoUrl,
        playerImageUrl: playerImageUrl,
        rarity: CardRarity.values.byName(json['rarity']),
        stats: PlayerStats(goals: player['goals'], games: player['games']),
      );
    }).toList();
  }

  Future<void> addCards(List<CardModel> cards) async {
    final userId = _supabase.auth.currentUser!.id;

    final insertData = cards
        .map(
          (card) => {
            'user_id': userId,
            'player_id': card.id.split('_')[0],
            'card_id': card.id,
            'rarity': card.rarity.name,
          },
        )
        .toList();

    await _supabase.from('user_cards').insert(insertData);
  }

  Future<void> removeCard(String cardId) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('user_cards')
        .select('id')
        .eq('user_id', userId)
        .eq('card_id', cardId)
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
