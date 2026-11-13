import '../number/digits.dart';
import 'bs_calendar_data.dart';

/// A day in the Bikram Sambat (BS, विक्रम संवत्) calendar.
///
/// BS month lengths follow the sky, not a formula, so conversion walks a
/// table of month lengths ([bsMonthDays], BS [minYear]..[maxYear]) counted
/// from the epoch **1 Baishakh 1970 BS = 13 April 1913 AD**.
///
/// A `BsDate` is a calendar day with no time and no time zone. Conversion
/// reads and returns *calendar fields* only: [BsDate.fromAd] uses the
/// `year`/`month`/`day` of the [DateTime] you pass (local or UTC, as given)
/// and never converts it to another zone, and [toAd] returns UTC midnight.
/// That avoids the off-by-one results that day counting across a local
/// time zone (Nepal is +05:45) gives.
class BsDate implements Comparable<BsDate> {
  /// The BS date [year]-[month]-[day]. [month] is 1 (Baishakh) .. 12
  /// (Chaitra).
  ///
  /// Throws [RangeError] when the date is outside [minYear]..[maxYear] or
  /// is not a day of that month.
  factory BsDate(int year, int month, int day) {
    _check(year, month, day);
    return BsDate._(year, month, day);
  }

  const BsDate._(this.year, this.month, this.day);

  /// The BS date of the AD calendar day [ad] (its `year`, `month` and
  /// `day` fields; the time and zone are ignored).
  ///
  /// Throws [RangeError] outside [minAd]..[maxAd].
  factory BsDate.fromAd(DateTime ad) =>
      BsDate.fromDayNumber(_dayNumberOfAd(ad.year, ad.month, ad.day));

  /// The BS date [days] days after 1 Baishakh [minYear] (day number 0).
  factory BsDate.fromDayNumber(int days) {
    if (days < 0 || days > _lastDayNumber) {
      throw RangeError.range(
        days,
        0,
        _lastDayNumber,
        'days',
        'BS date outside $minYear-$maxYear',
      );
    }
    final year = _yearOfDayNumber(days);
    var rest = days - _yearStart[year - minYear];
    final months = bsMonthDays[year - minYear];
    var month = 0;
    while (rest >= months[month]) {
      rest -= months[month];
      month++;
    }
    return BsDate._(year, month + 1, rest + 1);
  }

  /// Today in Nepal (UTC+05:45), whatever the device's zone. Pass [now] to
  /// use a fixed instant.
  factory BsDate.today({DateTime? now}) {
    final npt = (now ?? DateTime.now()).toUtc().add(
      const Duration(hours: 5, minutes: 45),
    );
    return BsDate.fromAd(npt);
  }

  /// Parses `2081-01-15`, `2081/1/15` or `२०८१-०१-१५`.
  ///
  /// Throws [FormatException] for other text and [RangeError] for a date
  /// that does not exist.
  factory BsDate.parse(String text) {
    final d = tryParseFields(text);
    if (d == null) throw FormatException('Not a BS date (yyyy-mm-dd)', text);
    return BsDate(d.$1, d.$2, d.$3);
  }

  /// Like [BsDate.parse], but returns null instead of throwing.
  static BsDate? tryParse(String text) {
    final d = tryParseFields(text);
    if (d == null || !isValid(d.$1, d.$2, d.$3)) return null;
    return BsDate._(d.$1, d.$2, d.$3);
  }

