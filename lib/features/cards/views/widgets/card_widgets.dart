import 'package:flutter/foundation.dart';
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (card.rarity == CardRarity.legendary)
                const _LegendaryCardShimmer(),
              if (card.rarity == CardRarity.epic) const _EpicCardSparkles(),
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
                        Text(
                          card.position,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: brand.cardTextSecondary,
                          ),
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

class _LegendaryCardShimmer extends StatefulWidget {
  const _LegendaryCardShimmer();

  @override
  State<_LegendaryCardShimmer> createState() => _LegendaryCardShimmerState();
}

class _LegendaryCardShimmerState extends State<_LegendaryCardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travelDistance = constraints.maxWidth + constraints.maxHeight;

          return AnimatedBuilder(
            key: const ValueKey('legendary-card-shimmer'),
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -travelDistance / 2 + travelDistance * _controller.value,
                  0,
                ),
                child: child,
              );
            },
            child: Transform.rotate(
              angle: -0.35,
              child: Center(
                child: Container(
                  width: constraints.maxWidth * 0.24,
                  height: constraints.maxHeight * 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EpicCardSparkles extends StatefulWidget {
  const _EpicCardSparkles();

  @override
  State<_EpicCardSparkles> createState() => _EpicCardSparklesState();
}

class _EpicCardSparklesState extends State<_EpicCardSparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        key: const ValueKey('epic-card-sparkles'),
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _EpicSparklesPainter(progress: _controller.value),
        ),
      ),
    );
  }
}

class _EpicSparklesPainter extends CustomPainter {
  const _EpicSparklesPainter({required this.progress});

  final double progress;

  static const _sparkles = <(Offset, double, double)>[
    (Offset(0.12, 0.16), 5.0, 0.00),
    (Offset(0.79, 0.12), 3.5, 0.18),
    (Offset(0.91, 0.31), 5.5, 0.42),
    (Offset(0.18, 0.43), 3.0, 0.66),
    (Offset(0.72, 0.52), 4.5, 0.84),
    (Offset(0.08, 0.67), 4.0, 0.30),
    (Offset(0.88, 0.76), 3.0, 0.57),
    (Offset(0.26, 0.86), 5.0, 0.75),
    (Offset(0.62, 0.91), 3.5, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (position, baseRadius, phaseOffset) in _sparkles) {
      final phase = (progress + phaseOffset) % 1;
      final intensity = 1 - (phase * 2 - 1).abs();
      final radius = baseRadius * (0.45 + intensity * 0.75);
      final center = Offset(
        position.dx * size.width,
        position.dy * size.height,
      );
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 + intensity * 0.68)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..quadraticBezierTo(
          center.dx + radius * 0.18,
          center.dy - radius * 0.18,
          center.dx + radius,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx + radius * 0.18,
          center.dy + radius * 0.18,
          center.dx,
          center.dy + radius,
        )
        ..quadraticBezierTo(
          center.dx - radius * 0.18,
          center.dy + radius * 0.18,
          center.dx - radius,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx - radius * 0.18,
          center.dy - radius * 0.18,
          center.dx,
          center.dy - radius,
        )
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_EpicSparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
