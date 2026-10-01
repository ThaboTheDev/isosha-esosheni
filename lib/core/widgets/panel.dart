import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// The standard card: 14 px radius, hairline border, surface fill.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        border: Border.all(color: C.line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: C.panelShadow(),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.onDark = false});
  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: onDark ? T.eyebrowOnDark : T.eyebrow,
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.favorite_outline,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 30, color: C.plum500),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: T.body.copyWith(color: C.muted),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!,
                    style: T.bodyStrong.copyWith(color: C.royal)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BrandBar extends StatelessWidget {
  const BrandBar({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 2,
        decoration: const BoxDecoration(gradient: C.brandBar),
      );
}
