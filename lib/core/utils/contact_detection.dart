/// Contact-detail detection. Posts/comments/stories/live chat are refused
/// server-side; private chat shows a gentle warning before sending.
library;

class ContactDetection {
  ContactDetection._();

  static final phoneRe =
      RegExp(r'(?:\+?27|0)[\s-]?\d{2}[\s-]?\d{3}[\s-]?\d{4}\b');
  static final emailRe = RegExp(r'[^\s@]+@[^\s@]+\.[a-z]{2,}');
  static final handleRe = RegExp(
    r'\b(whatsapp|telegram|instagram|facebook|ig|fb)\b',
    caseSensitive: false,
  );

  static bool looksLikeContactDetails(String text) {
    return phoneRe.hasMatch(text) ||
        emailRe.hasMatch(text) ||
        handleRe.hasMatch(text);
  }

  static const warning =
      'It looks like you are sharing contact details. There is no rush; '
      'many members keep talking here until trust has grown.';
}
