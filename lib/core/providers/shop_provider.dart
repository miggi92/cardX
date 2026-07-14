import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/sport_utils.dart';
import '../../../core/repositories/supabase_shop_repository.dart';
import '../../features/cards/models/card_rarity.dart';
import '../../features/shop/models/pack_model.dart';
import 'storage_image_provider.dart';

final shopRepoProvider = Provider(
  (ref) => SupabaseShopRepository(
    imageResolver: ref.watch(storageImageResolverProvider),
  ),
);

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
    final sportId = normalizeSportId((player['sport'] as String?) ?? '');
    countsBySport[sportId] = (countsBySport[sportId] ?? 0) + 1;
  }

  return countsBySport.map(
    (sport, playerCount) =>
        MapEntry(sport, playerCount * CardRarity.values.length),
  );
});
