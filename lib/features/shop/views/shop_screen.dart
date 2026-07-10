import 'dart:math';
import 'package:cardx/core/providers/shop_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';
import '../../cards/models/player_stats.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../models/pack_model.dart';
import 'pack_reveal_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Future<List<CardModel>> generatePulls(WidgetRef ref, PackModel pack) async {
    final random = Random();
    final List<CardModel> pulledCards = [];
    final supabase = Supabase.instance.client;

    // 1. Hole nur die passenden Spieler aus dem Supabase-Pool
    final repo = ref.read(shopRepoProvider);
    final filteredPool = await repo.getFilteredPlayerPool(
      pack.type,
      pack.filterValue,
    );

    if (filteredPool.isEmpty) return [];

    // 2. Erzeuge 10 Karten basierend auf den Wahrscheinlichkeiten
    for (int i = 0; i < 10; i++) {
      final double roll = random.nextDouble();
      CardRarity rarity;

      if (roll < 0.05) {
        rarity = CardRarity.legendary;
      } else if (roll < 0.20) {
        rarity = CardRarity.epic;
      } else if (roll < 0.50) {
        rarity = CardRarity.rare;
      } else {
        rarity = CardRarity.common;
      }

      final player = filteredPool[random.nextInt(filteredPool.length)];
      final club = player['clubs'];

      if (club == null) {
        continue; // Überspringt den Eintrag sicher, falls die Beziehungsdaten fehlen
      }

      final logoUrl = supabase.storage
          .from('club-logos')
          .getPublicUrl('${club['id']}.png');
      final playerImageUrl = supabase.storage
          .from('player-images')
          .getPublicUrl('${player['id']}.png');

      pulledCards.add(
        CardModel(
          id: '${player['id']}_${rarity.name}',
          playerName: player['name'] as String,
          position: player['position'] as String,
          teamName: club['name'] as String,
          teamLogoUrl: logoUrl,
          playerImageUrl: playerImageUrl,
          rarity: rarity,
          stats: PlayerStats(
            goals: player['goals'] as int,
            games: player['games'] as int,
          ),
        ),
      );
    }

    return pulledCards;
  }

  void buyAndOpenPack(
    BuildContext context,
    WidgetRef ref,
    PackModel pack,
  ) async {
    final success = ref.read(coinProvider.notifier).spendCoins(pack.price);

    if (success) {
      // Zeige einen Ladeindikator an, während das Pack generiert wird
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pulledCards = await generatePulls(ref, pack);

      Navigator.pop(context); // Ladeindikator schließen

      if (pulledCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Spieler für dieses Pack gefunden!'),
          ),
        );
        ref.read(coinProvider.notifier).addCoins(pack.price);
        return;
      }

      ref.read(collectionProvider.notifier).addCards(pulledCards);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PackRevealScreen(cards: pulledCards),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nicht genug Coins!')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCoins = ref.watch(coinProvider);
    final packsFuture = ref.watch(availablePacksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CardX Shop'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                '💰 $currentCoins',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: packsFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Fehler beim Laden des Shops: $err')),
        data: (packs) => ListView.separated(
          padding: const EdgeInsets.all(24.0),
          itemCount: packs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 32),
          itemBuilder: (context, index) {
            final pack = packs[index];

            return Column(
              children: [
                Container(
                  width: 200,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: pack.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 15,
                        offset: Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.amber, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      pack.name.replaceAll(' ', '\n'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => buyAndOpenPack(context, ref, pack),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  icon: const Icon(Icons.monetization_on),
                  label: Text('Für ${pack.price} Coins öffnen'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
