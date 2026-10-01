import 'package:flutter/material.dart';

import 'colors.dart';

/// Typography: Cormorant Garamond for headings, Figtree for body.
abstract final class T {
  static const String headingFamily = 'CormorantGaramond';
  static const String bodyFamily = 'Figtree';

  static const TextStyle display = TextStyle(
    fontFamily: headingFamily,
    fontWeight: FontWeight.w700,
    fontSize: 32,
    height: 1.1,
    letterSpacing: -0.32,
    color: C.plum700,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: headingFamily,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 1.15,
    letterSpacing: -0.26,
    color: C.plum700,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: headingFamily,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.15,
    letterSpacing: -0.24,
    color: C.plum700,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.6,
    color: C.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.5,
    color: C.ink,
  );

  static const TextStyle small = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 1.5,
    color: C.muted,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 2.16, // 0.18em
    color: C.crimson,
  );

  static const TextStyle eyebrowOnDark = TextStyle(
    fontFamily: bodyFamily,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 2.16,
    color: C.gold,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: C.canvas,
    fontFamily: T.bodyFamily,
    colorScheme: const ColorScheme.light(
      primary: C.royal,
      onPrimary: Colors.white,
      secondary: C.crimson,
      onSecondary: Colors.white,
      surface: C.surface,
      onSurface: C.ink,
      error: C.rust,
      onError: Colors.white,
      outline: C.line,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: T.bodyFamily,
      bodyColor: C.ink,
      displayColor: C.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.plum800,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    dividerColor: C.line,
    dividerTheme: const DividerThemeData(color: C.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.royal, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.rust),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: C.rust),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
  );
}
