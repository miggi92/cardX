import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/providers/daily_reward_provider.dart';
import '../../../core/providers/shop_provider.dart';
import '../../shop/views/pack_reveal_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _claimFreePack(BuildContext context, WidgetRef ref) async {
    final canClaim = ref
        .read(dailyRewardProvider)
        .maybeWhen(data: DailyRewardNotifier.canClaimFor, orElse: () => false);
    if (!canClaim) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gratis-Pack heute bereits abgeholt.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repo = ref.read(shopRepoProvider);
      final pulledCards = await repo.generateRandomCardsFromAllPlayers(
        count: 10,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();

      if (pulledCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Spieler für das Gratis-Pack gefunden!'),
          ),
        );
        return;
      }

      final rewardClaimed = await ref
          .read(dailyRewardProvider.notifier)
          .claimReward();
      if (!context.mounted) {
        return;
      }
      if (!rewardClaimed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gratis-Pack konnte nicht gespeichert werden.'),
          ),
        );
        return;
      }

      final cardsSaved = await ref
          .read(collectionProvider.notifier)
          .addCards(pulledCards);
      if (!context.mounted) {
        return;
      }
      if (!cardsSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Karten konnten nicht gespeichert werden.'),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PackRevealScreen(cards: pulledCards),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden des Gratis-Packs: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCoins = ref.watch(coinProvider);
    final myCards = ref.watch(collectionProvider);
    final uniqueCollectedCards = myCards.map((card) => card.id).toSet().length;
    final totalAvailableCards = ref.watch(totalAvailableCardsProvider);

    final dailyReward = ref.watch(dailyRewardProvider);
    final canClaimReward = dailyReward.when(
      data: DailyRewardNotifier.canClaimFor,
      loading: () => false,
      error: (_, _) => false,
    );

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
            totalAvailableCards.when(
              loading: () =>
                  _buildProgressSection(uniqueCollectedCards, 0, null),
              error: (_, _) =>
                  _buildProgressSection(uniqueCollectedCards, 0, null),
              data: (maxCardsInSet) {
                final progressValue = maxCardsInSet == 0
                    ? 0.0
                    : (uniqueCollectedCards / maxCardsInSet).clamp(0.0, 1.0);
                return _buildProgressSection(
                  uniqueCollectedCards,
                  maxCardsInSet,
                  progressValue,
                );
              },
            ),
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

  Widget _buildProgressSection(int collected, int total, double? progress) {
    final percentage = progress == null
        ? '...'
        : (progress * 100).toStringAsFixed(1);

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
          '$collected von $total Karten gesammelt ($percentage%)',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
