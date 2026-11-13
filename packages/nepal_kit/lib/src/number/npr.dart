// Nepalese rupees held as integer paisa.
//
// Parsing and formatting are lifted from Tipot's receipts package
// (feat/receipts: packages/receipts/lib/src/domain/money.dart) and widened
// into a value type.
library;

import 'amount_words.dart';
import 'digits.dart';

/// How [Npr.format] labels an amount.
enum NprSymbol {
  /// `Rs. 1,000`
  rs('Rs. '),

  /// `रु 1,000` (the usual Nepali abbreviation of रुपैयाँ)
  rupee('रु '),

  /// `NPR 1,000`, the ISO 4217 code
  code('NPR '),

  /// `1,000`
  none('');

  const NprSymbol(this.prefix);

  /// Text written before the number.
  final String prefix;
}

/// When [Npr.format] writes the paisa.
enum PaisaDisplay {
  /// Only when there are any: `1,200` and `1,200.50`.
  auto,

  /// Always: `1,200.00`.
  always,

  /// Never; paisa are dropped (not rounded).
  never,
}

/// An amount of Nepalese rupees, stored as whole paisa (1 rupee = 100
/// paisa) so that sums never drift the way floating-point rupees do.
class Npr implements Comparable<Npr> {
  /// [paisa] paisa.
  const Npr(this.paisa);

  /// [rupees] rupees and [paisa] paisa: `Npr.rupees(1200, 50)` is
  /// Rs. 1,200.50.
  const Npr.rupees(int rupees, [int paisa = 0]) : paisa = rupees * 100 + paisa;

  /// Zero.
  static const Npr zero = Npr(0);

  /// Paisa per rupee.
  static const int scale = 100;

  /// The amount, in paisa.
  final int paisa;

  /// Whole rupees, toward zero.
  int get wholeRupees => paisa ~/ scale;

  /// The paisa part, 0..99 (sign follows [paisa]).
  int get paisaPart => paisa.remainder(scale);

  /// Whether the amount is below zero.
  bool get isNegative => paisa < 0;

  /// Whether the amount is zero.
  bool get isZero => paisa == 0;

  /// Parses typed text: Western or Devanagari digits, optional `Rs.`,
  /// `रु`, `रू` or `NPR`, commas and spaces, at most two decimals, an
  /// optional leading minus.
  ///
  /// Returns null for anything else.
  static Npr? tryParse(String input) {
    var t = toLatinDigits(input).trim();
    var negative = false;
    // A sign may come before the symbol (as [format] writes it) or after.
    if (t.startsWith('-') || t.startsWith('−')) {
      negative = true;
      t = t.substring(1).trimLeft();
    }
    t = t.replaceFirst(
      RegExp(r'^(rs\.?|npr|रु\.?|रू\.?)\s*', caseSensitive: false),
      '',
    );
    t = t.replaceAll(RegExp(r'[,\s]'), '');
    if (!negative && (t.startsWith('-') || t.startsWith('−'))) {
      negative = true;
      t = t.substring(1);
    }
    if (t.isEmpty || t == '.' || !RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(t)) {
      return null;
    }
    final parts = t.split('.');
    final whole = parts[0].isEmpty ? 0 : int.parse(parts[0]);
    final frac = parts.length > 1 ? '${parts[1]}00'.substring(0, 2) : '00';
    final p = whole * scale + int.parse(frac);
    return Npr(negative ? -p : p);
  }

  /// Like [tryParse], but throws [FormatException].
  static Npr parse(String input) =>
      tryParse(input) ?? (throw FormatException('Not an NPR amount', input));

  /// Formats with lakh grouping: `Rs. 1,00,000`, `रु १,००,०००.५०`.
  ///
  /// A negative amount is written `-Rs. 500`.
  String format({
    NprSymbol symbol = NprSymbol.rs,
    bool devanagari = false,
    PaisaDisplay paisaDisplay = PaisaDisplay.auto,
  }) {
    final abs = paisa.abs();
    final rupees = groupLakh(abs ~/ scale);
    final p = abs % scale;
    final showPaisa = switch (paisaDisplay) {
      PaisaDisplay.always => true,
      PaisaDisplay.never => false,
      PaisaDisplay.auto => p != 0,
    };
    var s = showPaisa ? '$rupees.${p.toString().padLeft(2, '0')}' : rupees;
    if (devanagari) s = toDevanagariDigits(s);
    return '${paisa < 0 ? '-' : ''}${symbol.prefix}$s';
  }

