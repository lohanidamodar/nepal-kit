import '../l10n/strings.dart';
import '../number/digits.dart';
import 'bs_date.dart';

/// Formats BS and AD dates in Nepali or English with a small pattern
/// language:
///
/// | Pattern | Meaning                      | Example (en / ne)        |
/// |---------|------------------------------|--------------------------|
/// | `yyyy`  | year                         | 2081 / २०८१              |
/// | `yy`    | two-digit year               | 81 / ८१                  |
/// | `MMMM`  | month name                   | Baishakh / बैशाख          |
/// | `MMM`   | short month name             | Bai / बै                  |
/// | `MM`    | two-digit month              | 01 / ०१                  |
/// | `M`     | month                        | 1 / १                    |
/// | `dd`    | two-digit day                | 05 / ०५                  |
/// | `d`     | day                          | 5 / ५                    |
/// | `EEEE`  | weekday                      | Saturday / शनिबार         |
/// | `EEE`   | short weekday                | Sat / शनि                 |
/// | `G`     | era                          | BS / वि.सं.               |
/// | `'..'`  | literal text (`''` is a `'`) |                          |
///
/// Digits are Devanagari when the language is Nepali, unless
/// [devanagariDigits] says otherwise.
class NepaliDateFormat {
  /// A format for [pattern] in [language].
  NepaliDateFormat(
    this.pattern, {
    this.language = NepalKitLanguage.en,
    bool? devanagariDigits,
  }) : devanagariDigits = devanagariDigits ?? language == NepalKitLanguage.ne,
       _tokens = _tokenize(pattern);

  /// `2081-01-05`.
  factory NepaliDateFormat.iso() =>
      NepaliDateFormat('yyyy-MM-dd', devanagariDigits: false);

  /// `5 Baishakh 2081` / `५ बैशाख २०८१`.
  factory NepaliDateFormat.long([
    NepalKitLanguage language = NepalKitLanguage.en,
  ]) => NepaliDateFormat('d MMMM yyyy', language: language);

  /// `Saturday, 5 Baishakh 2081` / `शनिबार, ५ बैशाख २०८१`.
  factory NepaliDateFormat.full([
    NepalKitLanguage language = NepalKitLanguage.en,
  ]) => NepaliDateFormat('EEEE, d MMMM yyyy', language: language);

  /// `2081/01/05` / `२०८१/०१/०५`, the form printed on Nepali bills.
  factory NepaliDateFormat.numeric([
    NepalKitLanguage language = NepalKitLanguage.en,
  ]) => NepaliDateFormat('yyyy/MM/dd', language: language);

  /// The pattern.
  final String pattern;

  /// Language of names.
  final NepalKitLanguage language;

  /// Whether digits are written in Devanagari.
  final bool devanagariDigits;

  final List<_Token> _tokens;

  /// Formats a BS date.
  String formatBs(BsDate date) =>
      _format(date.year, date.month, date.day, date.weekday, bs: true);

  /// Formats the AD calendar day of [date] (its fields as given; no zone
  /// conversion) with AD month names.
  String formatAd(DateTime date) =>
      _format(date.year, date.month, date.day, date.weekday, bs: false);

  /// Formats the BS date of the AD calendar day [date].
  String formatAdAsBs(DateTime date) => formatBs(BsDate.fromAd(date));

  String _format(int y, int m, int d, int weekday, {required bool bs}) {
    final s = NepalKitStrings.of(language);
    String n(int v, [int width = 1]) {
      final t = v.toString().padLeft(width, '0');
      return devanagariDigits ? toDevanagariDigits(t) : t;
    }

    final b = StringBuffer();
    for (final t in _tokens) {
      b.write(switch (t.field) {
        null => t.text,
        'yyyy' => n(y, 4),
        'yy' => n(y % 100, 2),
        'MMMM' => (bs ? s.bsMonths : s.adMonths)[m - 1],
        'MMM' => (bs ? s.bsMonthsShort : s.adMonthsShort)[m - 1],
        'MM' => n(m, 2),
        'M' => n(m),
        'dd' => n(d, 2),
        'd' => n(d),
        'EEEE' => s.weekdays[weekday - 1],
        'EEE' => s.weekdaysShort[weekday - 1],
        'G' => bs ? s.bsEra : s.adEra,
        _ => t.text,
      });
    }
    return b.toString();
  }

  static const _fields = [
    'yyyy', 'yy', 'MMMM', 'MMM', 'MM', 'M', 'dd', 'd', 'EEEE', 'EEE', 'G', //
  ];

  static List<_Token> _tokenize(String p) {
    final out = <_Token>[];
    var i = 0;
    while (i < p.length) {
      if (p[i] == "'") {
        if (i + 1 < p.length && p[i + 1] == "'") {
          out.add(const _Token("'"));
          i += 2;
          continue;
        }
        // Quoted text runs to the next lone quote; '' inside is a quote.
        final b = StringBuffer();
        var j = i + 1;
        while (j < p.length) {
          if (p[j] == "'") {
            if (j + 1 < p.length && p[j + 1] == "'") {
              b.write("'");
              j += 2;
              continue;
            }
            break;
          }
          b.write(p[j]);
          j++;
        }
        out.add(_Token(b.toString()));
        i = j + 1;
        continue;
      }
      final f = _fields.where((f) => p.startsWith(f, i)).firstOrNull;
      if (f != null) {
        out.add(_Token(f, field: f));
        i += f.length;
      } else {
        out.add(_Token(p[i]));
        i++;
      }
    }
    return out;
  }
}

class _Token {
  const _Token(this.text, {this.field});
  final String text;
  final String? field;
}
