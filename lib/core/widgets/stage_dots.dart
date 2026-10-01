import 'package:flutter/material.dart';

import '../../data/models/relationship.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';

/// Progress dots over the six relationship stages.
class StageDots extends StatelessWidget {
  const StageDots(this.currentStage, {super.key, this.ended = false});

  final String currentStage;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    final idx = stageOrder.indexOf(currentStage);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stageOrder.length; i++) ...[
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ended
                      ? C.line
                      : i <= idx
                          ? C.royal
                          : C.track,
                  border: i == idx && !ended
                      ? Border.all(color: C.crimson, width: 2)
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stageLabels[stageOrder[i]] ?? '',
                style: TextStyle(
                  fontSize: 9,
                  color: i <= idx && !ended ? C.plum700 : C.muted,
                ),
              ),
            ],
          ),
          if (i < stageOrder.length - 1)
            Container(
              width: 14,
              height: 2,
              margin: const EdgeInsets.only(bottom: 14),
              color: i < idx && !ended ? C.royal : C.line,
            ),
        ],
      ],
    );
  }
}
