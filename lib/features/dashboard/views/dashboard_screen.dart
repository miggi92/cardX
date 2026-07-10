import 'package:cardx/core/providers/collection_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardx/core/providers/coin_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCoins = ref.watch(coinProvider);
    final myCards = ref.watch(collectionProvider);

    const int maxCardsInSet = 150;
    final double progressValue = myCards.length / maxCardsInSet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CardX Dashboard'),
        actions: [
          // Coins Anzeige in der AppBar
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
            _buildHeroBanner(),
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

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
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
          const Text(
            'Hol dir jetzt deine neuen Spieler.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Action: Gehe zum Pack-Opening
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
            ),
            child: const Text('Jetzt öffnen'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // ListView übernimmt das Scrollen
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5, // Breite zu Höhe der Kacheln
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
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
