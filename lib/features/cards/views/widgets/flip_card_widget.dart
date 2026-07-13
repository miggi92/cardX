import 'dart:math';
import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/card_model.dart';

class FlipCardWidget extends StatefulWidget {
  final CardModel card;
  final String? backLogoUrl;

  const FlipCardWidget({super.key, required this.card, this.backLogoUrl});

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (!_isFlipped) {
      _controller.forward();
      _isFlipped = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isFrontVisible = angle >= (pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontVisible
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: CardWidget(card: widget.card),
                  )
                : _buildCardBack(),
          );
        },
      ),
    );
  }

  Widget _buildCardBack() {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final hasRemoteBackLogo =
        widget.backLogoUrl != null && widget.backLogoUrl!.isNotEmpty;

    return AspectRatio(
      aspectRatio: 0.71,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              brand.cardBackBackgroundStart,
              brand.cardBackBackgroundEnd,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: brand.cardBackBorder, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: brand.cardShadow,
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: hasRemoteBackLogo ? 0.22 : 0.28,
              child: Padding(
                padding: const EdgeInsets.all(26),
                child: hasRemoteBackLogo
                    ? _buildRemoteBackLogo(
                        url: widget.backLogoUrl!,
                        fallback: _buildDefaultBackLogo(),
                      )
                    : _buildDefaultBackLogo(),
              ),
            ),
            Text(
              'CARDX',
              style: theme.textTheme.titleLarge?.copyWith(
                color: brand.cardBackAccent,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSvgUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? url.toLowerCase();
    final fragment = uri?.fragment.toLowerCase() ?? '';

    return path.endsWith('.svg') || fragment.contains('mime=image/svg+xml');
  }

  Widget _buildRemoteBackLogo({required String url, required Widget fallback}) {
    if (_isSvgUrl(url)) {
      if (kIsWeb) {
        return Image.network(
          url,
          fit: BoxFit.contain,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, _, _) => fallback,
        );
      }

      return SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => fallback,
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _buildDefaultBackLogo() {
    return Image.asset(
      'assets/icon/logo.png',
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) =>
          const Icon(Icons.shield, color: Colors.white70, size: 72),
    );
  }
}