  /// The year, month and day fields of `yyyy-mm-dd` text, unvalidated.
  static (int, int, int)? tryParseFields(String text) {
    final m = RegExp(
      r'^\s*(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\s*$',
    ).firstMatch(toLatinDigits(text));
    if (m == null) return null;
    return (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  /// First BS year supported.
  static const int minYear = bsFirstYear;

  /// Last BS year supported.
  static const int maxYear = bsLastYear;

  /// 1 Baishakh [minYear].
  static const BsDate min = BsDate._(minYear, 1, 1);

  /// Last day of Chaitra [maxYear].
  static final BsDate max = BsDate._(maxYear, 12, bsMonthDays.last[11]);

  /// AD date of [min], UTC midnight.
  static final DateTime minAd = DateTime.utc(1913, 4, 13);

  /// AD date of [max], UTC midnight.
  static final DateTime maxAd = minAd.add(Duration(days: _lastDayNumber));

  /// BS year.
  final int year;

  /// BS month, 1 (Baishakh) .. 12 (Chaitra).
  final int month;

  /// Day of the month, from 1.
  final int day;

  /// Whether [year]-[month]-[day] is a BS date in the supported range.
  static bool isValid(int year, int month, int day) =>
      year >= minYear &&
      year <= maxYear &&
      month >= 1 &&
      month <= 12 &&
      day >= 1 &&
      day <= bsMonthDays[year - minYear][month - 1];

  /// Days in BS [month] of [year].
  static int daysInMonthOf(int year, int month) {
    RangeError.checkValueInInterval(year, minYear, maxYear, 'year');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    return bsMonthDays[year - minYear][month - 1];
  }

  /// Days in BS [year] (365 or 366, occasionally 364 or 367 in old tables).
  static int daysInYearOf(int year) {
    RangeError.checkValueInInterval(year, minYear, maxYear, 'year');
    return bsMonthDays[year - minYear].fold(0, (a, b) => a + b);
  }

  /// Days in this date's month.
  int get daysInMonth => bsMonthDays[year - minYear][month - 1];

  /// Days since 1 Baishakh [minYear].
  int get dayNumber {
    var n = _yearStart[year - minYear];
    final months = bsMonthDays[year - minYear];
    for (var i = 0; i < month - 1; i++) {
      n += months[i];
    }
    return n + day - 1;
  }

  /// The AD date, as UTC midnight.
  DateTime toAd() => minAd.add(Duration(days: dayNumber));

  /// The AD date, as local midnight (for APIs that want a local
  /// [DateTime], such as most date pickers).
  DateTime toAdLocal() {
    final u = toAd();
    return DateTime(u.year, u.month, u.day);
  }

  /// Weekday with [DateTime]'s numbering: 1 = Monday (सोमबार) .. 7 =
  /// Sunday (आइतबार).
  int get weekday => toAd().weekday;

  /// The date [days] days later (earlier when negative).
  BsDate addDays(int days) => BsDate.fromDayNumber(dayNumber + days);

  /// The same day [months] months later, clamped to the last day of a
  /// shorter month (32 Asar + 1 month = 31 Shrawan when Shrawan has 31).
  BsDate addMonths(int months) {
    final total = year * 12 + (month - 1) + months;
    final y = total ~/ 12, m = total % 12 + 1;
    RangeError.checkValueInInterval(y, minYear, maxYear, 'year');
    final last = bsMonthDays[y - minYear][m - 1];
    return BsDate._(y, m, day > last ? last : day);
  }

  /// The same day [years] years later, clamped like [addMonths].
  BsDate addYears(int years) => addMonths(years * 12);

  /// 1st of this month.
  BsDate get firstOfMonth => BsDate._(year, month, 1);

  /// Last day of this month.
  BsDate get lastOfMonth => BsDate._(year, month, daysInMonth);

  /// Whole days from [other] to this date (positive when this is later).
  int difference(BsDate other) => dayNumber - other.dayNumber;

  /// Whether this date is before [other].
  bool isBefore(BsDate other) => compareTo(other) < 0;

  /// Whether this date is after [other].
  bool isAfter(BsDate other) => compareTo(other) > 0;

  @override
  int compareTo(BsDate other) => year != other.year
      ? year - other.year
      : month != other.month
      ? month - other.month
      : day - other.day;

  @override
  bool operator ==(Object other) =>
      other is BsDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// `2081-01-05`.
  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static void _check(int year, int month, int day) {
    RangeError.checkValueInInterval(year, minYear, maxYear, 'year');
    RangeError.checkValueInInterval(month, 1, 12, 'month');
    RangeError.checkValueInInterval(
      day,
      1,
      bsMonthDays[year - minYear][month - 1],
      'day',
    );
  }

  /// Day number of 1 Baishakh of each year, index 0 = [minYear], plus one
  /// past the end.
  static final List<int> _yearStart = () {
    final out = <int>[0];
    for (final months in bsMonthDays) {
      out.add(out.last + months.fold(0, (a, b) => a + b));
    }
    return out;
  }();

  static final int _lastDayNumber = _yearStart.last - 1;

  static int _yearOfDayNumber(int days) {
    var lo = 0, hi = bsMonthDays.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_yearStart[mid] <= days) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return minYear + lo;
  }

  static int _dayNumberOfAd(int y, int m, int d) {
    final days = DateTime.utc(y, m, d).difference(minAd).inDays;
    if (days < 0 || days > _lastDayNumber) {
      throw RangeError(
        'AD $y-$m-$d is outside the BS table '
        '(${minAd.toIso8601String().substring(0, 10)} .. '
        '${maxAd.toIso8601String().substring(0, 10)})',
      );
    }
    return days;
  }
}

/// Converts the AD calendar day [ad] to BS. See [BsDate.fromAd].
BsDate adToBs(DateTime ad) => BsDate.fromAd(ad);

/// Converts a BS date to the AD calendar day, UTC midnight.
DateTime bsToAd(int year, int month, int day) =>
    BsDate(year, month, day).toAd();
