import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// 88 px circular ring with the percent in Cormorant.
class CompletionMeter extends StatelessWidget {
  const CompletionMeter(this.percent, {super.key, this.size = 88});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(clamped / 100),
          ),
          Text(
            '$clamped%',
            style: TextStyle(
              fontFamily: T.headingFamily,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.27,
              color: C.plum700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    final track = Paint()
      ..color = C.track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 3.14159 * 2, false, track);
    if (progress > 0) {
      final bar = Paint()
        ..color = C.royal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -3.14159 / 2, 3.14159 * 2 * progress, false, bar);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
