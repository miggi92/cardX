import 'package:cardx/core/theme/app_theme.dart';
import 'package:cardx/features/cards/models/card_model.dart';
import 'package:cardx/features/cards/models/card_rarity.dart';
import 'package:cardx/features/cards/models/player_stats.dart';
import 'package:cardx/features/cards/views/widgets/card_widgets.dart';
import 'package:cardx/features/shop/views/pack_reveal_screen.dart';
import 'package:cardx/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('collecting cards opens an overview of all pulled cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cards = List.generate(
      3,
      (index) => CardModel(
        id: 'card-$index',
        playerName: 'Player $index',
        position: 'ST',
        teamName: 'Test Club',
        teamLogoUrl: '',
        playerImageUrl: '',
        rarity: CardRarity.common,
        stats: const PlayerStats(goals: 1, games: 2),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PackRevealScreen(cards: cards),
                  ),
                ),
                child: const Text('Open pack'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open pack'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collect-cards-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('pulled-cards-overview')), findsOneWidget);
    expect(find.byType(CardWidget), findsNWidgets(cards.length));
    expect(find.text('Pulled cards (3)'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('finish-card-overview-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open pack'), findsOneWidget);
  });
}