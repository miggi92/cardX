import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';
import '../../cards/models/player_stats.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../models/pack_model.dart';
import 'pack_reveal_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  // Unsere verfügbaren Packs im Shop
  final List<PackModel> availablePacks = const [
    PackModel(
      id: 'pack_1',
      name: 'FC Musterstadt Pack',
      price: 300,
      type: PackType.club,
      filterValue: 'FC Musterstadt',
      gradientColors: [Colors.blue, Colors.indigo],
    ),
    PackModel(
      id: 'pack_2',
      name: 'Handball Spezial',
      price: 500,
      type: PackType.sport,
      filterValue: 'Handball',
      gradientColors: [Colors.orange, Colors.red],
    ),
    PackModel(
      id: 'pack_3',
      name: 'Kreisliga Legenden',
      price: 400,
      type: PackType.league,
      filterValue: 'Kreisliga',
      gradientColors: [Colors.green, Colors.teal],
    ),
  ];

  List<CardModel> generatePulls(PackModel pack) {
    final random = Random();
    final List<CardModel> pulledCards = [];

    // Der "große" Master-Pool an Spielern (in einer echten App kommt der aus der Datenbank)
    final List<Map<String, dynamic>> masterPlayerPool = [
      {
        'baseId': '1',
        'name': 'Max Mustermann',
        'position': 'ST',
        'club': 'FC Musterstadt',
        'sport': 'Football',
        'league': 'Kreisliga',
        'goals': 12,
        'games': 20,
      },
      {
        'baseId': '2',
        'name': 'Lukas Müller',
        'position': 'TW',
        'club': 'FC Musterstadt',
        'sport': 'Football',
        'league': 'Kreisliga',
        'goals': 0,
        'games': 34,
      },
      {
        'baseId': '3',
        'name': 'Anna Schmidt',
        'position': 'RM',
        'club': 'HSG Test',
        'sport': 'Handball',
        'league': 'Bezirksliga',
        'goals': 55,
        'games': 14,
      },
      {
        'baseId': '4',
        'name': 'Tom Bauer',
        'position': 'LA',
        'club': 'HSG Test',
        'sport': 'Handball',
        'league': 'Bezirksliga',
        'goals': 42,
        'games': 15,
      },
      {
        'baseId': '5',
        'name': 'Leon Becker',
        'position': 'MF',
        'club': 'SV Dorfbach',
        'sport': 'Football',
        'league': 'Kreisliga',
        'goals': 1,
        'games': 15,
      },
    ];

    // 1. Filtern des Pools basierend auf dem gewählten Pack
    final List<Map<String, dynamic>> filteredPool = masterPlayerPool.where((
      player,
    ) {
      switch (pack.type) {
        case PackType.club:
          return player['club'] == pack.filterValue;
        case PackType.sport:
          return player['sport'] == pack.filterValue;
        case PackType.league:
          return player['league'] == pack.filterValue;
      }
    }).toList();

    // Falls der Filter leer ist (Sicherheitsnetz)
    if (filteredPool.isEmpty) return [];

    // 2. 10 Karten aus dem gefilterten Pool ziehen
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

      pulledCards.add(
        CardModel(
          id: '${player['baseId']}_${rarity.name}',
          playerName: player['name'] as String,
          position: player['position'] as String,
          teamName:
              player['club']
                  as String, // Der Teamname kommt jetzt dynamisch aus dem Pool
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

  void buyAndOpenPack(BuildContext context, WidgetRef ref, PackModel pack) {
    final success = ref.read(coinProvider.notifier).spendCoins(pack.price);

    if (success) {
      final pulledCards = generatePulls(pack);

      if (pulledCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler: Keine Spieler für dieses Pack gefunden!'),
          ),
        );
        ref
            .read(coinProvider.notifier)
            .addCoins(pack.price); // Geld zurückgeben
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
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: availablePacks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 32),
        itemBuilder: (context, index) {
          final pack = availablePacks[index];

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
                    pack.name.replaceAll(
                      ' ',
                      '\n',
                    ), // Zeilenumbruch bei Leerzeichen für die Optik
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
    );
  }
}
