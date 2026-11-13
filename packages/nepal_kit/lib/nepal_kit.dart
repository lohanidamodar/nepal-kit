/// Building blocks for Nepal small-business apps, in pure Dart (servers,
/// CLIs, Flutter): Bikram Sambat dates, Nepali numbers and NPR money,
/// amount in words, VAT, phone numbers, address data, receipt PDFs, SMS
/// reminders and ne/en strings.
///
/// `dart:io`-only extras: `package:nepal_kit/sandesh_io.dart` (pinned
/// HTTPS client for Sandesh) and `package:nepal_kit/fonts_io.dart`.
/// Flutter widgets: `package:nepal_kit_flutter`.
library;

export 'src/address/address.dart';
export 'src/date/bs_date.dart';
export 'src/date/bs_month.dart';
export 'src/date/date_format.dart';
export 'src/l10n/strings.dart';
export 'src/number/amount_words.dart';
export 'src/number/digits.dart';
export 'src/number/npr.dart';
export 'src/number/vat.dart';
export 'src/phone/nepali_phone.dart';
export 'src/receipt/receipt.dart';
export 'src/receipt/receipt_pdf.dart';
export 'src/sms/reminders.dart';
export 'src/sms/sms_gateway.dart';
export 'src/sms/template.dart';
