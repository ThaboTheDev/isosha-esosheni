import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Circle avatar with a plum-100 fallback showing the first initial in
/// Cormorant. Uses the storage path as cacheKey so rotated signed URLs
/// still hit the image cache.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.url,
    this.cacheKey,
    this.size = 44,
  });

  final String? name;
  final String? url;
  final String? cacheKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = ((name ?? 'M').trim().isNotEmpty
            ? (name ?? 'M').trim()[0]
            : 'M')
        .toUpperCase();
    Widget child;
    if (url != null && url!.startsWith('fake://')) {
      child = _fallback(initial);
    } else if (url != null && url!.isNotEmpty) {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: url!,
          cacheKey: cacheKey,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(initial),
          errorWidget: (_, __, ___) => _fallback(initial),
        ),
      );
    } else {
      child = _fallback(initial);
    }
    return SizedBox(width: size, height: size, child: child);
  }

  Widget _fallback(String initial) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: C.plum100,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: T.headingFamily,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.45,
            color: C.plum700,
          ),
        ),
      );
}

/// Rectangular member photo used by cards (4:3) and profiles (4:5).
class MemberImage extends StatelessWidget {
  const MemberImage({
    super.key,
    this.name,
    this.url,
    this.cacheKey,
    this.aspect = 4 / 3,
    this.radius = 12,
  });

  final String? name;
  final String? url;
  final String? cacheKey;
  final double aspect;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = ((name ?? 'M').trim().isNotEmpty
            ? (name ?? 'M').trim()[0]
            : 'M')
        .toUpperCase();
    final fallback = Container(
      color: C.plum100,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: T.headingFamily,
          fontWeight: FontWeight.w700,
          fontSize: 42,
          color: C.plum700,
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: (url != null && url!.isNotEmpty && !url!.startsWith('fake://'))
            ? CachedNetworkImage(
                imageUrl: url!,
                cacheKey: cacheKey,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}
