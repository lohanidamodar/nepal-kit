// Nepali phone numbers: validation, normalisation to E.164, carrier
// lookup and display.
//
// The input clean-up (Devanagari digits, separators, a `00` or `+977`
// prefix) follows Sandesh's sandesh_api/lib/src/phone.dart. Sandesh checks
// numbers against libphonenumber's metadata for any region; this file
// knows only Nepal, so it needs no dependency and can name the carrier.
library;

import '../number/digits.dart';

/// Who issued a Nepali mobile number, read from its prefix.
///
/// Nepal has no number portability yet, so the prefix still names the
/// carrier. Prefixes are from Nepal Telecommunications Authority
/// allocations as reported by the operators and the trade press (Ncell's
/// 971 range opened in 2025).
enum NepalCarrier {
  /// Nepal Telecom (NTC, Namaste): 984, 985, 986, 974, 975, 976.
  ntc('Nepal Telecom', 'नेपाल टेलिकम'),

  /// Ncell: 980, 981, 982, 970, 971.
  ncell('Ncell', 'एनसेल'),

  /// Smart Telecom: 961, 962, 988. Licence revoked; numbers no longer in
  /// service.
  smart('Smart Telecom', 'स्मार्ट टेलिकम'),

  /// UTL: 972. No longer in service.
  utl('UTL', 'यूटीएल'),

  /// Hello Mobile (Nepal Satellite Telecom): 963. No longer in service.
  hello('Hello Mobile', 'हेलो मोबाइल'),

  /// A landline (no carrier is read from it).
  landline('Landline', 'ल्यान्डलाइन');

  const NepalCarrier(this.nameEn, this.nameNe);

  /// English name.
  final String nameEn;

  /// Nepali name.
  final String nameNe;

  /// Whether the carrier still runs a mobile network.
  bool get isActive => this == ntc || this == ncell;
}

const Map<String, NepalCarrier> _mobilePrefixes = {
  '984': NepalCarrier.ntc,
  '985': NepalCarrier.ntc,
  '986': NepalCarrier.ntc,
  '974': NepalCarrier.ntc,
  '975': NepalCarrier.ntc,
  '976': NepalCarrier.ntc,
  '980': NepalCarrier.ncell,
  '981': NepalCarrier.ncell,
  '982': NepalCarrier.ncell,
  '970': NepalCarrier.ncell,
  '971': NepalCarrier.ncell,
  '961': NepalCarrier.smart,
  '962': NepalCarrier.smart,
  '988': NepalCarrier.smart,
  '972': NepalCarrier.utl,
  '963': NepalCarrier.hello,
};

/// Why a phone number was rejected.
enum PhoneError {
  /// Nothing was typed.
  empty,

  /// Something other than digits, spaces, `+`, `-`, `.` or brackets.
  invalidCharacters,

  /// An international number for a country other than Nepal (+977).
  notNepal,

  /// The wrong number of digits.
  wrongLength,

  /// A 10-digit number starting with 9 whose prefix is not allocated to
  /// a mobile carrier.
  unknownPrefix,

  /// A mobile number of a carrier that no longer operates (allowed with
  /// `allowInactive: true`).
  inactiveCarrier,

  /// A landline, where only mobile numbers are accepted.
  landlineNotAllowed,
}

/// The result of [NepaliPhone.validate]: the number, or why not.
class PhoneValidation {
  const PhoneValidation._(this.phone, this.error);

  /// The parsed number, when valid.
  final NepaliPhone? phone;

  /// Why the input was rejected, when invalid.
  final PhoneError? error;

  /// Whether the input is a usable number.
  bool get isValid => phone != null;
}

/// A Nepali phone number.
///
/// [nsn] is the national significant number, the digits after +977: ten
/// digits for a mobile (`9841234567`), eight for a landline (`14123456`
/// is Kathmandu 01-4123456).
class NepaliPhone {
  const NepaliPhone._(this.nsn, this.carrier);

  /// Digits after +977.
  final String nsn;

  /// The carrier, or [NepalCarrier.landline].
  final NepalCarrier carrier;

  /// Whether this is a mobile number.
  bool get isMobile => carrier != NepalCarrier.landline;

  /// `+9779841234567`. Store and send this form.
  String get e164 => '+977$nsn';

