import 'package:flutter/material.dart';

import '../../data/models/member.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import 'avatar.dart';
import 'badges.dart';
import 'buttons.dart';
import 'panel.dart';

/// How a card's action row should behave.
enum CardActionVariant { discover, received, sent, match, saved }

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.data,
    this.variant = CardActionVariant.discover,
    this.avatarUrl,
    this.onSendInterest,
    this.onLike,
    this.onSave,
    this.onPass,
    this.onAccept,
    this.onDecline,
    this.onView,
    this.onWithdraw,
    this.onOpenConversation,
    this.onEndMatch,
  });

  final MemberCardData data;
  final CardActionVariant variant;
  final String? avatarUrl;
  final VoidCallback? onSendInterest;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onPass;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onView;
  final VoidCallback? onWithdraw;
  final VoidCallback? onOpenConversation;
  final VoidCallback? onEndMatch;

  @override
  Widget build(BuildContext context) {
    final place = [
      if (data.age != null) '${data.age}',
      if ((data.city ?? '').isNotEmpty) data.city,
      if ((data.province ?? '').isNotEmpty) data.province,
    ].join(', ');
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              MemberImage(
                name: data.displayName,
                url: avatarUrl,
                cacheKey: data.avatarPath,
              ),
              Positioned(
                left: 8,
                top: 8,
                child: ScoreBadge(score: data.score),
              ),
              if ((data.relationshipStatus ?? 'single') != 'single')
                Positioned(
                  right: 8,
                  top: 8,
                  child: ChipSmall(maritalLabel(data.relationshipStatus),
                      tone: ChipTone.bronze),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.displayName,
            style: T.cardTitle.copyWith(fontSize: 26),
          ),
          if (place.isNotEmpty)
            Text(
              '$place${(data.profession ?? '').isNotEmpty ? '. ${data.profession}' : ''}',
              style: T.small,
            ),
          if (data.household != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.crimson100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Married, ${data.household!.wives} '
                '${data.household!.wives == 1 ? 'wife' : 'wives'}. '
                'This household is seeking an additional wife, with each '
                "wife's consent.",
                style: const TextStyle(fontSize: 13, color: C.crimson600),
              ),
            ),
          ],
          if (data.intentions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final i in data.intentions.take(3))
                  ChipSmall(intentionLabel(i)),
              ],
            ),
          ],
          if (data.reasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final r in data.reasons.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 15, color: C.sage),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(r,
                          style: T.small.copyWith(color: C.ink)),
                    ),
                  ],
                ),
              ),
          ],
          if ((data.bio ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data.bio!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: T.body.copyWith(fontSize: 14),
            ),
          ],
          if ((data.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '“${data.note}”',
              style: T.body.copyWith(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: C.muted,
              ),
            ),
          ],
          if (data.isDemo) ...[
            const SizedBox(height: 6),
            Text('Development demo profile',
                style: T.small.copyWith(fontSize: 11)),
          ],
          const SizedBox(height: 12),
          _actions(context),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final row = <Widget>[];
    switch (variant) {
      case CardActionVariant.discover:
        if (data.matched) {
          row.add(const ChipSmall('Matched', tone: ChipTone.sage));
        } else if (data.interestReceived != null) {
          row.add(QuietButton(
              label: 'Accept their interest', onPressed: onAccept));
        } else if (data.interestSent) {
          row.add(const ChipSmall('Interest sent', tone: ChipTone.bronze));
        } else {
          row.add(Expanded(
            child: GoldButton(label: 'Send interest', onPressed: onSendInterest),
          ));
        }
        row.add(const SizedBox(width: 8));
        row.add(_icon(
          data.liked ? Icons.favorite : Icons.favorite_border,
          data.liked ? C.crimson : C.muted,
          'Like',
          onLike,
        ));
        row.add(_icon(
          data.saved ? Icons.bookmark : Icons.bookmark_border,
          data.saved ? C.royal : C.muted,
          'Save',
          onSave,
        ));
        row.add(_icon(Icons.visibility_off_outlined, C.muted, 'Pass', onPass));
      case CardActionVariant.received:
        row.add(Expanded(
            child: PrimaryButton(label: 'Accept', onPressed: onAccept)));
        row.add(const SizedBox(width: 8));
        row.add(
            Expanded(child: QuietButton(label: 'Decline', onPressed: onDecline)));
        row.add(const SizedBox(width: 8));
        row.add(QuietButton(label: 'View profile', onPressed: onView));
      case CardActionVariant.sent:
        row.add(Expanded(child: QuietButton(label: 'View', onPressed: onView)));
        row.add(const SizedBox(width: 8));
        row.add(Expanded(
            child: QuietButton(label: 'Withdraw interest', onPressed: onWithdraw)));
      case CardActionVariant.match:
        row.add(Expanded(
            child: PrimaryButton(
                label: 'Open conversation', onPressed: onOpenConversation)));
        row.add(const SizedBox(width: 8));
        row.add(QuietButton(label: 'View profile', onPressed: onView));
        row.add(const SizedBox(width: 8));
        row.add(_icon(Icons.close, C.rust, 'End match', onEndMatch));
      case CardActionVariant.saved:
        row.add(Expanded(child: QuietButton(label: 'View', onPressed: onView)));
        row.add(const SizedBox(width: 8));
        row.add(_icon(
            Icons.bookmark_remove_outlined, C.muted, 'Remove from saved', onSave));
    }
    return Row(children: row);
  }

  Widget _icon(IconData icon, Color color, String label, VoidCallback? onTap) =>
      Semantics(
        label: label,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );
}

/// Placeholder photo block (the feature layer overlays signed URLs).
class MemberPhotoPlaceholder extends StatelessWidget {
  const MemberPhotoPlaceholder({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: C.plum100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: T.headingFamily,
            fontWeight: FontWeight.w700,
            fontSize: 44,
            color: C.plum700,
          ),
        ),
      ),
    );
  }
}
