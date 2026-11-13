import 'package:nepal_kit/nepal_kit.dart';
import 'package:nepal_kit/src/date/bs_calendar_data.dart';
import 'package:test/test.dart';

import 'fixtures/ahargana.dart';

void main() {
  group('table', () {
    test('covers BS 1970-2100, 12 months each, 29-32 days a month', () {
      expect(bsMonthDays, hasLength(2100 - 1970 + 1));
      for (var i = 0; i < bsMonthDays.length; i++) {
        expect(bsMonthDays[i], hasLength(12), reason: '${1970 + i}');
        for (final d in bsMonthDays[i]) {
          expect(d, inInclusiveRange(29, 32), reason: '${1970 + i}');
        }
        expect(BsDate.daysInYearOf(1970 + i), inInclusiveRange(365, 366));
      }
    });

    test('every year length matches the astrology Calendar table '
        '(an independent ahargana count)', () {
      for (var y = 1970; y <= 2100; y++) {
        expect(
          BsDate.daysInYearOf(y),
          aharganaOfBaishakh1[y + 1]! - aharganaOfBaishakh1[y]!,
          reason: 'BS $y',
        );
      }
    });
  });

  group('known dates', () {
    // (BS, AD, what)
    const known = [
      ((1970, 1, 1), (1913, 4, 13), 'table epoch'),
      ((2000, 1, 1), (1943, 4, 14), "Tipot's epoch, a Wednesday"),
      ((2007, 11, 7), (1951, 2, 18), 'Democracy Day 2007'),
      ((2063, 1, 11), (2006, 4, 24), 'Loktantra Day 2063'),
      ((2065, 2, 15), (2008, 5, 28), 'Republic Day 2065'),
      ((2072, 6, 3), (2015, 9, 20), 'Constitution Day 2072'),
      ((2080, 1, 1), (2023, 4, 14), 'New Year 2080'),
      ((2081, 1, 1), (2024, 4, 13), 'New Year 2081'),
      ((2082, 1, 1), (2025, 4, 14), 'New Year 2082'),
      ((2083, 1, 1), (2026, 4, 14), 'New Year 2083'),
    ];
    for (final ((by, bm, bd), (ay, am, ad), what) in known) {
      test('$what: $by-$bm-$bd BS = $ay-$am-$ad AD', () {
        expect(BsDate(by, bm, bd).toAd(), DateTime.utc(ay, am, ad));
        expect(BsDate.fromAd(DateTime(ay, am, ad)), BsDate(by, bm, bd));
        expect(BsDate.fromAd(DateTime.utc(ay, am, ad)), BsDate(by, bm, bd));
      });
    }

    test('weekdays', () {
      expect(BsDate(2000, 1, 1).weekday, DateTime.wednesday);
      expect(BsDate(2081, 1, 1).weekday, DateTime.saturday);
      expect(BsDate(2082, 1, 1).weekday, DateTime.monday);
    });
  });

  test('every day of the table round-trips and runs on without gaps', () {
    var d = BsDate.min;
    var ad = BsDate.minAd;
    var n = 0;
    while (true) {
      expect(d.toAd(), ad, reason: '$d');
      expect(BsDate.fromAd(ad), d, reason: '$ad');
      expect(d.dayNumber, n);
      if (d == BsDate.max) break;
      final next = d.addDays(1);
      final ok =
          (next.year == d.year &&
              next.month == d.month &&
              next.day == d.day + 1) ||
          (next.year == d.year &&
              next.month == d.month + 1 &&
              next.day == 1 &&
              d.day == d.daysInMonth) ||
          (next.year == d.year + 1 &&
              next.month == 1 &&
              next.day == 1 &&
              d.month == 12);
      expect(ok, isTrue, reason: '$d -> $next');
      d = next;
      ad = ad.add(const Duration(days: 1));
      n++;
    }
    expect(BsDate.maxAd, ad);
    expect(n, greaterThan(47800));
  });

  group('range and validation', () {
    test('rejects dates that do not exist', () {
      expect(() => BsDate(1969, 12, 30), throwsRangeError);
      expect(() => BsDate(2101, 1, 1), throwsRangeError);
      expect(() => BsDate(2081, 13, 1), throwsRangeError);
      expect(() => BsDate(2081, 1, 0), throwsRangeError);
      expect(
        () => BsDate(2081, 1, 32),
        throwsRangeError,
      ); // Baishakh 2081 has 31
      expect(BsDate(2081, 2, 32).day, 32); // Jestha 2081 has 32
      expect(BsDate.isValid(2081, 1, 31), isTrue);
      expect(BsDate.isValid(2081, 1, 32), isFalse);
    });

    test('AD outside the table throws', () {
      expect(() => BsDate.fromAd(DateTime(1913, 4, 12)), throwsRangeError);
      expect(
        () => BsDate.fromAd(BsDate.maxAd.add(const Duration(days: 1))),
        throwsRangeError,
      );
      expect(BsDate.fromAd(BsDate.maxAd), BsDate.max);
    });
  });

  group('time zones', () {
    test('fromAd reads calendar fields only', () {
      // 23:30 local and 00:10 UTC are both just "that day".
      expect(BsDate.fromAd(DateTime(2024, 4, 13, 23, 30)), BsDate(2081, 1, 1));
      expect(
        BsDate.fromAd(DateTime.utc(2024, 4, 13, 0, 10)),
        BsDate(2081, 1, 1),
      );
    });

    test('today is Nepal time whatever the device zone', () {
      // 18:20 UTC on 12 April is 00:05 on 13 April in Nepal.
      expect(
        BsDate.today(now: DateTime.utc(2024, 4, 12, 18, 20)),
        BsDate(2081, 1, 1),
      );
      expect(
        BsDate.today(now: DateTime.utc(2024, 4, 12, 18, 10)),
        BsDate(2080, 12, 30),
      ); // Chaitra 2080 has 30 days
    });

    test('toAdLocal is local midnight of the same day', () {
      final l = BsDate(2081, 1, 1).toAdLocal();
      expect(
        [l.isUtc, l.year, l.month, l.day, l.hour],
        [false, 2024, 4, 13, 0],
      );
    });
  });

  group('arithmetic', () {
    test('addDays across months and years', () {
      expect(BsDate(2080, 12, 30).addDays(1), BsDate(2081, 1, 1));
      expect(BsDate(2081, 1, 1).addDays(-1), BsDate(2080, 12, 30));
      expect(BsDate(2081, 1, 1).addDays(366), BsDate(2082, 1, 1));
    });

    test('addMonths clamps to the month end', () {
      expect(BsDate(2081, 2, 32).addMonths(1), BsDate(2081, 3, 31));
      expect(BsDate(2081, 12, 15).addMonths(1), BsDate(2082, 1, 15));
      expect(BsDate(2081, 1, 15).addMonths(-1), BsDate(2080, 12, 15));
      expect(BsDate(2081, 1, 15).addYears(2), BsDate(2083, 1, 15));
    });

    test('difference, comparison and month ends', () {
      expect(BsDate(2082, 1, 1).difference(BsDate(2081, 1, 1)), 366);
      expect(BsDate(2081, 1, 1).isBefore(BsDate(2081, 1, 2)), isTrue);
      expect(BsDate(2081, 2, 5).lastOfMonth, BsDate(2081, 2, 32));
      expect(BsDate(2081, 2, 5).firstOfMonth, BsDate(2081, 2, 1));
      final sorted = [
        BsDate(2081, 2, 1),
        BsDate(2080, 5, 5),
        BsDate(2081, 1, 9),
      ]..sort();
      expect(sorted.first, BsDate(2080, 5, 5));
    });
  });

  group('parse', () {
    test('Latin and Devanagari, separators', () {
      expect(BsDate.parse('2081-01-15'), BsDate(2081, 1, 15));
      expect(BsDate.parse('2081/1/5'), BsDate(2081, 1, 5));
      expect(BsDate.parse('२०८१-०२-३२'), BsDate(2081, 2, 32));
      expect(BsDate(2081, 1, 5).toString(), '2081-01-05');
    });

    test('bad input', () {
      expect(BsDate.tryParse('2081-01-32'), isNull);
      expect(BsDate.tryParse('hello'), isNull);
      expect(() => BsDate.parse('81-1-1'), throwsFormatException);
    });
  });

  test('top-level helpers', () {
    expect(adToBs(DateTime(2025, 4, 14)), BsDate(2082, 1, 1));
    expect(bsToAd(2082, 1, 1), DateTime.utc(2025, 4, 14));
  });
}
