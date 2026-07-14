import 'package:cardx/core/theme/app_theme.dart';
import 'package:cardx/features/cards/models/card_model.dart';
import 'package:cardx/features/cards/models/card_rarity.dart';
import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:cardx/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class CardDetailDialog extends StatefulWidget {
  final String playerName;
  final List<CardModel> cards;
  final Future<bool> Function(CardModel card, int sellValue) onSellCard;

  const CardDetailDialog({
    super.key,
    required this.playerName,
    required this.cards,
    required this.onSellCard,
  });

  @override
  State<CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends State<CardDetailDialog> {
  late final Map<String, int> _exactCounts;
  late final Map<String, CardModel> _uniqueModels;
  late final List<String> _sortedIds;
  late final List<CardModel> _uniqueCards;
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _exactCounts = {};
    _uniqueModels = {};

    for (final card in widget.cards) {
      _exactCounts[card.id] = (_exactCounts[card.id] ?? 0) + 1;
      _uniqueModels[card.id] = card;
    }

    _sortedIds = _uniqueModels.keys.toList()
      ..sort(
        (a, b) => _rarityValue(
          _uniqueModels[b]!.rarity,
        ).compareTo(_rarityValue(_uniqueModels[a]!.rarity)),
      );
    _uniqueCards = _sortedIds.map((id) => _uniqueModels[id]!).toList();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _rarityValue(CardRarity rarity) {
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

  int _sellValue(CardRarity rarity) {
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

  Color _rarityColor(BuildContext context, CardRarity rarity) {
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

  IconData _rarityIcon(CardRarity rarity) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final selectedCard = _uniqueCards[_currentIndex];
    final selectedCount = _exactCounts[selectedCard.id] ?? 0;
    final mediaSize = MediaQuery.sizeOf(context);
    final maxDialogHeight = mediaSize.height * 0.9;
    final maxDialogWidth = mediaSize.width < 700
        ? mediaSize.width * 0.95
        : 680.0;
    final cardPreviewHeight = (maxDialogHeight * 0.62).clamp(320.0, 560.0);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: brand.surfaceBorder),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxDialogHeight,
            maxWidth: maxDialogWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.playerName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: l10n.collectionClose,
                    ),
                  ],
                ),
                SizedBox(
                  height: cardPreviewHeight,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _uniqueCards.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: CardWidget(card: _uniqueCards[index]),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _currentIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${_uniqueCards.length}',
                      style: theme.textTheme.labelLarge,
                    ),
                    IconButton(
                      onPressed: _currentIndex < _uniqueCards.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_uniqueCards.length, (index) {
                      final card = _uniqueCards[index];
                      final count = _exactCounts[card.id] ?? 0;
                      final isSelected = card.id == selectedCard.id;
                      final rarityColor = _rarityColor(context, card.rarity);

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? rarityColor.withValues(alpha: 0.18)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? rarityColor
                                    : brand.surfaceBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _rarityIcon(card.rarity),
                                  size: 12,
                                  color: isSelected
                                      ? rarityColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_localizedRarityLabel(l10n, card.rarity, uppercase: true)} x$count',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.surfaceContainerLowest,
                    border: Border.all(color: brand.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _rarityColor(context, selectedCard.rarity),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_localizedRarityLabel(l10n, selectedCard.rarity, uppercase: true)} (x$selectedCount)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (selectedCount > 1)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final sold = await widget.onSellCard(
                              selectedCard,
                              _sellValue(selectedCard.rarity),
                            );
                            if (!sold) {
                              return;
                            }
                            setState(() {
                              _exactCounts[selectedCard.id] = selectedCount - 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor:
                                theme.colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.sell, size: 14),
                          label: Text(
                            l10n.collectionQuickSellWithValue(
                              _sellValue(selectedCard.rarity),
                            ),
                            style: theme.textTheme.labelMedium,
                          ),
                        )
                      else
                        Text(
                          l10n.collectionLastCopy,
                          style: theme.textTheme.labelMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
