import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cardx/core/theme/app_theme.dart';

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
}
