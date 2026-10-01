import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// The nine-stage member journey shown on the welcome screen.
const List<String> journeyStages = [
  'Discovery: recommended matches and your own search',
  'Interest: show interest without sharing contact details',
  'Mutual match: both of you agree to talk',
  'Talking stage: a private room for the two of you',
  'Indawo Ephakeme: spiritual consultation before dating',
  'Dating: entered together, after consultation',
  'Courtship: a serious, declared relationship',
  'Marriage preparation: guidance as you prepare',
  'Married: a family built within the Spiritual Home',
];

class JourneyList extends StatelessWidget {
  const JourneyList({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < journeyStages.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _numeral(i + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    journeyStages[i],
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: onDark ? Colors.white : C.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _numeral(int n) {
    final stage5 = n == 5;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: stage5 ? C.crimson : (onDark ? C.plum700 : C.plum100),
        border: stage5 ? Border.all(color: C.crimson100, width: 2) : null,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: TextStyle(
          fontFamily: T.headingFamily,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: stage5 ? Colors.white : (onDark ? Colors.white : C.plum700),
        ),
      ),
    );
  }
}
