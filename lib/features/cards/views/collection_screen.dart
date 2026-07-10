import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/providers/coin_provider.dart';
import '../../cards/models/card_model.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  // Diese Methode öffnet das Menü von unten
  void _showQuickSellSheet(
    BuildContext context,
    WidgetRef ref,
    CardModel card,
    int count,
  ) {
    // Definieren wir einen festen Verkaufswert, z.B. abhängig von der Rarity
    final int sellValue = 100;

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
                  // 1. Karte aus der Sammlung entfernen
                  ref.read(collectionProvider.notifier).removeCard(card.id);
                  // 2. Coins gutschreiben
                  ref.read(coinProvider.notifier).addCoins(sellValue);

                  // 3. Menü schließen
                  Navigator.pop(context);

                  // 4. Kleine Erfolgsmeldung anzeigen
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myCards = ref.watch(collectionProvider);

    final Map<String, int> cardCounts = {};
    final List<CardModel> uniqueCards = [];

    for (final card in myCards) {
      if (cardCounts.containsKey(card.id)) {
        cardCounts[card.id] = cardCounts[card.id]! + 1;
      } else {
        cardCounts[card.id] = 1;
        uniqueCards.add(card);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sammlung (${uniqueCards.length} / ${myCards.length} gesamt)',
        ),
      ),
      body: myCards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Deine Sammlung ist noch leer.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.71,
              ),
              itemCount: uniqueCards.length,
              itemBuilder: (context, index) {
                final card = uniqueCards[index];
                final count = cardCounts[card.id]!;

                return GestureDetector(
                  // Klick-Logik: Nur öffnen, wenn man die Karte doppelt hat
                  onTap: () {
                    if (count > 1) {
                      _showQuickSellSheet(context, ref, card, count);
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
                              border: Border.all(color: Colors.white, width: 2),
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
    );
  }
}
