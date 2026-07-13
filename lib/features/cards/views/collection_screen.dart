import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:cardx/core/constants/sport_utils.dart';
import 'package:cardx/l10n/generated/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/providers/collection_provider.dart';
import '../../../core/providers/coin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../cards/models/card_model.dart';
import '../../cards/models/card_rarity.dart';

class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key});

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

bool _isSvgUrl(String url) {
  final uri = Uri.tryParse(url);
  final path = uri?.path.toLowerCase() ?? url.toLowerCase();
  final fragment = uri?.fragment.toLowerCase() ?? '';

  return path.endsWith('.svg') || fragment.contains('mime=image/svg+xml');
}

Widget _buildRemoteImage({
  required String url,
  required BoxFit fit,
  required Widget fallback,
  double? width,
  double? height,
}) {
  if (_isSvgUrl(url)) {
    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return SvgPicture.network(
      url,
      fit: fit,
      width: width,
      height: height,
      placeholderBuilder: (_) => fallback,
    );
  }

  return Image.network(
    url,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (_, _, _) => fallback,
  );
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  final TextEditingController searchController = TextEditingController();
  CardRarity? selectedRarity;

  ({int crossAxisCount, double childAspectRatio}) _gridConfigForWidth(
    double maxWidth,
  ) {
    if (maxWidth < 420) {
      return (crossAxisCount: 2, childAspectRatio: 0.52);
    }
    if (maxWidth < 760) {
      return (crossAxisCount: 3, childAspectRatio: 0.56);
    }
    return (crossAxisCount: 4, childAspectRatio: 0.6);
  }

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

  Color getRarityColor(BuildContext context, CardRarity rarity) {
    final brand = Theme.of(context).extension<AppBrandTheme>()!;

    switch (rarity) {
      case CardRarity.legendary:
        return brand.rarityLegendary;
      case CardRarity.epic:
        return brand.rarityEpic;
      case CardRarity.rare:
        return brand.rarityRare;
      case CardRarity.common:
        return brand.rarityCommon;
    }
  }

  Future<bool> sellCard(CardModel card, int sellValue) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final removed = await ref
        .read(collectionProvider.notifier)
        .removeCard(card.id);
    if (!removed) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.collectionSellCardFailed),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return false;
    }

    final credited = await ref.read(coinProvider.notifier).addCoins(sellValue);
    if (!credited) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.collectionCreditCoinsFailed),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return false;
    }

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.collectionSoldCardForCoins(
            card.playerName,
            _localizedRarityLabel(l10n, card.rarity, uppercase: true),
            sellValue,
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    return true;
  }

  void showPlayerDetailsSheet(String playerName, List<CardModel> cards) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
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
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: brand.surfaceBorder),
      ),
      builder: (context) {
        final sheetTheme = Theme.of(context);
        final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerName,
                        style: sheetTheme.textTheme.titleLarge?.copyWith(
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
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: getRarityColor(
                                          context,
                                          card.rarity,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_localizedRarityLabel(l10n, card.rarity, uppercase: true)} (x$count)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (count > 1)
                                Flexible(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final sold = await sellCard(
                                        card,
                                        sellValue,
                                      );
                                      if (!sold) {
                                        return;
                                      }
                                      setSheetState(() {
                                        exactCounts[id] = exactCounts[id]! - 1;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: sheetTheme
                                          .colorScheme
                                          .primaryContainer,
                                      foregroundColor: sheetTheme
                                          .colorScheme
                                          .onPrimaryContainer,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                    ),
                                    icon: const Icon(Icons.sell, size: 16),
                                    label: Text(
                                      l10n.collectionQuickSellWithValue(
                                        sellValue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  l10n.collectionLastCopy,
                                  style: sheetTheme.textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            l10n.collectionClose,
                            style: sheetTheme.textTheme.labelLarge,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showBulkSellDialog(int duplicateCount, int totalValue) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        final dialogTheme = Theme.of(context);
        return AlertDialog(
          title: Text(l10n.collectionSellAllDuplicatesTitle),
          content: Text(
            l10n.collectionSellAllDuplicatesBody(duplicateCount, totalValue),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.collectionCancel,
                style: dialogTheme.textTheme.labelLarge,
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
                    SnackBar(
                      content: Text(l10n.collectionSellDuplicatesFailed),
                      backgroundColor: theme.colorScheme.error,
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
                    SnackBar(
                      content: Text(l10n.collectionCreditCoinsFailed),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                  return;
                }

                if (!context.mounted) return;

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.collectionSoldDuplicatesForCoins(
                        duplicateCount,
                        totalValue,
                      ),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
              ),
              child: Text(l10n.collectionSell),
            ),
          ],
        );
      },
    );
  }

  IconData getRarityIcon(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return Icons.adjust;
      case CardRarity.rare:
        return Icons.bolt;
      case CardRarity.epic:
        return Icons.auto_awesome;
      case CardRarity.legendary:
        return Icons.workspace_premium;
    }
  }

  Widget buildRarityTrack(
    Map<CardRarity, int> rarityCounts, {
    required bool hasAllRarities,
  }) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: hasAllRarities
            ? Colors.amber.withValues(alpha: 0.12)
            : brand.surfaceBackground.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAllRarities ? Colors.amber.shade700 : brand.surfaceBorder,
          width: hasAllRarities ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: CardRarity.values.map((rarity) {
          final count = rarityCounts[rarity] ?? 0;
          final owned = count > 0;
          final rarityColor = getRarityColor(context, rarity);

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: owned
                    ? rarityColor.withValues(alpha: 0.20)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: owned
                      ? rarityColor.withValues(alpha: 0.85)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    owned ? getRarityIcon(rarity) : Icons.lock_outline,
                    size: 16,
                    color: owned
                        ? rarityColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      color: owned
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildRarityLegend() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    Widget buildLegendChip({
      required String label,
      required IconData icon,
      required Color color,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : brand.surfaceBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? color : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: brand.surfaceBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.surfaceBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          buildLegendChip(
            label: l10n.collectionAllFilter,
            icon: Icons.grid_view,
            color: theme.colorScheme.primary,
            selected: selectedRarity == null,
            onTap: () => setState(() => selectedRarity = null),
          ),
          ...CardRarity.values.map((rarity) {
            final color = getRarityColor(context, rarity);
            return buildLegendChip(
              label: _localizedRarityLabel(l10n, rarity, uppercase: true),
              icon: getRarityIcon(rarity),
              color: color,
              selected: selectedRarity == rarity,
              onTap: () {
                setState(() {
                  selectedRarity = selectedRarity == rarity ? null : rarity;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
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

    // team -> sport -> playerName -> cards
    final Map<String, Map<String, Map<String, List<CardModel>>>>
    groupedByTeamSportPlayer = {};
    for (final card in filteredCards) {
      groupedByTeamSportPlayer.putIfAbsent(card.teamName, () => {});
      groupedByTeamSportPlayer[card.teamName]!.putIfAbsent(
        card.sport,
        () => {},
      );
      groupedByTeamSportPlayer[card.teamName]![card.sport]!.putIfAbsent(
        card.playerName,
        () => [],
      );
      groupedByTeamSportPlayer[card.teamName]![card.sport]![card.playerName]!
          .add(card);
    }

    final sortedTeamNames = groupedByTeamSportPlayer.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.collectionTitle(myCards.length))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.collectionSearchHint,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          if (myCards.isNotEmpty) ...[
            buildRarityLegend(),
            const SizedBox(height: 8),
          ],

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
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.monetization_on),
                label: Text(
                  l10n.collectionSellAllDuplicatesCta(totalDuplicateValue),
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
                          color: theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.collectionEmpty,
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : filteredCards.isEmpty
                ? Center(
                    child: Text(
                      l10n.collectionNoPlayersFound,
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: sortedTeamNames.length,
                    itemBuilder: (context, index) {
                      final teamName = sortedTeamNames[index];
                      final sportMap = groupedByTeamSportPlayer[teamName]!;
                      final sortedSports = sportMap.keys.toList()..sort();
                      final hasMultipleSports = sortedSports.length > 1;

                      // Hole die Logo-URL dynamisch von der ersten Karte in dieser Vereins-Gruppe
                      final String teamLogoUrl = sportMap[sortedSports.first]!
                          .values
                          .first
                          .first
                          .teamLogoUrl;

                      final int totalPlayerCount = sportMap.values.fold(
                        0,
                        (sum, playersMap) => sum + playersMap.length,
                      );

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
                                    color: brand.surfaceBackground.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                  child: _buildRemoteImage(
                                    url: teamLogoUrl,
                                    fit: BoxFit.contain,
                                    fallback: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final iconSize = clampDouble(
                                          constraints.biggest.shortestSide *
                                              0.72,
                                          12,
                                          22,
                                        );
                                        return Icon(
                                          Icons.shield,
                                          color: Colors.blueAccent,
                                          size: iconSize,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    teamName,
                                    style: theme.textTheme.titleLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.collectionPlayersCount(totalPlayerCount),
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          ...sortedSports.map((sport) {
                            final playersMap = sportMap[sport]!;
                            final sortedPlayerNames = playersMap.keys.toList()
                              ..sort();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasMultipleSports)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 8.0,
                                      top: 4.0,
                                    ),
                                    child: Text(
                                      localizedSportLabel(
                                        l10n,
                                        sport,
                                        unknownLabel: l10n.collectionGeneral,
                                      ).toUpperCase(),
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                  ),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final gridConfig = _gridConfigForWidth(
                                      constraints.maxWidth,
                                    );

                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount:
                                                gridConfig.crossAxisCount,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio:
                                                gridConfig.childAspectRatio,
                                          ),
                                      itemCount: sortedPlayerNames.length,
                                      itemBuilder: (context, playerIndex) {
                                        final playerName =
                                            sortedPlayerNames[playerIndex];
                                        final cardsOfPlayer =
                                            playersMap[playerName]!;

                                        cardsOfPlayer.sort(
                                          (a, b) => getRarityValue(
                                            b.rarity,
                                          ).compareTo(getRarityValue(a.rarity)),
                                        );
                                        final bestCard = cardsOfPlayer.first;

                                        final Map<CardRarity, int>
                                        rarityCounts = {};
                                        for (final c in cardsOfPlayer) {
                                          rarityCounts[c.rarity] =
                                              (rarityCounts[c.rarity] ?? 0) + 1;
                                        }

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
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              buildRarityTrack(
                                                rarityCounts,
                                                hasAllRarities: hasAllRarities,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),

                                if (hasMultipleSports &&
                                    sport != sortedSports.last)
                                  const SizedBox(height: 16),
                              ],
                            );
                          }),

                          Divider(
                            height: 48,
                            thickness: 2,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _localizedRarityLabel(
    AppLocalizations l10n,
    CardRarity rarity, {
    bool uppercase = false,
  }) {
    final value = switch (rarity) {
      CardRarity.common => l10n.rarityCommon,
      CardRarity.rare => l10n.rarityRare,
      CardRarity.epic => l10n.rarityEpic,
      CardRarity.legendary => l10n.rarityLegendary,
    };
    return uppercase ? value.toUpperCase() : value;
  }
}
