import 'package:nepal_kit/nepal_kit.dart';
import 'package:test/test.dart';

const _ne = AmountWordsLanguage.ne;

void main() {
  group('English, South Asian scale (Tipot cases and more)', () {
    final cases = {
      0: 'zero',
      7: 'seven',
      15: 'fifteen',
      20: 'twenty',
      21: 'twenty-one',
      99: 'ninety-nine',
      100: 'one hundred',
      101: 'one hundred one',
      110: 'one hundred ten',
      999: 'nine hundred ninety-nine',
      1000: 'one thousand',
      1001: 'one thousand one',
      1790: 'one thousand seven hundred ninety',
      10000: 'ten thousand',
      99999: 'ninety-nine thousand nine hundred ninety-nine',
      100000: 'one lakh',
      123456: 'one lakh twenty-three thousand four hundred fifty-six',
      1000000: 'ten lakh',
      10000000: 'one crore',
      12345678:
          'one crore twenty-three lakh forty-five thousand six hundred seventy-eight',
      1000000000: 'one hundred crore',
      123456789012:
          'twelve thousand three hundred forty-five crore sixty-seven lakh '
          'eighty-nine thousand twelve',
    };
    cases.forEach((n, w) => test('$n', () => expect(numberInWords(n), w)));
    test('negative', () => expect(numberInWords(-5), 'minus five'));
  });

  group('Nepali', () {
    final cases = {
      0: 'शून्य',
      1: 'एक',
      21: 'एक्काइस',
      45: 'पैँतालीस',
      99: 'उनान्सय',
      100: 'एक सय',
      105: 'एक सय पाँच',
      1790: 'एक हजार सात सय नब्बे',
      250000: 'दुई लाख पचास हजार',
      10000000: 'एक करोड',
      1000000000: 'एक अर्ब',
      1250000000: 'एक अर्ब पच्चीस करोड',
      100000000000: 'एक खर्ब',
      123456789: 'बाह्र करोड चौँतीस लाख छपन्न हजार सात सय उनान्नब्बे',
    };
    cases.forEach(
      (n, w) => test('$n', () => expect(numberInWords(n, language: _ne), w)),
    );
    test('negative', () => expect(numberInWords(-5, language: _ne), 'ऋण पाँच'));

    test('every number 1..99 has its own single word', () {
      final words = {
        for (var i = 1; i < 100; i++) numberInWords(i, language: _ne),
      };
      expect(words, hasLength(99));
      expect(words.every((w) => !w.contains(' ')), isTrue);
    });
  });

  test('every number below ten lakh has a distinct name in both languages', () {
    final en = <String>{}, ne = <String>{};
    for (var i = 0; i < 1000000; i += 7) {
      expect(en.add(numberInWords(i)), isTrue, reason: '$i');
      expect(ne.add(numberInWords(i, language: _ne)), isTrue, reason: '$i');
    }
  });

  group('NPR on a receipt', () {
    test('English', () {
      expect(
        nprInWords(const Npr.rupees(120000)),
        'Rupees one lakh twenty thousand only',
      );
      expect(
        nprInWords(const Npr.rupees(1130, 50)),
        'Rupees one thousand one hundred thirty and fifty paisa only',
      );
      expect(
        nprInWords(const Npr(5), only: false),
        'Rupees zero and five paisa',
      );
      expect(nprInWords(const Npr(-100)), 'Minus rupees one only');
    });

    test('Nepali', () {
      expect(
        nprInWords(const Npr.rupees(120000), language: _ne),
        'एक लाख बीस हजार रुपैयाँ मात्र',
      );
      expect(
        nprInWords(const Npr.rupees(1130, 50), language: _ne),
        'एक हजार एक सय तीस रुपैयाँ पचास पैसा मात्र',
      );
      expect(const Npr.rupees(5).inWords(language: _ne), 'पाँच रुपैयाँ मात्र');
    });
  });
}
