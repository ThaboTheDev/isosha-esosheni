import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';

/// Label + hint + error around any field, per the AppInput spec.
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    this.label,
    this.hint,
    this.error,
    required this.child,
  });

  final String? label;
  final String? hint;
  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontFamily: T.bodyFamily,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: C.ink,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Focus(
          child: child,
          onFocusChange: (_) {},
        ),
        if (hint != null && error == null) ...[
          const SizedBox(height: 5),
          Text(hint!, style: T.small.copyWith(fontSize: 13)),
        ],
        if (error != null) ...[
          const SizedBox(height: 5),
          Text(
            error!,
            style: const TextStyle(
              fontFamily: T.bodyFamily,
              fontSize: 13,
              color: C.rust,
            ),
          ),
        ],
      ],
    );
  }
}

/// Pill chip used by TagInput.
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.plum100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: T.bodyFamily,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: C.plum700,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: C.plum700),
            ),
          ],
        ],
      ),
    );
  }
}

/// Type + Enter/comma to add; x removes. Max 20 tags of 40 chars.
class TagInput extends StatefulWidget {
  const TagInput({
    super.key,
    required this.tags,
    required this.onChanged,
    this.placeholder = 'Type and press Enter',
    this.maxTags = 20,
    this.maxLength = 40,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String placeholder;
  final int maxTags;
  final int maxLength;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final _ctl = TextEditingController();

  void _add(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return;
    if (v.length > widget.maxLength) return;
    if (widget.tags.length >= widget.maxTags) return;
    if (widget.tags.contains(v)) {
      _ctl.clear();
      return;
    }
    widget.onChanged([...widget.tags, v]);
    _ctl.clear();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.tags.isNotEmpty)
          Wrap(
            children: [
              for (final t in widget.tags)
                TagChip(t,
                    onRemove: () => widget
                        .onChanged(widget.tags.where((e) => e != t).toList())),
            ],
          ),
        TextField(
          controller: _ctl,
          decoration: InputDecoration(hintText: widget.placeholder),
          maxLength: widget.maxLength,
          onSubmitted: _add,
          onChanged: (v) {
            if (v.endsWith(',')) {
              _add(v.substring(0, v.length - 1));
            }
          },
        ),
      ],
    );
  }
}
