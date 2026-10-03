import 'package:flutter/material.dart';

import '../../core/utils/dates.dart';
import '../theme/colors.dart';

/// A single chat bubble. Mine = royal fill with white text and a squared
/// bottom-right; theirs = surface with a line border. System messages are
/// centred in plum-100. Deleted messages get a dashed border.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.createdAt,
    required this.mine,
    this.kind = 'text',
    this.body,
    this.deleted = false,
    this.isLast = false,
    this.read = false,
    this.reactions = const {},
    this.onLongPress,
    this.child,
  });

  final String createdAt;
  final bool mine;
  final String kind;
  final String? body;
  final bool deleted;
  final bool isLast;
  final bool read;
  final Map<String, List<String>> reactions;
  final VoidCallback? onLongPress;

  /// Media payload (image/voice/video) rendered by the feature layer.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (kind == 'system' && !deleted) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: C.plum100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            body ?? '',
            style: const TextStyle(fontSize: 12.5, color: C.plum700),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? C.royal : C.surface,
            border: deleted
                ? Border.all(color: C.muted, style: BorderStyle.solid)
                : (mine ? null : Border.all(color: C.line)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(mine ? 14 : 4),
              bottomRight: Radius.circular(mine ? 4 : 14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (deleted)
                Text(
                  'Message deleted',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: mine ? Colors.white70 : C.muted,
                  ),
                )
              else if (kind == 'text')
                Text(
                  body ?? '',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: mine ? Colors.white : C.ink,
                  ),
                )
              else if (child != null)
                child!
              else
                Text(
                  body ?? '',
                  style: TextStyle(
                    fontSize: 14.5,
                    color: mine ? Colors.white : C.ink,
                  ),
                ),
              if (reactions.isNotEmpty && !deleted)
                Wrap(
                  spacing: 4,
                  children: [
                    for (final e in reactions.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: mine
                              ? Colors.white.withValues(alpha: 0.15)
                              : C.plum50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${e.key} ${e.value.length}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              Text(
                Dates.fmtTime(DateTime.parse(createdAt)),
                style: TextStyle(
                  fontSize: 10,
                  color: mine ? Colors.white70 : C.muted,
                ),
              ),
              if (mine && !deleted)
                Text(
                  read ? 'Read' : 'Sent',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
