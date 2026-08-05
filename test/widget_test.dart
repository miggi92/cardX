import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cardx/core/theme/app_theme.dart';
import 'package:cardx/features/cards/models/card_model.dart';
import 'package:cardx/features/cards/models/card_rarity.dart';
import 'package:cardx/features/cards/models/player_stats.dart';
import 'package:cardx/features/cards/views/widgets/card_widgets.dart';

void main() {
  testWidgets('App theme applies Material 3', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: Text('CardX')),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(find.text('CardX'), findsOneWidget);
  });

  testWidgets('special rarity cards render only their own effect', (
    WidgetTester tester,
  ) async {
    Future<void> pumpCard(CardRarity rarity) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                child: CardWidget(
                  card: CardModel(
                    id: rarity.name,
                    playerName: 'Test Player',
                    position: 'ST',
                    teamName: 'Test Club',
                    teamLogoUrl: '',
                    playerImageUrl: '',
                    rarity: rarity,
                    stats: const PlayerStats(goals: 10, games: 20),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await pumpCard(CardRarity.legendary);
    expect(
      find.byKey(const ValueKey('legendary-card-shimmer')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('epic-card-sparkles')), findsNothing);

    await pumpCard(CardRarity.epic);
    expect(find.byKey(const ValueKey('legendary-card-shimmer')), findsNothing);
    expect(find.byKey(const ValueKey('epic-card-sparkles')), findsOneWidget);

    await pumpCard(CardRarity.common);
    expect(find.byKey(const ValueKey('legendary-card-shimmer')), findsNothing);
    expect(find.byKey(const ValueKey('epic-card-sparkles')), findsNothing);
  });
}
