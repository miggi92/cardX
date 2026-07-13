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

  int getRarityValue(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.legendary:
        return 4;
      case CardRarity.epic:
        return 3;
      case CardRarity.rare:
        return 2;
      case CardRarity.common:
        return 1;
    }
  }

  Color getRarityColor(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.legendary:
        return Colors.orange;
      case CardRarity.epic:
        return Colors.purple;
      case CardRarity.rare:
        return Colors.blue;
      case CardRarity.common:
        return Colors.grey;
    }
  }

  Future<bool> sellCard(CardModel card, int sellValue) async {
    final removed = await ref
        .read(collectionProvider.notifier)
        .removeCard(card.id);
    if (!removed) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karte konnte nicht verkauft werden.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final credited = await ref.read(coinProvider.notifier).addCoins(sellValue);
    if (!credited) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coins konnten nicht gutgeschrieben werden.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${card.playerName} (${card.rarity.name}) verkauft für $sellValue Coins!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    return true;
  }

  void showPlayerDetailsSheet(String playerName, List<CardModel> cards) {
    final Map<String, int> exactCounts = {};
    final Map<String, CardModel> uniqueModels = {};

    for (final card in cards) {
      exactCounts[card.id] = (exactCounts[card.id] ?? 0) + 1;
      uniqueModels[card.id] = card;
    }

    final sortedIds = uniqueModels.keys.toList()
      ..sort(
        (a, b) => getRarityValue(
          uniqueModels[b]!.rarity,
        ).compareTo(getRarityValue(uniqueModels[a]!.rarity)),
      );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playerName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...sortedIds.map((id) {
                    final card = uniqueModels[id]!;
                    final count = exactCounts[id]!;
                    final sellValue = getSellValue(card.rarity);

                    if (count == 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: getRarityColor(card.rarity),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${card.rarity.name.toUpperCase()} (x$count)',
                              ),
                            ],
                          ),
                          if (count > 1)
                            ElevatedButton.icon(
                              onPressed: () async {
                                final sold = await sellCard(card, sellValue);
                                if (!sold) {
                                  return;
                                }
                                setSheetState(() {
                                  exactCounts[id] = exactCounts[id]! - 1;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              icon: const Icon(Icons.sell, size: 16),
                              label: Text('Quick Sell (+$sellValue)'),
                            )
                          else
                            const Text(
                              'Letztes Exemplar',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Schließen',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
              onPressed: () async {
                final duplicatesRemoved = await ref
                    .read(collectionProvider.notifier)
                    .removeDuplicates();
                if (!duplicatesRemoved) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Duplikate konnten nicht verkauft werden.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final coinsAdded = await ref
                    .read(coinProvider.notifier)
                    .addCoins(totalValue);
                if (!coinsAdded) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Coins konnten nicht gutgeschrieben werden.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!context.mounted) return;

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

  Widget buildRarityBadge(CardRarity rarity, int count) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getRarityColor(rarity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        'x$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myCards = ref.watch(collectionProvider);

    int totalDuplicateCount = 0;
    int totalDuplicateValue = 0;
    final Map<String, int> duplicateCheck = {};

    for (final card in myCards) {
      if (duplicateCheck.containsKey(card.id)) {
        totalDuplicateCount++;
        totalDuplicateValue += getSellValue(card.rarity);
      } else {
        duplicateCheck[card.id] = 1;
      }
    }

    final String query = searchController.text.toLowerCase();
    final List<CardModel> filteredCards = myCards.where((card) {
      final matchesSearch = card.playerName.toLowerCase().contains(query);
      final matchesRarity =
          selectedRarity == null || card.rarity == selectedRarity;
      return matchesSearch && matchesRarity;
    }).toList();

    final Map<String, Map<String, List<CardModel>>> groupedByTeamAndPlayer = {};
    for (final card in filteredCards) {
      if (!groupedByTeamAndPlayer.containsKey(card.teamName)) {
        groupedByTeamAndPlayer[card.teamName] = {};
      }
      if (!groupedByTeamAndPlayer[card.teamName]!.containsKey(
        card.playerName,
      )) {
        groupedByTeamAndPlayer[card.teamName]![card.playerName] = [];
      }
      groupedByTeamAndPlayer[card.teamName]![card.playerName]!.add(card);
    }

    final sortedTeamNames = groupedByTeamAndPlayer.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Sammlung (${myCards.length} gesamt)')),
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
                      final playersMap = groupedByTeamAndPlayer[teamName]!;
                      final sortedPlayerNames = playersMap.keys.toList()
                        ..sort();

                      // Hole die Logo-URL dynamisch von der ersten Karte in dieser Vereins-Gruppe
                      final String teamLogoUrl =
                          playersMap[sortedPlayerNames.first]!
                              .first
                              .teamLogoUrl;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Row(
                              children: [
                                // Das neue dynamische Vereinslogo mit Fallback-Icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: Image.network(
                                    teamLogoUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.shield,
                                        color: Colors.blueAccent,
                                        size: 24,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  teamName,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${sortedPlayerNames.length} Spieler',
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
                                  childAspectRatio:
                                      0.58, // <-- WICHTIG: Verhältnis angepasst, damit die Badges unten Platz haben!
                                ),
                            itemCount: sortedPlayerNames.length,
                            itemBuilder: (context, playerIndex) {
                              final playerName = sortedPlayerNames[playerIndex];
                              final cardsOfPlayer = playersMap[playerName]!;

                              cardsOfPlayer.sort(
                                (a, b) => getRarityValue(
                                  b.rarity,
                                ).compareTo(getRarityValue(a.rarity)),
                              );
                              final bestCard = cardsOfPlayer.first;

                              final Map<CardRarity, int> rarityCounts = {};
                              for (final c in cardsOfPlayer) {
                                rarityCounts[c.rarity] =
                                    (rarityCounts[c.rarity] ?? 0) + 1;
                              }

                              final sortedRarities = rarityCounts.keys.toList()
                                ..sort(
                                  (a, b) => getRarityValue(
                                    b,
                                  ).compareTo(getRarityValue(a)),
                                );

                              // Logik für das "Mastered"-Feature (Alle Raritäten gesammelt)
                              final bool hasAllRarities =
                                  rarityCounts.length ==
                                  CardRarity.values.length;

                              return GestureDetector(
                                onTap: () => showPlayerDetailsSheet(
                                  playerName,
                                  cardsOfPlayer,
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        clipBehavior: Clip.none,
                                        children: [
                                          CardWidget(card: bestCard),
                                          // Die goldene Krone, wenn alle Raritäten gesammelt wurden
                                          if (hasAllRarities)
                                            const Positioned(
                                              top: -8,
                                              right: -8,
                                              child: Icon(
                                                Icons.workspace_premium,
                                                color: Colors.amber,
                                                size: 40,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black54,
                                                    blurRadius: 4,
                                                    offset: Offset(2, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Die Leiste mit den Badges ist jetzt sauber unter der Karte
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: hasAllRarities
                                            ? Colors.amber.withValues(
                                                alpha: 0.15,
                                              )
                                            : Colors.black12,
                                        borderRadius: BorderRadius.circular(12),
                                        border: hasAllRarities
                                            ? Border.all(
                                                color: Colors.amber.shade700,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: sortedRarities
                                              .map(
                                                (r) => buildRarityBadge(
                                                  r,
                                                  rarityCounts[r]!,
                                                ),
                                              )
                                              .toList(),
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
