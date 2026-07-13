import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/supabase_shop_repository.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/shop/models/pack_model.dart';

final shopRepoProvider = Provider((ref) => SupabaseShopRepository());

// Lädt die Packs asynchron aus Supabase
final availablePacksProvider = FutureProvider<List<PackModel>>((ref) async {
  final repo = ref.watch(shopRepoProvider);
  return repo.getAvailablePacks();
});

final totalAvailableCardsProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(shopRepoProvider);
  final players = await repo.getAllPlayers();
  return players.length * CardRarity.values.length;
});

final totalAvailableCardsBySportProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final repo = ref.watch(shopRepoProvider);
  final players = await repo.getAllPlayers();
  final countsBySport = <String, int>{};

  for (final player in players) {
    final rawSport = (player['sport'] as String?) ?? '';
    final sport = rawSport.trim().isEmpty ? 'Unbekannt' : rawSport.trim();
    countsBySport[sport] = (countsBySport[sport] ?? 0) + 1;
  }

  return countsBySport.map(
    (sport, playerCount) =>
        MapEntry(sport, playerCount * CardRarity.values.length),
  );
});
