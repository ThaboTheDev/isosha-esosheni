import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/theme.dart';
import 'buttons.dart';

const Map<String, String> reportCategories = {
  'harassment': 'Harassment',
  'fraud': 'Fraud or scam',
  'fake_identity': 'Fake identity',
  'sexual_content': 'Inappropriate sexual content',
  'hate_speech': 'Hate speech',
  'threats': 'Threats',
  'abuse': 'Abuse',
  'spam': 'Spam',
  'manipulation': 'Manipulation',
  'false_information': 'False information',
  'unwanted_contact': 'Unwanted contact',
  'other': 'Something else',
};

/// Bottom sheet used for reporting members, content and conversations.
class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.onSubmit, this.title});

  /// Returns an error message, or null on success.
  final Future<String?> Function(String category, String details) onSubmit;
  final String? title;

  static Future<bool> show(
    BuildContext context, {
    required Future<String?> Function(String, String) onSubmit,
    String? title,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReportSheet(onSubmit: onSubmit, title: title),
    ).then((v) => v ?? false);
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String? _category;
  final _details = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _error = 'Choose a reason for this report.');
      return;
    }
    if (_details.text.length > 2000) {
      setState(() => _error = 'Details are limited to 2000 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.onSubmit(_category!, _details.text.trim());
    if (!mounted) return;
    if (err == null) {
      setState(() => _busy = false);
      if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Report received'),
        backgroundColor: C.sage,
      ));
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title ?? 'Report', style: T.headline),
          const SizedBox(height: 4),
          Text(
            'Reports are confidential. A member of the safety team will '
            'review this.',
            style: T.small,
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in reportCategories.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _category == e.key,
                      onSelected: (_) =>
                          setState(() => _category = e.key),
                      selectedColor: C.crimson100,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _details,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'Add details that will help the review (optional).',
            ),
          ),
          if (_error != null)
            Text(_error!,
                style: const TextStyle(color: C.rust, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              QuietButton(
                label: 'Cancel',
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(false);
                  }
                },
              ),
              const SizedBox(width: 8),
              DangerButton(
                label: 'Send report',
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
