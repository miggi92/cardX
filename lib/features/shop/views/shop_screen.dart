import 'package:cardx/core/providers/shop_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../cards/models/card_model.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../models/pack_model.dart';
import 'pack_reveal_screen.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  Future<List<CardModel>> generatePulls(WidgetRef ref, PackModel pack) async {
    final repo = ref.read(shopRepoProvider);
    return repo.generateRandomCardsFromFilteredPool(
      pack.type,
      pack.filterValue,
      count: 10,
    );
  }

  void buyAndOpenPack(
    BuildContext context,
    WidgetRef ref,
    PackModel pack,
  ) async {
    final success = await ref
        .read(coinProvider.notifier)
        .spendCoins(pack.price);

    if (!context.mounted) {
      return;
    }

    if (success) {
      // Zeige einen Ladeindikator an, während das Pack generiert wird
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pulledCards = await generatePulls(ref, pack);

      if (!context.mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop(); // Ladeindikator schließen

      if (pulledCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Spieler für dieses Pack gefunden!'),
          ),
        );
        await ref.read(coinProvider.notifier).addCoins(pack.price);
        return;
      }

      final cardsSaved = await ref
          .read(collectionProvider.notifier)
          .addCards(pulledCards);
      if (!context.mounted) {
        return;
      }
      if (!cardsSaved) {
        await ref.read(coinProvider.notifier).addCoins(pack.price);
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kauf abgebrochen, Coins wurden erstattet.'),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PackRevealScreen(cards: pulledCards),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kauf fehlgeschlagen oder nicht genug Coins!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCoins = ref.watch(coinProvider);
    final packsFuture = ref.watch(availablePacksProvider);

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
      body: packsFuture.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Fehler beim Laden des Shops: $err')),
        data: (packs) => ListView.separated(
          padding: const EdgeInsets.all(24.0),
          itemCount: packs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 32),
          itemBuilder: (context, index) {
            final pack = packs[index];

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
                      pack.name.replaceAll(' ', '\n'),
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
      ),
    );
  }
}
