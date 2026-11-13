import 'package:nepal_kit/nepal_kit.dart';
import 'package:test/test.dart';

void main() {
  group('mobile numbers', () {
    test('accepted forms all normalise to E.164', () {
      for (final input in [
        '9841234567',
        '984-1234567',
        '984 123 4567',
        '(984) 1234567',
        '09841234567',
        '+9779841234567',
        '+977 984-1234567',
        '+977-9841234567',
        '+977 09841234567',
        '9779841234567',
        '009779841234567',
        '९८४१२३४५६७',
        '+९७७ ९८४१२३४५६७',
      ]) {
        expect(normalizeNepaliMobile(input), '+9779841234567', reason: input);
      }
    });

    test('carriers by prefix', () {
      final cases = {
        '9841234567': NepalCarrier.ntc,
        '9851234567': NepalCarrier.ntc,
        '9861234567': NepalCarrier.ntc,
        '9741234567': NepalCarrier.ntc,
        '9751234567': NepalCarrier.ntc,
        '9761234567': NepalCarrier.ntc,
        '9801234567': NepalCarrier.ncell,
        '9811234567': NepalCarrier.ncell,
        '9821234567': NepalCarrier.ncell,
        '9701234567': NepalCarrier.ncell,
        '9711234567': NepalCarrier.ncell,
      };
      cases.forEach((n, c) {
        final p = NepaliPhone.tryParse(n)!;
        expect(p.carrier, c, reason: n);
        expect(p.isMobile, isTrue);
        expect(p.carrier.isActive, isTrue);
      });
    });

    test('carriers that stopped operating', () {
      for (final n in [
        '9611234567',
        '9621234567',
        '9881234567',
        '9721234567',
        '9631234567',
      ]) {
        expect(
          NepaliPhone.validate(n).error,
          PhoneError.inactiveCarrier,
          reason: n,
        );
        expect(
          NepaliPhone.tryParse(n, allowInactive: true)!.carrier.isActive,
          isFalse,
        );
      }
    });

    test('rejections say why', () {
      final cases = {
        '': PhoneError.empty,
        '   ': PhoneError.empty,
        '98412345a7': PhoneError.invalidCharacters,
        '+919876543210': PhoneError.notNepal,
        '+14155550100': PhoneError.notNepal,
        '984123456': PhoneError.wrongLength,
        '98412345678': PhoneError.wrongLength,
        '9901234567': PhoneError.unknownPrefix,
        '9001234567': PhoneError.unknownPrefix,
        '12345': PhoneError.wrongLength,
      };
      cases.forEach((input, e) {
        final v = NepaliPhone.validate(input);
        expect(v.isValid, isFalse, reason: input);
        expect(v.error, e, reason: input);
        expect(NepalKitStrings.en.phoneErrors[e.name], isNotNull);
        expect(NepalKitStrings.ne.phoneErrors[e.name], isNotNull);
      });
    });

    test('display forms and links', () {
      final p = NepaliPhone.tryParse('9841234567')!;
      expect(p.e164, '+9779841234567');
      expect(p.national, '9841234567');
      expect(p.format(), '984-1234567');
      expect(p.format(international: true), '+977 984-1234567');
      expect(p.format(devanagari: true), '९८४-१२३४५६७');
      expect(p.telUri.toString(), 'tel:+9779841234567');
      expect(
        p.smsUri(body: 'Rent due').toString(),
        'sms:+9779841234567?body=Rent%20due',
      );
      expect(p.whatsAppUri.toString(), 'https://wa.me/9779841234567');
      expect(p, NepaliPhone.tryParse('+977 984 1234567'));
    });
  });

  group('landlines', () {
    test('Kathmandu and outside the valley', () {
      final ktm = NepaliPhone.tryParse('01-4123456')!;
      expect(ktm.isMobile, isFalse);
      expect(ktm.carrier, NepalCarrier.landline);
      expect(ktm.e164, '+97714123456');
      expect(ktm.national, '01-4123456');
      expect(ktm.format(international: true), '+977 1-4123456');
      expect(NepaliPhone.tryParse('+97714123456'), ktm);

      final pokhara = NepaliPhone.tryParse('061-123456')!;
      expect(pokhara.e164, '+97761123456');
      expect(pokhara.national, '061-123456');
    });

    test('mobileOnly rejects them', () {
      expect(
        NepaliPhone.validate('01-4123456', mobileOnly: true).error,
        PhoneError.landlineNotAllowed,
      );
      expect(normalizeNepaliMobile('01-4123456'), isNull);
      expect(isValidNepaliMobile('9801234567'), isTrue);
    });
  });
}
