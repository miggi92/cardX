import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/collection_provider.dart';

// Aus StatelessWidget wird ConsumerWidget
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wir holen uns alle Karten, die der Nutzer aktuell besitzt
    final myCards = ref.watch(collectionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Meine Sammlung (${myCards.length})'), // Anzahl im Titel
      ),
      // Wenn noch keine Karten da sind, zeigen wir einen Fallback
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
                  const SizedBox(height: 8),
                  const Text(
                    'Geh in den Shop und öffne dein erstes Pack!',
                    style: TextStyle(color: Colors.grey),
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
              itemCount: myCards.length,
              itemBuilder: (context, index) {
                // Wir übergeben dem CardWidget die jeweilige Karte aus der Liste
                return CardWidget(card: myCards[index]);
              },
            ),
    );
  }
}
