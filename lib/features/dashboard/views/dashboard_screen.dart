import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/providers/daily_reward_provider.dart';
import '../../../core/providers/shop_provider.dart';
import '../../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final currentCoins = ref.watch(coinProvider);
    final myCards = ref.watch(collectionProvider);
    final uniqueCollectedCards = myCards.map((card) => card.id).toSet().length;
    final totalAvailableCards = ref.watch(totalAvailableCardsProvider);
    final totalAvailableCardsBySport = ref.watch(
      totalAvailableCardsBySportProvider,
    );
    final collectedIdsBySport = <String, Set<String>>{};
    for (final card in myCards) {
      final sport = _normalizeSportName(card.sport);
      collectedIdsBySport.putIfAbsent(sport, () => <String>{}).add(card.id);
    }
    final collectedCardsBySport = {
      for (final entry in collectedIdsBySport.entries)
        entry.key: entry.value.length,
    };

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
                  color: brand.coinBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brand.coinBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: brand.coinIcon,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currentCoins.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: brand.coinForeground,
                        fontWeight: FontWeight.bold,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeroBanner(context, ref, canClaimReward),
            const SizedBox(height: 20),
            _buildOverviewStrip(
              context,
              currentCoins: currentCoins,
              collectedCards: uniqueCollectedCards,
              totalCards: totalAvailableCards,
            ),
            const SizedBox(height: 20),
            totalAvailableCards.when(
              loading: () =>
                  _buildProgressSection(context, uniqueCollectedCards, 0, null),
              error: (_, _) =>
                  _buildProgressSection(context, uniqueCollectedCards, 0, null),
              data: (maxCardsInSet) {
                final progressValue = maxCardsInSet == 0
                    ? 0.0
                    : (uniqueCollectedCards / maxCardsInSet).clamp(0.0, 1.0);
                return _buildProgressSection(
                  context,
                  uniqueCollectedCards,
                  maxCardsInSet,
                  progressValue,
                );
              },
            ),
            const SizedBox(height: 16),
            totalAvailableCardsBySport.when(
              loading: () => _buildSportProgressSection(
                context,
                collectedBySport: collectedCardsBySport,
                totalsBySport: const {},
                isLoading: true,
              ),
              error: (_, _) => _buildSportProgressSection(
                context,
                collectedBySport: collectedCardsBySport,
                totalsBySport: const {},
              ),
              data: (totalsBySport) => _buildSportProgressSection(
                context,
                collectedBySport: collectedCardsBySport,
                totalsBySport: totalsBySport,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeSportName(String rawSport) {
    final normalized = rawSport.trim();
    return normalized.isEmpty ? 'Unbekannt' : normalized;
  }

  Widget _buildHeroBanner(BuildContext context, WidgetRef ref, bool canClaim) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return Container(
      decoration: BoxDecoration(
        gradient: brand.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: brand.surfaceShadow,
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: _buildHeroOrb(const Color(0x33FFFFFF), 108),
          ),
          Positioned(
            left: -36,
            bottom: -34,
            child: _buildHeroOrb(const Color(0x22FFFFFF), 132),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tägliches Gratis-Pack',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canClaim
                      ? 'Hol dir jetzt neue Spieler und erweitere deine Sammlung.'
                      : 'Dein Gratis-Pack ist bereits geöffnet. Komm morgen für das nächste zurück.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: canClaim
                      ? () => _claimFreePack(context, ref)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: brand.surfaceBackground,
                    foregroundColor: theme.colorScheme.primary,
                    disabledBackgroundColor: brand.surfaceBackground.withValues(
                      alpha: 0.22,
                    ),
                    disabledForegroundColor: Colors.white70,
                  ),
                  child: Text(
                    canClaim ? 'Pack öffnen' : 'Morgen wieder verfügbar',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildOverviewStrip(
    BuildContext context, {
    required int currentCoins,
    required int collectedCards,
    required AsyncValue<int> totalCards,
  }) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final collectionCard = totalCards.when(
          loading: () => _buildOverviewCard(
            context,
            icon: Icons.layers_rounded,
            label: 'Sammlung',
            value: '$collectedCards / ...',
            accent: theme.colorScheme.primary,
            background: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.28,
            ),
          ),
          error: (_, _) => _buildOverviewCard(
            context,
            icon: Icons.layers_rounded,
            label: 'Sammlung',
            value: '$collectedCards Karten',
            accent: theme.colorScheme.primary,
            background: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.28,
            ),
          ),
          data: (total) => _buildOverviewCard(
            context,
            icon: Icons.layers_rounded,
            label: 'Sammlung',
            value: '$collectedCards / $total',
            accent: theme.colorScheme.primary,
            background: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.28,
            ),
          ),
        );

        final cards = [
          _buildOverviewCard(
            context,
            icon: Icons.monetization_on_rounded,
            label: 'Coins',
            value: currentCoins.toString(),
            accent: brand.coinIcon,
            background: brand.coinBackground,
          ),
          collectionCard,
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          );
        }

        return Column(
          children: [cards[0], const SizedBox(height: 12), cards[1]],
        );
      },
    );
  }

  Widget _buildOverviewCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required Color background,
  }) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.surfaceBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: brand.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: brand.surfaceShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: brand.subtleText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    int collected,
    int total,
    double? progress,
  ) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final percentage = progress == null
        ? '...'
        : (progress * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brand.surfaceBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brand.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: brand.surfaceShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dein Fortschritt',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Text(
                '$percentage%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 12),
          Text(
            '$collected von $total Karten gesammelt',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSportProgressSection(
    BuildContext context, {
    required Map<String, int> collectedBySport,
    required Map<String, int> totalsBySport,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final allSports = <String>{
      ...totalsBySport.keys,
      ...collectedBySport.keys,
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brand.surfaceBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brand.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: brand.surfaceShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fortschritt pro Sportart', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          if (isLoading)
            Text(
              'Sportarten werden geladen ...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: brand.subtleText,
              ),
            )
          else if (allSports.isEmpty)
            Text(
              'Keine Sportarten gefunden.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: brand.subtleText,
              ),
            )
          else
            ...allSports.asMap().entries.map((entry) {
              final index = entry.key;
              final sport = entry.value;
              final collected = collectedBySport[sport] ?? 0;
              final total = totalsBySport[sport] ?? 0;
              final progress = total == 0
                  ? null
                  : (collected / total).clamp(0.0, 1.0);
              final percentage = progress == null
                  ? '...'
                  : (progress * 100).toStringAsFixed(1);

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == allSports.length - 1 ? 0 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sport,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$collected von $total Karten gesammelt',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
