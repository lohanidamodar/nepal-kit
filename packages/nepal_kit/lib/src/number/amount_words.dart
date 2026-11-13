// Whole numbers and NPR amounts in words, on the South Asian scale
// (hundred, thousand, lakh, crore; Nepali also arba and kharba), for the
// "amount in words" line of a receipt or cheque.
//
// The number-name tables and the English/Nepali walks are lifted from
// Tipot's receipts package (feat/receipts: packages/receipts/lib/src/domain/
// amount_words.dart), with its tests; arba/kharba, negatives and the
// rupee/paisa sentence are new here.
library;

import 'npr.dart';

/// Language of [numberInWords] and [nprInWords].
enum AmountWordsLanguage {
  /// English, lakh/crore scale.
  en,

  /// Nepali (Devanagari).
  ne,
}

const _enOnes = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];
const _enTens = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

/// Nepali has a distinct word for every number from 1 to 99.
const _ne1to99 = [
  'शून्य',
  'एक',
  'दुई',
  'तीन',
  'चार',
  'पाँच',
  'छ',
  'सात',
  'आठ',
  'नौ',
  'दश',
  'एघार',
  'बाह्र',
  'तेह्र',
  'चौध',
  'पन्ध्र',
  'सोह्र',
  'सत्र',
  'अठार',
  'उन्नाइस',
  'बीस',
  'एक्काइस',
  'बाइस',
  'तेइस',
  'चौबीस',
  'पच्चीस',
  'छब्बीस',
  'सत्ताइस',
  'अठ्ठाइस',
  'उनन्तीस',
  'तीस',
  'एकतीस',
  'बत्तीस',
  'तेत्तीस',
  'चौँतीस',
  'पैँतीस',
  'छत्तीस',
  'सैँतीस',
  'अठतीस',
  'उनन्चालीस',
  'चालीस',
  'एकचालीस',
  'बयालीस',
  'त्रिचालीस',
  'चवालीस',
  'पैँतालीस',
  'छयालीस',
  'सतचालीस',
  'अठचालीस',
  'उनन्चास',
  'पचास',
  'एकाउन्न',
  'बाउन्न',
  'त्रिपन्न',
  'चउन्न',
  'पचपन्न',
  'छपन्न',
  'सन्ताउन्न',
  'अन्ठाउन्न',
  'उनन्साठी',
  'साठी',
  'एकसट्ठी',
  'बयसट्ठी',
  'त्रिसट्ठी',
  'चौसट्ठी',
  'पैँसट्ठी',
  'छयसट्ठी',
  'सतसट्ठी',
  'अठसट्ठी',
  'उनन्सत्तरी',
  'सत्तरी',
  'एकहत्तर',
  'बहत्तर',
  'त्रिहत्तर',
  'चौहत्तर',
  'पचहत्तर',
  'छयहत्तर',
  'सतहत्तर',
  'अठहत्तर',
  'उनासी',
  'असी',
  'एकासी',
  'बयासी',
  'त्रियासी',
  'चौरासी',
  'पचासी',
  'छयासी',
  'सतासी',
  'अठासी',
  'उनान्नब्बे',
  'नब्बे',
  'एकानब्बे',
  'बयानब्बे',
  'त्रियानब्बे',
  'चौरानब्बे',
  'पन्चानब्बे',
  'छयानब्बे',
  'सन्तानब्बे',
  'अन्ठानब्बे',
  'उनान्सय',
];

String _en2(int n) => n < 20
    ? _enOnes[n]
    : _enTens[n ~/ 10] + (n % 10 > 0 ? '-${_enOnes[n % 10]}' : '');

String _en3(int n) {
  final parts = <String>[];
  if (n >= 100) parts.add('${_enOnes[n ~/ 100]} hundred');
  if (n % 100 > 0) parts.add(_en2(n % 100));
  return parts.join(' ');
}

String _enWords(int n) {
  if (n == 0) return _enOnes[0];
  final parts = <String>[];
  final crore = n ~/ 10000000;
  var rest = n % 10000000;
  if (crore > 0) parts.add('${_enWords(crore)} crore');
  final lakh = rest ~/ 100000;
  rest %= 100000;
  if (lakh > 0) parts.add('${_en2(lakh)} lakh');
  final thousand = rest ~/ 1000;
  rest %= 1000;
  if (thousand > 0) parts.add('${_en2(thousand)} thousand');
  if (rest > 0) parts.add(_en3(rest));
  return parts.join(' ');
}

/// Nepali scale words above a crore: अर्ब = 100 crore, खर्ब = 100 arba.
String _neWords(int n) {
  if (n == 0) return _ne1to99[0];
  final parts = <String>[];
  final kharba = n ~/ 100000000000;
  var rest = n % 100000000000;
  if (kharba > 0) parts.add('${_neWords(kharba)} खर्ब');
  final arba = rest ~/ 1000000000;
  rest %= 1000000000;
  if (arba > 0) parts.add('${_ne1to99[arba]} अर्ब');
  final crore = rest ~/ 10000000;
  rest %= 10000000;
  if (crore > 0) parts.add('${_ne1to99[crore]} करोड');
  final lakh = rest ~/ 100000;
  rest %= 100000;
  if (lakh > 0) parts.add('${_ne1to99[lakh]} लाख');
  final thousand = rest ~/ 1000;
  rest %= 1000;
  if (thousand > 0) parts.add('${_ne1to99[thousand]} हजार');
  final hundred = rest ~/ 100;
  rest %= 100;
  if (hundred > 0) parts.add('${_ne1to99[hundred]} सय');
  if (rest > 0) parts.add(_ne1to99[rest]);
  return parts.join(' ');
}

/// [n] in words: `123456` → "one lakh twenty-three thousand four hundred
/// fifty-six" (en) or "एक लाख तेइस हजार चार सय छपन्न" (ne).
///
/// English stays on the crore scale ("one hundred crore"); Nepali goes on
/// to अर्ब and खर्ब ("एक अर्ब"). Negative numbers get "minus" / "ऋण".
String numberInWords(
  int n, {
  AmountWordsLanguage language = AmountWordsLanguage.en,
}) {
  final en = language == AmountWordsLanguage.en;
  if (n < 0) {
    return '${en ? 'minus' : 'ऋण'} ${numberInWords(-n, language: language)}';
  }
  return en ? _enWords(n) : _neWords(n);
}

/// [amount] as a receipt's "amount in words" line.
///
/// - en: "Rupees one lakh twenty thousand and fifty paisa only"
/// - ne: "एक लाख बीस हजार रुपैयाँ पचास पैसा मात्र"
///
/// Paisa are left out when there are none. Set [only] to false to drop
/// the closing "only" / "मात्र".
String nprInWords(
  Npr amount, {
  AmountWordsLanguage language = AmountWordsLanguage.en,
  bool only = true,
}) {
  final negative = amount.paisa < 0;
  final abs = amount.paisa.abs();
  final rupees = abs ~/ 100, paisa = abs % 100;
  if (language == AmountWordsLanguage.en) {
    final b = StringBuffer(negative ? 'Minus rupees ' : 'Rupees ')
      ..write(_enWords(rupees));
    if (paisa > 0) b.write(' and ${_en2(paisa)} paisa');
    if (only) b.write(' only');
    return b.toString();
  }
  final b = StringBuffer(negative ? 'ऋण ' : '')
    ..write('${_neWords(rupees)} रुपैयाँ');
  if (paisa > 0) b.write(' ${_ne1to99[paisa]} पैसा');
  if (only) b.write(' मात्र');
  return b.toString();
}
