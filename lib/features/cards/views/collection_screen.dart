import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/card_rarity.dart';
import '../models/player_stats.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleCard = CardModel(
      id: '1',
      playerName: 'Max Mustermann',
      position: 'MF',
      teamName: 'FC Musterstadt',
      rarity: CardRarity.rare,
      stats: const PlayerStats(goals: 4, games: 15),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Meine Sammlung')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.71,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return CardWidget(card: sampleCard);
        },
      ),
    );
  }
}
