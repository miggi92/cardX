import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2457FF),
      brightness: brightness,
    );
    final brandTheme = brightness == Brightness.dark
        ? AppBrandTheme.dark
        : AppBrandTheme.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brandTheme.pageBackgroundStart,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      textTheme: _buildTextTheme(colorScheme),
      extensions: <ThemeExtension<dynamic>>[brandTheme],
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }
}

class AppBrandTheme extends ThemeExtension<AppBrandTheme> {
  const AppBrandTheme({
    required this.pageBackgroundStart,
    required this.pageBackgroundEnd,
    required this.heroStart,
    required this.heroEnd,
    required this.coinBackground,
    required this.coinBorder,
    required this.coinForeground,
    required this.coinIcon,
    required this.surfaceBackground,
    required this.surfaceBorder,
    required this.surfaceShadow,
    required this.subtleText,
  });

  final Color pageBackgroundStart;
  final Color pageBackgroundEnd;
  final Color heroStart;
  final Color heroEnd;
  final Color coinBackground;
  final Color coinBorder;
  final Color coinForeground;
  final Color coinIcon;
  final Color surfaceBackground;
  final Color surfaceBorder;
  final Color surfaceShadow;
  final Color subtleText;

  LinearGradient get pageGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [pageBackgroundStart, pageBackgroundEnd],
  );

  LinearGradient get heroGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [heroStart, heroEnd],
  );

  static const light = AppBrandTheme(
    pageBackgroundStart: Color(0xFFF6F8FF),
    pageBackgroundEnd: Color(0xFFEFF4FB),
    heroStart: Color(0xFF1F5EFF),
    heroEnd: Color(0xFF7A4BFF),
    coinBackground: Color(0xFFFFF3D6),
    coinBorder: Color(0xFFFFD88B),
    coinForeground: Color(0xFF6A3E00),
    coinIcon: Color(0xFFB36A00),
    surfaceBackground: Color(0xFFFFFFFF),
    surfaceBorder: Color(0xFFDCE7FF),
    surfaceShadow: Color(0x1A000000),
    subtleText: Color(0xFF4A5877),
  );

  static const dark = AppBrandTheme(
    pageBackgroundStart: Color(0xFF0B1220),
    pageBackgroundEnd: Color(0xFF121C31),
    heroStart: Color(0xFF315BFF),
    heroEnd: Color(0xFF8A5CFF),
    coinBackground: Color(0xFF31250E),
    coinBorder: Color(0xFF6B5220),
    coinForeground: Color(0xFFFFE6B5),
    coinIcon: Color(0xFFFFC85E),
    surfaceBackground: Color(0xFF172033),
    surfaceBorder: Color(0xFF2A3857),
    surfaceShadow: Color(0x33000000),
    subtleText: Color(0xFFB5C0D9),
  );

  @override
  AppBrandTheme copyWith({
    Color? pageBackgroundStart,
    Color? pageBackgroundEnd,
    Color? heroStart,
    Color? heroEnd,
    Color? coinBackground,
    Color? coinBorder,
    Color? coinForeground,
    Color? coinIcon,
    Color? surfaceBackground,
    Color? surfaceBorder,
    Color? surfaceShadow,
    Color? subtleText,
  }) {
    return AppBrandTheme(
      pageBackgroundStart: pageBackgroundStart ?? this.pageBackgroundStart,
      pageBackgroundEnd: pageBackgroundEnd ?? this.pageBackgroundEnd,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      coinBackground: coinBackground ?? this.coinBackground,
      coinBorder: coinBorder ?? this.coinBorder,
      coinForeground: coinForeground ?? this.coinForeground,
      coinIcon: coinIcon ?? this.coinIcon,
      surfaceBackground: surfaceBackground ?? this.surfaceBackground,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      surfaceShadow: surfaceShadow ?? this.surfaceShadow,
      subtleText: subtleText ?? this.subtleText,
    );
  }

  @override
  AppBrandTheme lerp(ThemeExtension<AppBrandTheme>? other, double t) {
    if (other is! AppBrandTheme) {
      return this;
    }

    return AppBrandTheme(
      pageBackgroundStart:
          Color.lerp(pageBackgroundStart, other.pageBackgroundStart, t) ??
          pageBackgroundStart,
      pageBackgroundEnd:
          Color.lerp(pageBackgroundEnd, other.pageBackgroundEnd, t) ??
          pageBackgroundEnd,
      heroStart: Color.lerp(heroStart, other.heroStart, t) ?? heroStart,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t) ?? heroEnd,
      coinBackground:
          Color.lerp(coinBackground, other.coinBackground, t) ?? coinBackground,
      coinBorder: Color.lerp(coinBorder, other.coinBorder, t) ?? coinBorder,
      coinForeground:
          Color.lerp(coinForeground, other.coinForeground, t) ?? coinForeground,
      coinIcon: Color.lerp(coinIcon, other.coinIcon, t) ?? coinIcon,
      surfaceBackground:
          Color.lerp(surfaceBackground, other.surfaceBackground, t) ??
          surfaceBackground,
      surfaceBorder:
          Color.lerp(surfaceBorder, other.surfaceBorder, t) ?? surfaceBorder,
      surfaceShadow:
          Color.lerp(surfaceShadow, other.surfaceShadow, t) ?? surfaceShadow,
      subtleText: Color.lerp(subtleText, other.subtleText, t) ?? subtleText,
    );
  }
}
