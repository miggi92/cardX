import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/card_rarity.dart';
import '../models/player_stats.dart';

class DemoCardScreen extends StatelessWidget {
  const DemoCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final testCard = CardModel(
      id: '1',
      playerName: 'John Doe',
      position: 'TW',
      teamName: 'Home Team',
      rarity: CardRarity.epic,
      stats: const PlayerStats(goals: 30, games: 25),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('CardX: Sports')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: CardWidget(card: testCard),
        ),
      ),
    );
  }
}
