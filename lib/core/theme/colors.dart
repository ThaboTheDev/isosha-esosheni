import 'package:flutter/painting.dart';

/// Mobile redesign palette: deep teal leads, bronze accents, brass hairline,
/// warm stone neutrals. These hex values are authoritative and replace the
/// web colours. Token names are kept for continuity with the web codebase.
abstract final class C {
  /// Primary teal ("royal").
  static const Color royal = Color(0xFF0F4C5C);

  /// Deep teal.
  static const Color plum700 = Color(0xFF0A3441);

  /// Ink teal (modal scrim base).
  static const Color plum800 = Color(0xFF06222B);

  /// Soft teal.
  static const Color plum500 = Color(0xFF3C7A89);

  /// Mist.
  static const Color plum100 = Color(0xFFE1EEF1);

  /// Subtle fills.
  static const Color plum50 = Color(0xFFF1F7F8);

  /// Bronze accent.
  static const Color crimson = Color(0xFF9A6B1E);

  /// Bronze deep.
  static const Color crimson600 = Color(0xFF7A5214);

  /// Bronze wash.
  static const Color crimson100 = Color(0xFFF6EBD6);

  /// Brass.
  static const Color gold = Color(0xFFC9A24B);

  /// Success.
  static const Color sage = Color(0xFF2F7A4B);
  static const Color sage100 = Color(0xFFDFF0E6);

  /// Error / destructive.
  static const Color rust = Color(0xFFA12B2B);
  static const Color rust100 = Color(0xFFF8E4E3);
  static const Color rust900 = Color(0xFF5E1414);

  /// Warm stone page background.
  static const Color canvas = Color(0xFFF7F5F0);

  /// Cards and inputs.
  static const Color surface = Color(0xFFFFFFFF);

  /// Borders / dividers.
  static const Color line = Color(0xFFE2DDD2);

  /// Body text.
  static const Color ink = Color(0xFF1D2A2E);

  /// Secondary text.
  static const Color muted = Color(0xFF5F6B6E);

  /// CompletionMeter track.
  static const Color track = Color(0xFFE4ECEE);

  /// Story background render colours (keys sent to the backend unchanged).
  static const Color storyRoyal = Color(0xFF0F4C5C);
  static const Color storyCrimson = Color(0xFF9A6B1E);
  static const Color storyGold = Color(0xFF7C6A2A);
  static const Color storyNight = Color(0xFF1D2A2E);

  // Gradients (subtle).
  static const Gradient brandHeader = LinearGradient(
    begin: Alignment(-0.9, -0.4),
    end: Alignment(0.9, 0.4), // ~105deg
    colors: [plum800, royal],
  );

  static const Gradient brandBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [crimson, gold, crimson],
  );

  static const Gradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight, // ~120deg
    colors: [royal, plum700],
  );

  static const Gradient accentButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [crimson, crimson600],
  );

  static const Gradient liveBar = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [crimson600, crimson, crimson600],
  );

  static const Gradient toneCelebration = LinearGradient(
    colors: [crimson, plum700],
  );
  static const Gradient toneNotice = LinearGradient(colors: [royal, plum700]);
  static const Gradient toneUrgent = LinearGradient(
    colors: [rust, rust900],
  );

  /// Soft neutral shadow for panels.
  static List<BoxShadow> panelShadow() => const [
        BoxShadow(color: Color(0x0F0A3441), blurRadius: 24, offset: Offset(0, 8), spreadRadius: -14),
        BoxShadow(color: Color(0x0F0A3441), blurRadius: 8, offset: Offset(0, 2)),
      ];

  static Color storyColor(String key) {
    switch (key) {
      case 'royal':
        return storyRoyal;
      case 'crimson':
        return storyCrimson;
      case 'gold':
        return storyGold;
      default:
        return storyNight;
    }
  }

  /// Soft elevation for panels: ink at low alpha (calm, no drop-shadow grey).
  static List<BoxShadow> panelShadow() => [
        BoxShadow(
          color: ink.withOpacity(0.08),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];
}
