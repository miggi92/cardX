import 'dart:math';
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

  List<CardModel> generatePulls() {
    final random = Random();
    final List<CardModel> pulledCards = [];

    final List<Map<String, dynamic>> playerPool = [
      {
        'baseId': '1',
        'name': 'Max Mustermann',
        'position': 'ST',
        'goals': 12,
        'games': 20,
      },
      {
        'baseId': '2',
        'name': 'Lukas Müller',
        'position': 'TW',
        'goals': 0,
        'games': 34,
      },
      {
        'baseId': '3',
        'name': 'Felix Schmidt',
        'position': 'ABW',
        'goals': 2,
        'games': 28,
      },
      {
        'baseId': '5',
        'name': 'Leon Becker',
        'position': 'MF',
        'goals': 1,
        'games': 15,
      },
      {
        'baseId': '6',
        'name': 'Tim Wagner',
        'position': 'ST',
        'goals': 25,
        'games': 30,
      },
      {
        'baseId': '7',
        'name': 'Jonas Hoffmann',
        'position': 'ABW',
        'goals': 4,
        'games': 32,
      },
    ];

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

      final player = playerPool[random.nextInt(playerPool.length)];

      pulledCards.add(
        CardModel(
          id: '${player['baseId']}_${rarity.name}',
          playerName: player['name'] as String,
          position: player['position'] as String,
          teamName: 'FC Musterstadt',
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

  void buyAndOpenPack(BuildContext context, WidgetRef ref) {
    final packPrice = 500;

    final success = ref.read(coinProvider.notifier).spendCoins(packPrice);

    if (success) {
      final pulledCards = generatePulls();

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
              onPressed: () => buyAndOpenPack(context, ref),
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