  /// How it is dialled inside Nepal: `9841234567`, `01-4123456`,
  /// `061-123456`.
  String get national {
    if (isMobile) return nsn;
    if (nsn.startsWith('1')) return '01-${nsn.substring(1)}';
    return '0${nsn.substring(0, 2)}-${nsn.substring(2)}';
  }

  /// Display form: `984-1234567` or `01-4123456`, with Devanagari digits
  /// when [devanagari]. Pass [international] for `+977 984-1234567`.
  String format({bool international = false, bool devanagari = false}) {
    final body = isMobile
        ? '${nsn.substring(0, 3)}-${nsn.substring(3)}'
        : national;
    final s = international
        ? '+977 ${isMobile ? body : body.substring(1)}'
        : body;
    return devanagari ? toDevanagariDigits(s) : s;
  }

  /// `tel:+9779841234567`.
  Uri get telUri => Uri(scheme: 'tel', path: e164);

  /// `sms:+9779841234567`, with [body] when given.
  Uri smsUri({String? body}) => Uri(
    scheme: 'sms',
    path: e164,
    query: body == null ? null : 'body=${Uri.encodeComponent(body)}',
  );

  /// `https://wa.me/9779841234567`.
  Uri get whatsAppUri => Uri.parse('https://wa.me/977$nsn');

  /// Parses [input], or returns null; see [validate].
  static NepaliPhone? tryParse(
    String input, {
    bool mobileOnly = false,
    bool allowInactive = false,
  }) => validate(
    input,
    mobileOnly: mobileOnly,
    allowInactive: allowInactive,
  ).phone;

  /// Validates typed text.
  ///
  /// Accepts Western or Devanagari digits, with spaces, dashes, dots and
  /// brackets ignored, and these forms:
  ///
  /// - mobile: `9841234567`, `09841234567`, `+977 984-1234567`,
  ///   `977 9841234567`, `00977 9841234567`;
  /// - landline: `01-4123456`, `061-123456`, `+977 1 4123456`.
  ///
  /// Mobiles must have a known prefix; carriers that stopped operating are
  /// rejected unless [allowInactive]. Landlines are rejected when
  /// [mobileOnly].
  static PhoneValidation validate(
    String input, {
    bool mobileOnly = false,
    bool allowInactive = false,
  }) {
    PhoneValidation fail(PhoneError e) => PhoneValidation._(null, e);
    var s = toLatinDigits(input).replaceAll(RegExp(r'[\s\-.()]'), '');
    if (s.isEmpty) return fail(PhoneError.empty);
    if (!RegExp(r'^\+?\d+$').hasMatch(s)) {
      return fail(PhoneError.invalidCharacters);
    }
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    String nsn;
    if (s.startsWith('+')) {
      if (!s.startsWith('+977')) return fail(PhoneError.notNepal);
      nsn = s.substring(4);
      if (nsn.startsWith('0')) nsn = nsn.substring(1);
    } else if (s.startsWith('977') && (s.length == 13 || s.length == 11)) {
      nsn = s.substring(3);
    } else if (s.startsWith('0')) {
      nsn = s.substring(1);
    } else {
      nsn = s;
    }

    if (nsn.startsWith('9')) {
      if (nsn.length != 10) return fail(PhoneError.wrongLength);
      final carrier = _mobilePrefixes[nsn.substring(0, 3)];
      if (carrier == null) return fail(PhoneError.unknownPrefix);
      if (!carrier.isActive && !allowInactive) {
        return fail(PhoneError.inactiveCarrier);
      }
      return PhoneValidation._(NepaliPhone._(nsn, carrier), null);
    }
    if (nsn.length != 8 || !RegExp(r'^[1-8]').hasMatch(nsn)) {
      return fail(PhoneError.wrongLength);
    }
    if (mobileOnly) return fail(PhoneError.landlineNotAllowed);
    return PhoneValidation._(NepaliPhone._(nsn, NepalCarrier.landline), null);
  }

  @override
  bool operator ==(Object other) => other is NepaliPhone && other.nsn == nsn;

  @override
  int get hashCode => nsn.hashCode;

  @override
  String toString() => e164;
}

/// [input] as E.164 (`+9779841234567`), or null when it is not a valid
/// Nepali mobile number.
String? normalizeNepaliMobile(String input) =>
    NepaliPhone.tryParse(input, mobileOnly: true)?.e164;

/// Whether [input] is a valid Nepali mobile number.
bool isValidNepaliMobile(String input) => normalizeNepaliMobile(input) != null;
