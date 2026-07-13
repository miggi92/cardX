import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/card_model.dart';
import '../../models/card_rarity.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;

  const CardWidget({super.key, required this.card});

  Color _getRarityColor(BuildContext context) {
    final brand = Theme.of(context).extension<AppBrandTheme>()!;

    switch (card.rarity) {
      case CardRarity.common:
        return brand.rarityCommon;
      case CardRarity.rare:
        return brand.rarityRare;
      case CardRarity.epic:
        return brand.rarityEpic;
      case CardRarity.legendary:
        return brand.rarityLegendary;
    }
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
    double? width,
    double? height,
    required Widget fallback,
  }) {
    if (_isSvgUrl(url)) {
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
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return AspectRatio(
      aspectRatio: 0.71,
      child: Container(
        decoration: BoxDecoration(
          color: _getRarityColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: brand.cardBorder, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: brand.cardShadow,
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      color: brand.cardTextPrimary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: _buildRemoteImage(
                      url: card.teamLogoUrl,
                      fit: BoxFit.contain,
                      fallback: Icon(
                        Icons.shield,
                        color: brand.cardTextSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    card.position,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: brand.cardTextSecondary,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: _buildRemoteImage(
                    url: card.playerImageUrl,
                    fit: BoxFit.contain,
                    fallback: Icon(
                      Icons.person,
                      color: brand.cardTextSecondary,
                      size: 250,
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  card.playerName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: brand.cardTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    card.teamName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: brand.cardTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Divider(
                color: brand.cardTextSecondary.withValues(alpha: 0.45),
                thickness: 1,
              ),
              _buildStatsGrid(theme, brand),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, AppBrandTheme brand) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow(theme, brand, 'Goals', card.stats.goals),
            _buildStatRow(theme, brand, 'Games', card.stats.games),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    AppBrandTheme brand,
    String label,
    int value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              value.toString(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: brand.cardTextPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: brand.cardTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
