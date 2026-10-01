import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';
import 'buttons.dart';

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, this.label = 'Loading'});
  final String label;

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: C.royal),
          ),
        ),
      );
}

/// Skeleton rows for loading lists.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 96,
            decoration: BoxDecoration(
              color: C.surface,
              border: Border.all(color: C.line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: C.plum100),
              ),
            ),
          ),
      ],
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: C.muted, size: 30),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: T.body.copyWith(color: C.muted),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              QuietButton(label: 'Try again', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
