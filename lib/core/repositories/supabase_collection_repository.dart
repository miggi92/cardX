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
        .select()
        .eq('user_id', userId);

    return response
        .map(
          (json) => CardModel(
            id: json['card_id'],
            playerName: json['player_name'],
            position: json['position'],
            teamName: json['team_name'],
            rarity: CardRarity.values.byName(json['rarity']),
            stats: PlayerStats(goals: json['goals'], games: json['games']),
          ),
        )
        .toList();
  }

  Future<void> addCards(List<CardModel> cards) async {
    final userId = _supabase.auth.currentUser!.id;
    final insertData = cards
        .map(
          (card) => {
            'user_id': userId,
            'card_id': card.id,
            'player_name': card.playerName,
            'position': card.position,
            'team_name': card.teamName,
            'rarity': card.rarity.name,
            'goals': card.stats.goals,
            'games': card.stats.games,
          },
        )
        .toList();

    await _supabase.from('user_cards').insert(insertData);
  }

  Future<void> removeCard(String cardId) async {
    final userId = _supabase.auth.currentUser!.id;

    // Wir suchen exakt EINE Karte mit dieser ID und löschen sie (für Quick Sell)
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
    // Für den Bulk-Sell: Wir werfen alle Karten weg und speichern nur die einzigartigen neu ab
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_cards').delete().eq('user_id', userId);

    if (uniqueCards.isNotEmpty) {
      await addCards(uniqueCards);
    }
  }
}
