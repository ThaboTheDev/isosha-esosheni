import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// "N% compatible" pill, or the neutral not-enough-information pill.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: C.canvas,
          border: Border.all(color: C.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Not enough information to score',
          style: T.small.copyWith(fontSize: 12),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: C.crimson100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$score% compatible',
        style: const TextStyle(
          fontFamily: T.bodyFamily,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: C.crimson600,
        ),
      ),
    );
  }
}

class ChipSmall extends StatelessWidget {
  const ChipSmall(this.label, {super.key, this.tone});

  final String label;
  final ChipTone? tone;

  @override
  Widget build(BuildContext context) {
    final bg = tone == ChipTone.sage
        ? C.sage100
        : tone == ChipTone.bronze
            ? C.crimson100
            : tone == ChipTone.rust
                ? C.rust100
                : C.plum100;
    final fg = tone == ChipTone.sage
        ? C.sage
        : tone == ChipTone.bronze
            ? C.crimson600
            : tone == ChipTone.rust
                ? C.rust
                : C.plum700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: T.bodyFamily,
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: fg,
        ),
      ),
    );
  }
}

enum ChipTone { neutral, sage, bronze, rust }

/// Relationship intention labels (web wording).
const Map<String, String> intentionLabels = {
  'friendship': 'Friendship',
  'serious_relationship': 'Serious relationship',
  'courtship': 'Courtship',
  'marriage': 'Marriage',
  'future_marriage': 'Marriage in future',
  'traditional_family': 'Traditional family relationship',
  'monogamous_marriage': 'Monogamous marriage',
  'open_to_polygamous_marriage': 'Open to polygamous marriage',
};

String intentionLabel(String key) => intentionLabels[key] ?? key;

const Map<String, String> maritalLabels = {
  'single': 'Single',
  'separated': 'Separated',
  'divorced': 'Divorced',
  'widowed': 'Widowed',
  'dating': 'Dating',
  'courtship': 'Courtship',
  'marriage_preparation': 'Marriage preparation',
  'married': 'Married',
};

String maritalLabel(String? key) =>
    key == null ? '' : (maritalLabels[key] ?? key);
