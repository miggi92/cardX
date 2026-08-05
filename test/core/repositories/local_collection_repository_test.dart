import 'package:cardx/core/repositories/local_collection_repository.dart';
import 'package:cardx/features/cards/models/card_model.dart';
import 'package:cardx/features/cards/models/card_rarity.dart';
import 'package:cardx/features/cards/models/player_stats.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists complete collections separately per user', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalCollectionRepository(preferences);
    const card = CardModel(
      id: 'player-1_rare',
      playerName: 'Test Player',
      position: 'Forward',
      league: 'Test League',
      teamName: 'Test Club',
      teamLogoUrl: 'https://example.com/club.png',
      playerImageUrl: 'https://example.com/player.png',
      rarity: CardRarity.rare,
      stats: PlayerStats(goals: 7, games: 12),
      sport: 'football',
      season: '2025/26',
    );

    await repository.saveCards('user-a', [card]);

    expect(repository.getCards('user-a').single.toJson(), card.toJson());
    expect(repository.getCards('user-b'), isEmpty);
  });

  test('ignores malformed cached data', () async {
    SharedPreferences.setMockInitialValues({
      'user_collection.user-a': '{invalid json',
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = LocalCollectionRepository(preferences);

    expect(repository.getCards('user-a'), isEmpty);
  });
}
