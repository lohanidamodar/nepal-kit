// VAT in basis points, inclusive or exclusive.
//
// Lifted from Tipot's receipts package (feat/receipts: packages/receipts/
// lib/src/domain/vat.dart) with its tests, moved onto [Npr].
library;

import 'digits.dart';
import 'npr.dart';

/// A business's VAT: a rate in basis points (1300 = 13%, Nepal's standard
/// rate) and whether typed prices already include it. A rate of 0 means
/// the business does not charge VAT (for example a PAN-only business).
class VatRule {
  /// A rule charging [rateBp] basis points.
  const VatRule({this.rateBp = 0, this.inclusive = false});

  /// Nepal's standard 13%, added on top of the prices.
  static const VatRule nepalStandard = VatRule(rateBp: 1300);

  /// No VAT.
  static const VatRule none = VatRule();

  /// Rate in basis points (1300 = 13%).
  final int rateBp;

  /// Whether the prices already include VAT.
  final bool inclusive;

  /// Whether any VAT is charged.
  bool get charges => rateBp > 0;

  /// Splits [lines] (the sum of line amounts as typed) by this rule.
  VatBreakdown apply(Npr lines) => applyVat(lines, this);

  @override
  bool operator ==(Object other) =>
      other is VatRule &&
      other.rateBp == rateBp &&
      other.inclusive == inclusive;

  @override
  int get hashCode => Object.hash(rateBp, inclusive);
}

/// What one bill owes, split for printing.
class VatBreakdown {
  /// A breakdown; normally made by [applyVat].
  const VatBreakdown({
    required this.lines,
    required this.vat,
    required this.total,
  });

  /// Sum of the line amounts as typed.
  final Npr lines;

  /// The VAT.
  final Npr vat;

  /// What the customer pays.
  final Npr total;

  /// The amount before VAT.
  Npr get taxable => total - vat;
}

/// Splits [lines] by [rule], rounding VAT to the nearest paisa (halves
/// up).
///
/// Inclusive: the total is what was typed and VAT is the part of it that
/// is tax, total × rate / (100% + rate). Exclusive: VAT is added on top,
/// lines × rate.
VatBreakdown applyVat(Npr lines, VatRule rule) {
  if (!rule.charges || lines.paisa <= 0) {
    return VatBreakdown(lines: lines, vat: Npr.zero, total: lines);
  }
  if (rule.inclusive) {
    final vat = Npr(
      divideRounded(lines.paisa * rule.rateBp, 10000 + rule.rateBp),
    );
    return VatBreakdown(lines: lines, vat: vat, total: lines);
  }
  final vat = Npr(divideRounded(lines.paisa * rule.rateBp, 10000));
  return VatBreakdown(lines: lines, vat: vat, total: lines + vat);
}

/// `"13"` → 1300, `"12.5"` → 1250, `""` → 0. Null for anything that is
/// not a rate from 0 to 100 with at most two decimals.
int? parseVatRate(String text) {
  final t = toLatinDigits(text).replaceAll('%', '').trim();
  if (t.isEmpty) return 0;
  final m = RegExp(r'^(\d{1,3})(?:\.(\d{1,2}))?$').firstMatch(t);
  if (m == null) return null;
  final whole = int.parse(m.group(1)!);
  final frac = int.parse((m.group(2) ?? '').padRight(2, '0'));
  final bp = whole * 100 + frac;
  return bp > 10000 ? null : bp;
}

/// 1300 → `"13"`, 1250 → `"12.5"`, 0 → `""`.
String formatVatRate(int bp) {
  if (bp == 0) return '';
  final whole = bp ~/ 100;
  final frac = bp % 100;
  if (frac == 0) return '$whole';
  final f = frac.toString().padLeft(2, '0');
  return '$whole.${f.endsWith('0') ? f[0] : f}';
}

/// Whether [pan] looks like a Nepal PAN/VAT registration number: nine
/// digits (Western or Devanagari; spaces and dashes ignored).
///
/// This is a shape check only; it cannot tell whether IRD issued it.
bool isValidPan(String pan) => RegExp(
  r'^\d{9}$',
).hasMatch(toLatinDigits(pan).replaceAll(RegExp(r'[\s-]'), ''));
