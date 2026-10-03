import 'package:flutter/material.dart';

import '../../data/models/member.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// Discovery gate notices with the exact web wording.
class GateNotice extends StatelessWidget {
  const GateNotice({super.key, required this.gate, this.onSeeMissing});

  final Gate gate;
  final VoidCallback? onSeeMissing;

  @override
  Widget build(BuildContext context) {
    String? text;
    var bronze = false;
    Widget? link;
    switch (gate.reason) {
      case 'stage':
        text = 'Discovery is for members who are not married or preparing '
            'for marriage. Your status is ${gate.status ?? 'married'}. '
            'Additional-marriage matching is a separate, governed process '
            'that will open later.';
      case 'inactive':
        text = 'Your account is not active, so discovery is closed. Contact '
            'a membership administrator for help.';
      default:
        if (gate.visibleToOthers == false) {
          bronze = true;
          text = 'Your profile is ${gate.completion ?? 0}% complete. Other '
              'members see you once it reaches ${gate.minCompletion ?? 60}%.';
          if (onSeeMissing != null) {
            link = TextButton(
              onPressed: onSeeMissing,
              child: Text('See what is missing',
                  style: T.bodyStrong.copyWith(color: C.crimson600)),
            );
          }
        }
    }
    if (text == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bronze ? C.crimson100 : C.plum100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: bronze ? C.crimson600 : C.plum700,
            ),
          ),
          if (link != null) link,
        ],
      ),
    );
  }
}

/// Bronze panel used for the Indawo Ephakeme highlight.
class BronzeInfoPanel extends StatelessWidget {
  const BronzeInfoPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.crimson100,
          border: Border.all(color: C.crimson.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, height: 1.5, color: C.crimson600),
          child: child,
        ),
      );
}
