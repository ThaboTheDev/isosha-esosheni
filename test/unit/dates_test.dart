import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isosha_esosheni/core/utils/dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('SAST formatting', () {
    final nowUtc = DateTime.utc(2026, 10, 1, 12, 0, 0); // 14:00 SAST

    test('day labels', () {
      expect(Dates.dayLabel(nowUtc, nowUtc: nowUtc), 'Today');
      expect(
        Dates.dayLabel(nowUtc.subtract(const Duration(days: 1)),
            nowUtc: nowUtc),
        'Yesterday',
      );
      expect(
        Dates.dayLabel(DateTime.utc(2026, 9, 28, 10), nowUtc: nowUtc),
        'Monday, 28 September',
      );
    });

    test('timeAgo ladder', () {
      expect(
        Dates.timeAgo(nowUtc.subtract(const Duration(seconds: 10)),
            nowUtc: nowUtc),
        'just now',
      );
      expect(
        Dates.timeAgo(nowUtc.subtract(const Duration(minutes: 5)),
            nowUtc: nowUtc),
        '5 min ago',
      );
      expect(
        Dates.timeAgo(nowUtc.subtract(const Duration(hours: 3)),
            nowUtc: nowUtc),
        '3 h ago',
      );
      expect(
        Dates.timeAgo(nowUtc.subtract(const Duration(days: 2)),
            nowUtc: nowUtc),
        '2 d ago',
      );
      expect(
        Dates.timeAgo(nowUtc.subtract(const Duration(days: 30)),
            nowUtc: nowUtc),
        '1 Sep 2026',
      );
    });

    test('toSast shifts UTC+2', () {
      final sast = Dates.toSast(DateTime.utc(2026, 10, 1, 12, 0));
      expect(sast.hour, 14);
    });

    test('list stamp shows time today, short date otherwise', () {
      expect(Dates.listStamp(nowUtc, nowUtc: nowUtc), '14:00');
      expect(
        Dates.listStamp(DateTime.utc(2026, 9, 20, 9), nowUtc: nowUtc),
        '20 Sep',
      );
    });
  });
}
