import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/sport_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../models/card_model.dart';
import '../../models/card_rarity.dart';
import 'card_rarity_effects.dart';

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

  double _responsiveIconSize(
    BoxConstraints constraints, {
    required double factor,
    required double min,
    required double max,
  }) {
    final shortestSide = constraints.biggest.shortestSide;
    return clampDouble(shortestSide * factor, min, max);
  }

  IconData _sportIcon() {
    return switch (normalizeSportId(card.sport)) {
      'handball' => Icons.sports_handball,
      'soccer' => Icons.sports_soccer,
      _ => Icons.sports,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final l10n = AppLocalizations.of(context);
    final teamNames = card.stats.teams
        .map((team) => team.teamName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .join(' · ');

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (card.rarity == CardRarity.legendary)
                const LegendaryCardShimmer(),
              if (card.rarity == CardRarity.epic) const EpicCardSparkles(),
              if (card.rarity == CardRarity.rare) const RareCardLightning(),
              Padding(
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
                            color: brand.cardTextPrimary.withValues(
                              alpha: 0.16,
                            ),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: _buildRemoteImage(
                            url: card.teamLogoUrl,
                            fit: BoxFit.contain,
                            fallback: LayoutBuilder(
                              builder: (context, constraints) {
                                final iconSize = _responsiveIconSize(
                                  constraints,
                                  factor: 0.7,
                                  min: 10,
                                  max: 20,
                                );
                                return Icon(
                                  Icons.shield,
                                  color: brand.cardTextSecondary,
                                  size: iconSize,
                                );
                              },
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              card.position,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: brand.cardTextSecondary,
                              ),
                            ),
                            if (card.season.isNotEmpty)
                              Text(
                                card.season,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: brand.cardTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final iconSize = _responsiveIconSize(
                            constraints,
                            factor: 0.55,
                            min: 34,
                            max: 96,
                          );

                          return Center(
                            child: _buildRemoteImage(
                              url: card.playerImageUrl,
                              fit: BoxFit.contain,
                              fallback: Icon(
                                Icons.person,
                                color: brand.cardTextSecondary,
                                size: iconSize,
                              ),
                            ),
                          );
                        },
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
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                Text(
                                  card.teamName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: brand.cardTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (teamNames.isNotEmpty)
                                  Text(
                                    teamNames,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: brand.cardTextSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (card.sport.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: l10n == null
                                  ? card.sport
                                  : localizedSportLabel(l10n, card.sport),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: brand.cardTextPrimary.withValues(
                                    alpha: 0.14,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sportIcon(),
                                  size: 15,
                                  color: brand.cardTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
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
