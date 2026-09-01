import 'package:flutter/material.dart';

import '../../features/user/domain/user_profile.dart';

abstract final class BauhausColors {
  static const coral = Color(0xFFF04E45);
  static const cobalt = Color(0xFF2257D9);
  static const yellow = Color(0xFFFFD84A);
  static const mint = Color(0xFF55D6BE);
  static const lilac = Color(0xFFBCA7FF);
  static const brand = coral;
  static const brandDark = cobalt;
  static const brandSoft = Color(0xFFFFE9A6);
  static const red = coral;
  static const blue = cobalt;
  static const paper = Color(0xFFF3F4F7);
  static const ink = Color(0xFF171717);
  static const darkPaper = Color(0xFF15161A);
  static const darkPanel = Color(0xFF23252B);
  static const darkSoft = Color(0xFF343740);
}

class AppTheme {
  static ThemeData light(UserMode mode) => _build(Brightness.light, mode);
  static ThemeData dark(UserMode mode) => _build(Brightness.dark, mode);

  static ThemeData _build(Brightness brightness, UserMode mode) {
    final isDark = brightness == Brightness.dark;
    final primary = mode == UserMode.creator
        ? BauhausColors.coral
        : BauhausColors.cobalt;
    final text = isDark ? Colors.white : BauhausColors.ink;
    final muted = isDark ? const Color(0xFFBEBEBE) : const Color(0xFF505050);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: BauhausColors.cobalt,
      surface: isDark ? BauhausColors.darkPanel : Colors.white,
      onSurface: text,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    ).textTheme;
    final textTheme = base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        color: text,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        color: text,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        color: text,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
        color: text,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: text,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontFamily: 'Inter',
        height: 1.4,
        color: text,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontFamily: 'Inter',
        height: 1.45,
        color: muted,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontFamily: 'Inter',
        height: 1.35,
        color: muted,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: text,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: text,
      ),
    );
    final outline = const BorderSide(color: BauhausColors.ink, width: 2.5);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: outline,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? BauhausColors.darkPaper
          : BauhausColors.paper,
      fontFamily: 'Inter',
      textTheme: textTheme,
      dividerColor: isDark ? const Color(0xFF6A6A6A) : BauhausColors.ink,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? BauhausColors.darkPanel : Colors.white,
        shape: shape,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF303030) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: outline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: outline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(
            color: BauhausColors.brandDark,
            width: 2.5,
          ),
        ),
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: outline,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          side: outline,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF303030) : Colors.white,
        selectedColor: BauhausColors.brandSoft,
        side: outline,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: textTheme.labelMedium,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? BauhausColors.darkPanel : Colors.white,
        indicatorColor: BauhausColors.yellow,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? BauhausColors.darkPanel : BauhausColors.paper,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          side: BorderSide(color: BauhausColors.ink, width: 2.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : BauhausColors.ink,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BauhausColors.brandSoft
              : Colors.white,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(BauhausColors.ink),
        trackOutlineWidth: const WidgetStatePropertyAll(2.5),
      ),
    );
  }
}
