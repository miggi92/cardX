import 'package:flutter/material.dart';
import 'package:cardx/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../cards/models/card_model.dart';
import '../../cards/views/widgets/card_widgets.dart';
import '../../cards/views/widgets/flip_card_widget.dart';

class PackRevealScreen extends StatefulWidget {
  final List<CardModel> cards;
  final String? backLogoUrl;

  const PackRevealScreen({super.key, required this.cards, this.backLogoUrl});

  @override
  State<PackRevealScreen> createState() => _PackRevealScreenState();
}

class _PackRevealScreenState extends State<PackRevealScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  bool _showOverview = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          _showOverview
              ? l10n.packRevealOverviewTitle(widget.cards.length)
              : l10n.packRevealTitle,
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: brand.pageGradient),
        child: SafeArea(
          child: _showOverview
              ? _buildOverview(context, l10n)
              : _buildReveal(context, l10n),
        ),
      ),
    );
  }

  Widget _buildReveal(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 500,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: Transform.scale(scale: value, child: child),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: FlipCardWidget(
                    card: widget.cards[index],
                    backLogoUrl: widget.backLogoUrl,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        Text(
          l10n.packRevealSwipeHint,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          key: const ValueKey('collect-cards-button'),
          onPressed: () => setState(() => _showOverview = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
          ),
          icon: const Icon(Icons.grid_view),
          label: Text(l10n.packRevealCollectCards),
        ),
      ],
    );
  }

  Widget _buildOverview(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 500
            ? 3
            : 2;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                key: const ValueKey('pulled-cards-overview'),
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.71,
                ),
                itemCount: widget.cards.length,
                itemBuilder: (context, index) => CardWidget(
                  card: widget.cards[index],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('finish-card-overview-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    foregroundColor: theme.colorScheme.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.check),
                  label: Text(l10n.packRevealDone),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
