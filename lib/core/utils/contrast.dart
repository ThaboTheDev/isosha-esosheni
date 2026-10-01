import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// WCAG 2.1 contrast math, unit-tested for the palette pairs in use.
class Contrast {
  Contrast._();

  static double _lin(int v8) {
    final c = v8 / 255.0;
    return c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  static double relativeLuminance(Color c) {
    final r = _lin(c.red);
    final g = _lin(c.green);
    final b = _lin(c.blue);
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
