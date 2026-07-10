import 'package:cardx/core/providers/coin_provider.dart';
import 'package:cardx/core/providers/collection_provider.dart';
import 'package:flutter/material.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';
import '../../cards/models/player_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'pack_reveal_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  // Eine kleine Hilfsfunktion, die uns "frisch gezogene" Karten generiert
  List<CardModel> _generateDummyPull() {
    return [
      const CardModel(
        id: '2',
        playerName: 'Lukas Müller',
        position: 'TW',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.common,
        stats: PlayerStats(goals: 0, games: 34),
      ),
      const CardModel(
        id: '3',
        playerName: 'Felix Schmidt',
        position: 'ABW',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.rare,
        stats: PlayerStats(goals: 2, games: 28),
      ),
      const CardModel(
        id: '1',
        playerName: 'Max Mustermann',
        position: 'ST',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.epic,
        stats: PlayerStats(goals: 12, games: 20),
      ),
    ];
  }

  void _buyAndOpenPack(BuildContext context, WidgetRef ref) {
    final packPrice = 500;

    // 1. Versuchen, Coins abzuheben
    final success = ref.read(coinProvider.notifier).spendCoins(packPrice);

    if (success) {
      // 2. Karten generieren
      final pulledCards = _generateDummyPull();

      // 3. Karten direkt in der globalen Sammlung speichern!
      ref.read(collectionProvider.notifier).addCards(pulledCards);

      // 4. Zur Animation navigieren
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PackRevealScreen(cards: pulledCards),
        ),
      );
    } else {
      // Fehlermeldung, wenn man pleite ist
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nicht genug Coins!')));
    }
  }

  void _openPack(BuildContext context) {
    final pulledCards = _generateDummyPull();

    // Wir navigieren zum Reveal-Screen und übergeben die gezogenen Karten
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackRevealScreen(cards: pulledCards),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCoins = ref.watch(coinProvider);

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ein simples Pack-Design
            Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
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
              child: const Center(
                child: Text(
                  'AMATEUR\nPACK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _buyAndOpenPack(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.monetization_on),
              label: const Text('Für 500 Coins öffnen'),
            ),
          ],
        ),
      ),
    );
  }
}
