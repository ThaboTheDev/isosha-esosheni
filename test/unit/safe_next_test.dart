import 'package:flutter_test/flutter_test.dart';
import 'package:isosha_esosheni/core/utils/safe_next.dart';

void main() {
  test('relative paths pass', () {
    expect(safeNext('/messages/c-1'), '/messages/c-1');
    expect(safeNext('/connections?tab=matches'), '/connections?tab=matches');
  });

  test('absolute or scheme-y values fall back', () {
    expect(safeNext('https://evil.example'), '/home');
    expect(safeNext('//evil.example'), '/home');
    expect(safeNext('/https://evil.example'), '/home');
    expect(safeNext(null), '/home');
    expect(safeNext('home'), '/home');
  });
}
