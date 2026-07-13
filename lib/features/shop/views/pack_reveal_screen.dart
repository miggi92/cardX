import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../cards/models/card_model.dart';
import '../../cards/views/widgets/flip_card_widget.dart';

class PackRevealScreen extends StatefulWidget {
  final List<CardModel> cards;

  const PackRevealScreen({super.key, required this.cards});

  @override
  State<PackRevealScreen> createState() => _PackRevealScreenState();
}

class _PackRevealScreenState extends State<PackRevealScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.8);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text('Neuer Spieler!', style: theme.textTheme.titleLarge),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: brand.pageGradient),
        child: SafeArea(
          child: Column(
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
                        child: FlipCardWidget(card: widget.cards[index]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Wische, um alle Karten zu sehen',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                ),
                child: const Text('Karten einsammeln'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
