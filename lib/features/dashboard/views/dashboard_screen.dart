import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/providers/daily_reward_provider.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';
import '../../cards/models/player_stats.dart';
import '../../shop/views/pack_reveal_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  List<CardModel> _generateFreePull() {
    return [
      const CardModel(
        id: '4',
        playerName: 'Freier Spieler',
        position: 'MF',
        teamName: 'FC Musterstadt',
        rarity: CardRarity.common,
        stats: PlayerStats(goals: 0, games: 0),
        teamLogoUrl: '',
        playerImageUrl: '',
      ),
    ];
  }

  void _claimFreePack(BuildContext context, WidgetRef ref) {
    ref.read(dailyRewardProvider.notifier).claimReward();
    final pulledCards = _generateFreePull();
    ref.read(collectionProvider.notifier).addCards(pulledCards);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PackRevealScreen(cards: pulledCards),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCoins = ref.watch(coinProvider);
    final myCards = ref.watch(collectionProvider);

    ref.watch(dailyRewardProvider);
    final canClaimReward = ref.read(dailyRewardProvider.notifier).canClaim;

    const int maxCardsInSet = 150;
    final double progressValue = myCards.length / maxCardsInSet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CardX Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentCoins.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildHeroBanner(context, ref, canClaimReward),
            const SizedBox(height: 32),
            const Text(
              'Schnellzugriff',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(),
            const SizedBox(height: 32),
            _buildProgressSection(myCards.length, maxCardsInSet, progressValue),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, WidgetRef ref, bool canClaim) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tägliches Gratis-Pack!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canClaim
                ? 'Hol dir jetzt deine neuen Spieler.'
                : 'Du hast dein Pack heute schon abgeholt.',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: canClaim ? () => _claimFreePack(context, ref) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
              disabledBackgroundColor: Colors.white30,
              disabledForegroundColor: Colors.white70,
            ),
            child: Text(canClaim ? 'Jetzt öffnen' : 'Morgen wieder verfügbar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildActionCard('Meine Sammlung', Icons.style, Colors.green),
        _buildActionCard('Mein Team', Icons.shield, Colors.orange),
        _buildActionCard('Store', Icons.store, Colors.blue),
        _buildActionCard('Rangliste', Icons.emoji_events, Colors.red),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color.shade700),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(int collected, int total, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dein Fortschritt',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress,
          minHeight: 10,
          backgroundColor: Colors.grey.shade300,
          color: Colors.blue,
          borderRadius: BorderRadius.circular(10),
        ),
        const SizedBox(height: 8),
        Text(
          '$collected von $total Karten gesammelt (${(progress * 100).toStringAsFixed(1)}%)',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
