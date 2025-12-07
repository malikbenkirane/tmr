import 'package:test/test.dart';
import 'package:too_many_tabs/utils/format_duration.dart';

void main() {
  group('Test formatSpentDuration', () {
    for (final (duration, expected) in <(Duration, String)>[
      (Duration(), "00:00:00.00"),
      (Duration(minutes: 1), "00:01:00.00"),
      (Duration(hours: 1), "01:00:00.00"),
      (Duration(seconds: 1), "00:00:01.00"),
      (Duration(milliseconds: 1), "00:00:00.00"),
      (Duration(milliseconds: 100), "00:00:00.10"),
      (Duration(milliseconds: 10), "00:00:00.01"),
      (
        Duration(minutes: 8, hours: 6, seconds: 1, milliseconds: 780),
        "06:08:01.78",
      ),
    ]) {
      test('Expected $duration format "$expected"', () {
        expect(formatSpentDuration(duration), expected);
      });
    }
  });
}
