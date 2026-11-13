import 'dart:math';

import 'package:nepal_kit/nepal_kit.dart';
import 'package:test/test.dart';

void main() {
  group('digits and grouping (from Tipot receipts)', () {
    test('digit conversion both ways', () {
      expect(toDevanagariDigits('SK-0043'), 'SK-००४३');
      expect(toLatinDigits('२०८३/०७/२३'), '2083/07/23');
      expect(toLatinDigits(toDevanagariDigits('0123456789')), '0123456789');
      expect(hasDevanagari('Ram राम'), isTrue);
      expect(hasDevanagari('Ram'), isFalse);
    });

    test('groupLakh', () {
      expect(groupLakh(0), '0');
      expect(groupLakh(999), '999');
      expect(groupLakh(1000), '1,000');
      expect(groupLakh(100000), '1,00,000');
      expect(groupLakh(10000000), '1,00,00,000');
      expect(groupLakh(12345678), '1,23,45,678');
      expect(groupLakh(-1234567), '-12,34,567');
      expect(groupLakh(100000, devanagari: true), '१,००,०००');
    });

    test('groupLakh agrees with a reference on random values', () {
      String ref(int v) {
        final s = v.toString();
        if (s.length <= 3) return s;
        final head = s.substring(0, s.length - 3);
        final groups = <String>[];
        for (var i = head.length; i > 0; i -= 2) {
          groups.insert(0, head.substring(max(0, i - 2), i));
        }
        return '${groups.join(',')},${s.substring(s.length - 3)}';
      }

      final r = Random(7);
      for (var i = 0; i < 2000; i++) {
        final v = r.nextInt(1 << 31) * (r.nextBool() ? 1 : 1000);
        expect(groupLakh(v), ref(v), reason: '$v');
      }
    });

    test('formatNepaliNumber', () {
      expect(formatNepaliNumber(1234567.891, decimals: 2), '12,34,567.89');
      expect(formatNepaliNumber(-1500.5, decimals: 1), '-1,500.5');
      expect(formatNepaliNumber(-0.001, decimals: 2), '0.00');
      expect(formatNepaliNumber(250000, devanagari: true), '२,५०,०००');
    });
  });

  group('Npr', () {
    test('parse (Tipot cases plus symbols and sign)', () {
      expect(Npr.tryParse('120'), const Npr(12000));
      expect(Npr.tryParse('120.5'), const Npr(12050));
      expect(Npr.tryParse('120.05'), const Npr(12005));
      expect(Npr.tryParse('1,20,000'), const Npr(12000000));
      expect(Npr.tryParse(' 45 '), const Npr(4500));
      expect(Npr.tryParse('.5'), const Npr(50));
      expect(Npr.tryParse('१,२५०.५०'), const Npr(125050));
      expect(Npr.tryParse('Rs. 1,000'), const Npr(100000));
      expect(Npr.tryParse('रु १००'), const Npr(10000));
      expect(Npr.tryParse('NPR 5'), const Npr(500));
      expect(Npr.tryParse('-5'), const Npr(-500));
      for (final bad in ['', '.', 'abc', '12.345', '1.2.3', '12a', 'Rs.']) {
        expect(Npr.tryParse(bad), isNull, reason: bad);
      }
      expect(() => Npr.parse('x'), throwsFormatException);
    });

    test('format', () {
      expect(const Npr(12000).format(), 'Rs. 120');
      expect(const Npr(12050).format(), 'Rs. 120.50');
      expect(const Npr.rupees(100000).format(), 'Rs. 1,00,000');
      expect(
        const Npr.rupees(
          100000,
        ).format(symbol: NprSymbol.rupee, devanagari: true),
        'रु १,००,०००',
      );
      expect(
        const Npr(12345678900).format(symbol: NprSymbol.none),
        '12,34,56,789',
      );
      expect(
        const Npr.rupees(5).format(paisaDisplay: PaisaDisplay.always),
        'Rs. 5.00',
      );
      expect(const Npr(599).format(paisaDisplay: PaisaDisplay.never), 'Rs. 5');
      expect(const Npr(-50000).format(symbol: NprSymbol.code), '-NPR 500');
      expect(Npr.zero.toString(), 'Rs. 0');
    });

    test('editText round-trips through tryParse', () {
      for (final v in [0, 5, 50, 12000, 12050, 12005, 9999999, -12050]) {
        expect(Npr.tryParse(Npr(v).editText), Npr(v), reason: '$v');
      }
      expect(const Npr(12050).editText, '120.5');
    });

    test('format and parse round-trip on random amounts', () {
      final r = Random(42);
      for (var i = 0; i < 5000; i++) {
        final v = Npr(r.nextInt(1 << 32) - (1 << 31));
        for (final sym in NprSymbol.values) {
          for (final dev in [false, true]) {
            final s = v.format(symbol: sym, devanagari: dev);
            expect(Npr.tryParse(s), v, reason: s);
          }
        }
      }
    });

    test('arithmetic stays in whole paisa', () {
      expect(const Npr.rupees(10) + const Npr(5), const Npr(1005));
      expect(const Npr.rupees(10) - const Npr.rupees(15), const Npr.rupees(-5));
      expect(const Npr.rupees(250) * 3, const Npr.rupees(750));
      expect(const Npr(333).times(1500, 1000), const Npr(500)); // 499.5 -> 500
      expect(const Npr(-333).times(1500, 1000), const Npr(-500));
      expect(const Npr(1000).percent(1300), const Npr(130));
      expect(
        sumNpr([for (var i = 0; i < 10; i++) const Npr(10)]),
        const Npr(100),
      );
      // 0.1 + 0.2 in rupees is exact here.
      expect(Npr.parse('0.1') + Npr.parse('0.2'), Npr.parse('0.3'));
    });

    test('split and allocate add up exactly', () {
      expect(const Npr(1000).split(3), [
        const Npr(334),
        const Npr(333),
        const Npr(333),
      ]);
      expect(const Npr(-1000).split(3), [
        const Npr(-334),
        const Npr(-333),
        const Npr(-333),
      ]);
      final r = Random(3);
      for (var i = 0; i < 1000; i++) {
        final total = Npr(r.nextInt(10000000));
        final weights = [
          for (var j = 0; j < 1 + r.nextInt(6); j++) r.nextInt(100) + 1,
        ];
        final parts = total.allocate(weights);
        expect(sumNpr(parts), total);
        final n = 1 + r.nextInt(12);
        final split = total.split(n);
        expect(sumNpr(split), total);
        expect(
          split.map((s) => s.paisa).reduce(max) -
              split.map((s) => s.paisa).reduce(min),
          lessThanOrEqualTo(1),
        );
      }
      expect(const Npr(100).allocate([1, 1, 1]), [
        const Npr(34),
        const Npr(33),
        const Npr(33),
      ]);
      expect(() => const Npr(1).split(0), throwsArgumentError);
    });

    test('comparison', () {
      expect(const Npr(5) < const Npr(6), isTrue);
      expect(const Npr(5).max(const Npr(6)), const Npr(6));
      expect(const Npr(5).compareTo(const Npr(5)), 0);
    });
  });

  test('divideRounded rounds halves away from zero', () {
    expect(divideRounded(5, 2), 3);
    expect(divideRounded(-5, 2), -3);
    expect(divideRounded(4, 3), 1);
    expect(divideRounded(5, -2), -3);
    expect(() => divideRounded(1, 0), throwsArgumentError);
  });

  group('VAT (from Tipot receipts)', () {
    test('exclusive adds 13% on top', () {
      final b = applyVat(const Npr.rupees(1000), VatRule.nepalStandard);
      expect(b.vat, const Npr.rupees(130));
      expect(b.total, const Npr.rupees(1130));
      expect(b.taxable, const Npr.rupees(1000));
    });

    test('inclusive takes the tax out of the total', () {
      final b = applyVat(
        const Npr.rupees(1130),
        const VatRule(rateBp: 1300, inclusive: true),
      );
      expect(b.vat, const Npr.rupees(130));
      expect(b.total, const Npr.rupees(1130));
      expect(b.taxable, const Npr.rupees(1000));
      // 100 incl. 13%: 11.504.. -> 11.50
      expect(
        applyVat(
          const Npr.rupees(100),
          const VatRule(rateBp: 1300, inclusive: true),
        ).vat,
        const Npr(1150),
      );
    });

    test('no VAT, zero and negative lines', () {
      expect(applyVat(const Npr(500), VatRule.none).vat, Npr.zero);
      expect(applyVat(Npr.zero, VatRule.nepalStandard).total, Npr.zero);
      expect(applyVat(const Npr(-500), VatRule.nepalStandard).vat, Npr.zero);
    });

    test('inclusive taxable + vat always equals the total', () {
      final r = Random(9);
      for (var i = 0; i < 2000; i++) {
        final lines = Npr(r.nextInt(100000000));
        final b = applyVat(
          lines,
          VatRule(rateBp: r.nextInt(3000), inclusive: true),
        );
        expect(b.taxable + b.vat, b.total);
        expect(b.total, lines);
      }
    });

    test('rates', () {
      expect(parseVatRate('13'), 1300);
      expect(parseVatRate('12.5%'), 1250);
      expect(parseVatRate('१३'), 1300);
      expect(parseVatRate(''), 0);
      expect(parseVatRate('101'), isNull);
      expect(parseVatRate('1.234'), isNull);
      expect(formatVatRate(1300), '13');
      expect(formatVatRate(1250), '12.5');
      expect(formatVatRate(0), '');
    });

    test('PAN shape', () {
      expect(isValidPan('301234567'), isTrue);
      expect(isValidPan('३०१ २३४ ५६७'), isTrue);
      expect(isValidPan('30123456'), isFalse);
      expect(isValidPan('30123456a'), isFalse);
    });
  });
}
