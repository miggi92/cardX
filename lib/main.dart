import 'dart:ui';
import 'package:cardx/features/navigation/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/storage_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Supabase.initialize(
    url: 'https://xzjdcoadvmrprdjlrzwc.supabase.co',
    publishableKey: 'sb_publishable_88t6XwiWV3auqXQLVgWbhw_H46ODCw3',
  );

  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser == null) {
    await supabase.auth.signInAnonymously();
  }

  runApp(
    ProviderScope(
      overrides: [
        // Hier überschreiben wir den Error-Provider mit der echten, geladenen Instanz!
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CardX: Sports',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),
      home: const MainNavigationScreen(),
    );
  }
}