  /// A plain number for an input field: no grouping, no symbol, trailing
  /// zero paisa trimmed (`120`, `120.5`, `120.05`). Round-trips through
  /// [tryParse].
  String get editText {
    final abs = paisa.abs();
    final p = abs % scale;
    final sign = paisa < 0 ? '-' : '';
    if (p == 0) return '$sign${abs ~/ scale}';
    final frac = p.toString().padLeft(2, '0');
    return '$sign${abs ~/ scale}.${frac.endsWith('0') ? frac[0] : frac}';
  }

  /// The amount in words for a receipt; see [nprInWords].
  String inWords({AmountWordsLanguage language = AmountWordsLanguage.en}) =>
      nprInWords(this, language: language);

  /// Sum.
  Npr operator +(Npr other) => Npr(paisa + other.paisa);

  /// Difference.
  Npr operator -(Npr other) => Npr(paisa - other.paisa);

  /// Negation.
  Npr operator -() => Npr(-paisa);

  /// The amount times a whole [count] (quantity, months, ...).
  Npr operator *(int count) => Npr(paisa * count);

  /// The amount times [numerator] / [denominator], rounded to the nearest
  /// paisa, halves away from zero. Use it for fractional quantities
  /// (`times(1500, 1000)` is ×1.5) and percentages.
  Npr times(int numerator, int denominator) =>
      Npr(divideRounded(paisa * numerator, denominator));

  /// [percentBp] basis points of this amount (1300 = 13%), rounded like
  /// [times].
  Npr percent(int percentBp) => times(percentBp, 10000);

  /// Splits the amount into [parts] shares that differ by at most one
  /// paisa and add up exactly to this amount; earlier shares get the
  /// extra paisa.
  List<Npr> split(int parts) {
    if (parts <= 0) throw ArgumentError.value(parts, 'parts', 'must be > 0');
    final base = paisa ~/ parts, extra = paisa.remainder(parts);
    return [
      for (var i = 0; i < parts; i++)
        Npr(base + (i < extra.abs() ? (extra < 0 ? -1 : 1) : 0)),
    ];
  }

  /// Splits the amount in proportion to [weights], exactly (largest
  /// remainder method). Useful for sharing a discount across lines.
  List<Npr> allocate(List<int> weights) {
    final total = weights.fold(0, (a, b) => a + b);
    if (weights.isEmpty || total <= 0 || weights.any((w) => w < 0)) {
      throw ArgumentError.value(weights, 'weights');
    }
    final shares = [for (final w in weights) paisa * w ~/ total];
    var left = paisa - shares.fold(0, (a, b) => a + b);
    final order = List.generate(weights.length, (i) => i)
      ..sort(
        (a, b) => (paisa * weights[b])
            .remainder(total)
            .abs()
            .compareTo((paisa * weights[a]).remainder(total).abs()),
      );
    final step = left < 0 ? -1 : 1;
    for (var i = 0; left != 0; i = (i + 1) % order.length) {
      shares[order[i]] += step;
      left -= step;
    }
    return [for (final s in shares) Npr(s)];
  }

  /// The larger of this and [other].
  Npr max(Npr other) => paisa >= other.paisa ? this : other;

  /// The smaller of this and [other].
  Npr min(Npr other) => paisa <= other.paisa ? this : other;

  /// Less than.
  bool operator <(Npr other) => paisa < other.paisa;

  /// Less than or equal.
  bool operator <=(Npr other) => paisa <= other.paisa;

  /// Greater than.
  bool operator >(Npr other) => paisa > other.paisa;

  /// Greater than or equal.
  bool operator >=(Npr other) => paisa >= other.paisa;

  @override
  int compareTo(Npr other) => paisa.compareTo(other.paisa);

  @override
  bool operator ==(Object other) => other is Npr && other.paisa == paisa;

  @override
  int get hashCode => paisa.hashCode;

  /// `Rs. 1,200.50`.
  @override
  String toString() => format();
}

/// Sums [amounts].
Npr sumNpr(Iterable<Npr> amounts) =>
    Npr(amounts.fold(0, (a, b) => a + b.paisa));

/// [a] / [b] rounded to the nearest integer, halves away from zero.
int divideRounded(int a, int b) {
  if (b == 0) throw ArgumentError.value(b, 'b', 'division by zero');
  if (b < 0) return divideRounded(-a, -b);
  final q = (a.abs() * 2 + b) ~/ (b * 2);
  return a < 0 ? -q : q;
}
