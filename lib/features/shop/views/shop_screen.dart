import 'dart:math'; // Wichtig für Random()
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';
import '../../cards/models/player_stats.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import 'pack_reveal_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  List<CardModel> _generateDummyPull() {
    final random = Random();

    // Ein Pool an möglichen Spielern
    final List<CardModel> cardPool = [
      const CardModel(
        id: '1',
        playerName: 'Max Mustermann',
        position: 'ST',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.epic,
        stats: PlayerStats(goals: 12, games: 20),
      ),
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
        id: '5',
        playerName: 'Leon Becker',
        position: 'MF',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.common,
        stats: PlayerStats(goals: 1, games: 15),
      ),
      const CardModel(
        id: '6',
        playerName: 'Tim Wagner',
        position: 'ST',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.legendary,
        stats: PlayerStats(goals: 25, games: 30),
      ),
      const CardModel(
        id: '7',
        playerName: 'Jonas Hoffmann',
        position: 'ABW',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.rare,
        stats: PlayerStats(goals: 4, games: 32),
      ),
    ];

    // Generiert eine Liste mit exakt 10 zufälligen Karten aus dem Pool
    return List.generate(10, (_) {
      final randomIndex = random.nextInt(cardPool.length);
      return cardPool[randomIndex];
    });
  }

  void _buyAndOpenPack(BuildContext context, WidgetRef ref) {
    final packPrice = 500;

    final success = ref.read(coinProvider.notifier).spendCoins(packPrice);

    if (success) {
      final pulledCards = _generateDummyPull();

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
