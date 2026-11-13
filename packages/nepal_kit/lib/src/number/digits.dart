// Devanagari digits and South Asian (lakh/crore) grouping.
//
// toDevanagariDigits, toLatinDigits and the grouping walk are lifted from
// Tipot's receipts package (feat/receipts: packages/receipts/lib/src/domain/
// money.dart), with its tests.
library;

const String _devanagariDigits = '०१२३४५६७८९';

final RegExp _latinDigit = RegExp('[0-9]');
final RegExp _devanagariDigit = RegExp('[०-९]');

/// Replaces Western digits with Devanagari ones (`2083` → `२०८३`). Other
/// characters are left as they are.
String toDevanagariDigits(String input) => input.replaceAllMapped(
  _latinDigit,
  (m) => _devanagariDigits[m[0]!.codeUnitAt(0) - 0x30],
);

/// Replaces Devanagari digits with Western ones (`२०८३` → `2083`).
String toLatinDigits(String input) => input.replaceAllMapped(
  _devanagariDigit,
  (m) => '${_devanagariDigits.indexOf(m[0]!)}',
);

/// Whether [input] has any Devanagari character (U+0900–U+097F).
bool hasDevanagari(String input) =>
    input.runes.any((c) => c >= 0x0900 && c <= 0x097F);

/// Groups an integer the South Asian way: `12345678` → `1,23,45,678`.
///
/// The last three digits form one group and every two digits before them
/// another. Pass [devanagari] for `१,२३,४५,६७८`.
String groupLakh(int value, {bool devanagari = false}) {
  final negative = value < 0;
  final out = _groupDigits(value.abs().toString());
  final s = negative ? '-$out' : out;
  return devanagari ? toDevanagariDigits(s) : s;
}

/// Formats [value] with lakh grouping and exactly [decimals] decimal
/// places (rounded half away from zero): `1234567.891` → `12,34,567.89`.
String formatNepaliNumber(
  num value, {
  int decimals = 0,
  bool devanagari = false,
}) {
  RangeError.checkValueInInterval(decimals, 0, 10, 'decimals');
  final fixed = value.abs().toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  final whole = dot < 0 ? fixed : fixed.substring(0, dot);
  final frac = dot < 0 ? '' : fixed.substring(dot);
  final isZero = RegExp(r'^[0.]*$').hasMatch(fixed);
  final s = '${value < 0 && !isZero ? '-' : ''}${_groupDigits(whole)}$frac';
  return devanagari ? toDevanagariDigits(s) : s;
}

String _groupDigits(String digits) {
  if (digits.length <= 3) return digits;
  final last3 = digits.substring(digits.length - 3);
  var head = digits.substring(0, digits.length - 3);
  final parts = <String>[];
  while (head.length > 2) {
    parts.insert(0, head.substring(head.length - 2));
    head = head.substring(0, head.length - 2);
  }
  if (head.isNotEmpty) parts.insert(0, head);
  return '${parts.join(',')},$last3';
}
