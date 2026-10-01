import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/theme/colors.dart';
import 'package:isosha_esosheni/core/utils/contrast.dart';

void main() {
  const white = Color(0xFFFFFFFF);

  test('WCAG AA for every white-on-brand pair', () {
    expect(Contrast.passesAA(white, C.royal), isTrue);
    expect(Contrast.passesAA(white, C.plum700), isTrue);
    expect(Contrast.passesAA(white, C.crimson), isTrue);
    expect(Contrast.passesAA(white, C.crimson600), isTrue);
    expect(Contrast.passesAA(white, C.rust), isTrue);
    expect(Contrast.passesAA(white, C.sage), isTrue);
    expect(Contrast.passesAA(white, C.plum800), isTrue);
  });

  test('muted on canvas meets 4.5:1', () {
    expect(Contrast.passesAA(C.muted, C.canvas), isTrue);
  });

  test('ink on canvas and surface', () {
    expect(Contrast.passesAA(C.ink, C.canvas), isTrue);
    expect(Contrast.passesAA(C.ink, C.surface), isTrue);
  });

  test('bronze text on bronze wash', () {
    expect(Contrast.passesAA(C.crimson600, C.crimson100), isTrue);
  });

  test('teal text on mist', () {
    expect(Contrast.passesAA(C.plum700, C.plum100), isTrue);
  });
}
