import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/utils/contact_detection.dart';

void main() {
  test('phones', () {
    expect(ContactDetection.looksLikeContactDetails('Call me on 082 123 4567'),
        isTrue);
    expect(ContactDetection.looksLikeContactDetails('+27 82 123 4567'),
        isTrue);
    expect(ContactDetection.looksLikeContactDetails('0821234567'), isTrue);
    expect(
        ContactDetection.looksLikeContactDetails('Psalm 121 is my favourite'),
        isFalse);
  });

  test('emails', () {
    expect(
        ContactDetection.looksLikeContactDetails('mail me at a@b.co please'),
        isTrue);
  });

  test('social handles', () {
    expect(ContactDetection.looksLikeContactDetails('find me on WhatsApp'),
        isTrue);
    expect(ContactDetection.looksLikeContactDetails('my instagram is x'),
        isTrue);
    expect(ContactDetection.looksLikeContactDetails('I love feedback'),
        isFalse);
  });
}
