import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2.1 contrast math, unit-tested for the palette pairs in use.
class Contrast {
  Contrast._();

  /// Linearizes one non-linear sRGB channel (0.0-1.0), per WCAG 2.1.
  static double _lin(double c) {
    return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static double relativeLuminance(Color c) {
    // `.r/.g/.b` are the double-valued sRGB channels (0.0-1.0); the older
    // `.red/.green/.blue` 8-bit getters are deprecated in Flutter 3.27+.
    final r = _lin(c.r);
    final g = _lin(c.g);
    final b = _lin(c.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double contrastRatio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  /// AA for normal text.
  static bool passesAA(Color fg, Color bg) => contrastRatio(fg, bg) >= 4.5;
}
