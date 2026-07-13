import 'package:cardx/core/providers/shop_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cards/models/card_model.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/theme/app_theme.dart';
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

  Future<void> buyAndOpenPack(
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

  String _typeLabel(PackType type) {
    switch (type) {
      case PackType.club:
        return 'Club Pack';
      case PackType.sport:
        return 'Sport Pack';
      case PackType.league:
        return 'League Pack';
    }
  }

  IconData _typeIcon(PackType type) {
    switch (type) {
      case PackType.club:
        return Icons.shield_outlined;
      case PackType.sport:
        return Icons.sports_soccer_outlined;
      case PackType.league:
        return Icons.emoji_events_outlined;
    }
  }

  Widget _buildPackLogo(PackModel pack) {
    final logoUrl = pack.logoUrl;
    if (pack.type != PackType.club || logoUrl == null || logoUrl.isEmpty) {
      return Icon(_typeIcon(pack.type), color: Colors.white, size: 16);
    }

    return ClipOval(
      child: Container(
        width: 24,
        height: 24,
        color: Colors.white,
        padding: const EdgeInsets.all(2),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(_typeIcon(pack.type), color: Colors.black54, size: 14),
        ),
      ),
    );
  }

  Widget _buildCoinsChip(BuildContext context, int currentCoins) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: brand.coinBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: brand.coinBorder, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: brand.coinIcon, size: 20),
          const SizedBox(width: 6),
          Text(
            '$currentCoins Coins',
            style: theme.textTheme.labelLarge?.copyWith(
              color: brand.coinForeground,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCard(
    BuildContext context,
    WidgetRef ref,
    PackModel pack,
    int currentCoins,
  ) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final canAfford = currentCoins >= pack.price;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: pack.gradientColors.first.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          const BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pack.gradientColors.first,
                if (pack.gradientColors.length > 1) pack.gradientColors[1],
                if (pack.gradientColors.length == 1)
                  pack.gradientColors.first.withValues(alpha: 0.82),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPackLogo(pack),
                              const SizedBox(width: 6),
                              Text(
                                _typeLabel(pack.type),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${pack.price}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      pack.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kategorie: ${pack.filterValue}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => buyAndOpenPack(context, ref, pack),
                            style: FilledButton.styleFrom(
                              backgroundColor: brand.surfaceBackground,
                              foregroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: Text(
                              canAfford
                                  ? 'Für ${pack.price} Coins öffnen'
                                  : '${pack.price} Coins benötigt',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (pack.type == PackType.club &&
                  pack.logoUrl != null &&
                  pack.logoUrl!.isNotEmpty)
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.58),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2B000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.network(
                        pack.logoUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          _typeIcon(pack.type),
                          color: Colors.black54,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final currentCoins = ref.watch(coinProvider);
    final packsFuture = ref.watch(availablePacksProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: brand.pageGradient),
        child: SafeArea(
          child: packsFuture.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Fehler beim Laden des Shops:\n$err',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            data: (packs) => LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = 1;
                if (width >= 980) {
                  crossAxisCount = 3;
                } else if (width >= 640) {
                  crossAxisCount = 2;
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: width >= 640 ? 0.84 : 0.9,
                  ),
                  itemCount: packs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GridTile(
                        child: Container(
                          decoration: BoxDecoration(
                            color: brand.surfaceBackground.withValues(
                              alpha: 0.78,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: brand.surfaceBorder),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Shop',
                                          style: TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF162033),
                                            height: 0.95,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Ziehe neue Spielerkarten und erweitere deine Sammlung.',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildCoinsChip(context, currentCoins),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${packs.length} Packs verfügbar',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final pack = packs[index - 1];
                    return _buildPackCard(context, ref, pack, currentCoins);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
