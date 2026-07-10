import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/providers/coin_provider.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController searchController = TextEditingController();
  CardRarity? selectedRarity;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  int getSellValue(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.legendary:
        return 200;
      case CardRarity.epic:
        return 100;
      case CardRarity.rare:
        return 50;
      case CardRarity.common:
        return 10;
    }
  }

  void showQuickSellSheet(CardModel card, int count) {
    final int sellValue = getSellValue(card.rarity);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Karte verkaufen',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Du besitzt ${card.playerName} $count Mal. Möchtest du eine Kopie per Quick Sell verkaufen?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(collectionProvider.notifier).removeCard(card.id);
                  ref.read(coinProvider.notifier).addCoins(sellValue);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${card.playerName} verkauft für $sellValue Coins!',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.monetization_on),
                label: Text('Quick Sell (+ $sellValue Coins)'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Abbrechen',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // NEU: Der Dialog für den Massen-Verkauf
  void showBulkSellDialog(int duplicateCount, int totalValue) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alle Duplikate verkaufen?'),
          content: Text(
            'Du stehst kurz davor, $duplicateCount doppelte Karten zu verkaufen. Dafür erhältst du $totalValue Coins.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Abbrechen',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // 1. Alle Duplikate auf einmal aus der Sammlung werfen
                ref.read(collectionProvider.notifier).removeDuplicates();
                // 2. Den berechneten Gesamtwert gutschreiben
                ref.read(coinProvider.notifier).addCoins(totalValue);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$duplicateCount Karten für $totalValue Coins verkauft!',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Verkaufen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myCards = ref.watch(collectionProvider);

    final Map<String, int> cardCounts = {};
    final List<CardModel> uniqueCards = [];

    // NEU: Zähler für die Duplikate und deren Gesamtwert
    int totalDuplicateCount = 0;
    int totalDuplicateValue = 0;

    for (final card in myCards) {
      if (cardCounts.containsKey(card.id)) {
        cardCounts[card.id] = cardCounts[card.id]! + 1;

        // Jedes gefundene Duplikat zum Gesamtwert addieren
        totalDuplicateCount++;
        totalDuplicateValue += getSellValue(card.rarity);
      } else {
        cardCounts[card.id] = 1;
        uniqueCards.add(card);
      }
    }

    final String query = searchController.text.toLowerCase();

    final List<CardModel> filteredCards = uniqueCards.where((card) {
      final matchesSearch = card.playerName.toLowerCase().contains(query);
      final matchesRarity =
          selectedRarity == null || card.rarity == selectedRarity;
      return matchesSearch && matchesRarity;
    }).toList();

    final Map<String, List<CardModel>> groupedByTeam = {};
    for (final card in filteredCards) {
      if (!groupedByTeam.containsKey(card.teamName)) {
        groupedByTeam[card.teamName] = [];
      }
      groupedByTeam[card.teamName]!.add(card);
    }

    for (final team in groupedByTeam.keys) {
      groupedByTeam[team]!.sort((a, b) => a.playerName.compareTo(b.playerName));
    }

    final sortedTeamNames = groupedByTeam.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sammlung (${uniqueCards.length} / ${myCards.length} gesamt)',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Spieler suchen...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CardRarity?>(
                      value: selectedRarity,
                      hint: const Text('Alle'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Alle Raritäten'),
                        ),
                        ...CardRarity.values.map(
                          (rarity) => DropdownMenuItem(
                            value: rarity,
                            child: Text(rarity.name.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedRarity = value),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NEU: Der Bulk-Sell Button, erscheint nur, wenn es Duplikate gibt!
          if (totalDuplicateCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ElevatedButton.icon(
                onPressed: () => showBulkSellDialog(
                  totalDuplicateCount,
                  totalDuplicateValue,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.monetization_on),
                label: Text(
                  'Alle doppelten verkaufen (+ $totalDuplicateValue Coins)',
                ),
              ),
            ),

          Expanded(
            child: myCards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Deine Sammlung ist noch leer.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : filteredCards.isEmpty
                ? const Center(child: Text('Keine Spieler gefunden.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: sortedTeamNames.length,
                    itemBuilder: (context, index) {
                      final teamName = sortedTeamNames[index];
                      final teamCards = groupedByTeam[teamName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shield,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  teamName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${teamCards.length} Karten',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.71,
                                ),
                            itemCount: teamCards.length,
                            itemBuilder: (context, cardIndex) {
                              final card = teamCards[cardIndex];
                              final count = cardCounts[card.id]!;

                              return GestureDetector(
                                onTap: () {
                                  if (count > 1) {
                                    showQuickSellSheet(card, count);
                                  }
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CardWidget(card: card),
                                    if (count > 1)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent.shade700,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black54,
                                                blurRadius: 4,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'x$count',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 48, thickness: 2),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
