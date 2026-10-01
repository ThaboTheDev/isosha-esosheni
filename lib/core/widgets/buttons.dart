import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onPressed,
    this.gradient,
    this.background,
    this.foreground = Colors.white,
    this.border,
    this.busy = false,
    this.icon,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? background;
  final Color foreground;
  final Color? border;
  final bool busy;
  final IconData? icon;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || busy;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled && !busy ? null : gradient,
          color: gradient == null
              ? (background ?? C.surface)
              : (disabled && !busy ? background : null),
          border: border == null
              ? null
              : Border.all(color: border!),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: disabled ? null : onPressed,
            child: Opacity(
              opacity: onPressed == null ? 0.5 : 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (busy) ...[
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ] else if (icon != null) ...[
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      busy ? (busyLabel ?? 'Saving') : label,
                      style: T.bodyStrong.copyWith(color: foreground),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Teal gradient pill with white text.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) => _PillButton(
        label: label,
        onPressed: onPressed,
        gradient: C.primaryButton,
        background: C.royal,
        busy: busy,
        icon: icon,
        busyLabel: busyLabel,
      );
}

/// Bronze accent pill with white text.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) => _PillButton(
        label: label,
        onPressed: onPressed,
        gradient: C.accentButton,
        background: C.crimson,
        busy: busy,
        icon: icon,
        busyLabel: busyLabel,
      );
}

/// Surface fill, line border, deep-teal text.
class QuietButton extends StatelessWidget {
  const QuietButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) => _PillButton(
        label: label,
        onPressed: onPressed,
        background: C.surface,
        foreground: C.plum700,
        border: C.line,
        busy: busy,
        icon: icon,
        busyLabel: busyLabel,
      );
}

/// Rust destructive pill.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) => _PillButton(
        label: label,
        onPressed: onPressed,
        background: C.rust,
        busy: busy,
        busyLabel: busyLabel,
      );
}
