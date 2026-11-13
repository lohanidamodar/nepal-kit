# nepal_kit

Shared building blocks for Nepal small-business apps: Bikram Sambat dates,
Nepali numbers and NPR money, amounts in words, VAT, phone numbers, address
data, receipt and invoice PDFs, SMS reminders through Sandesh, and ne/en
strings.

| Package | Depends on | For |
| --- | --- | --- |
| [`nepal_kit`](packages/nepal_kit) | `pdf`, `http`, `crypto` (pure Dart) | Servers, CLIs, Appwrite functions and Flutter apps |
| [`nepal_kit_flutter`](packages/nepal_kit_flutter) | `nepal_kit`, `printing`, Flutter **widgets layer only** | BS date picker, month calendar, receipt preview / print / share |

`nepal_kit_flutter` imports only `package:flutter/widgets.dart`. It works in
apps on Flutter's Material, on `package:material_ui` (Bhadama, Sandesh,
Tipot), on Cupertino, or on a custom design system. It re-exports
`nepal_kit`.

Install from pub.dev:

```yaml
dependencies:
  nepal_kit: ^0.1.0          # pure Dart
  nepal_kit_flutter: ^0.1.0  # Flutter widgets; re-exports nepal_kit
```

Dart SDK `^3.12.0`. The minimum comes from `pdf` 3.13.

## Dates (Bikram Sambat)

```dart
import 'package:nepal_kit/nepal_kit.dart';

final d = BsDate.fromAd(DateTime(2025, 4, 14));      // 2082-01-01
d.toAd();                                           // 2025-04-14 UTC midnight
BsDate(2081, 2, 32).addMonths(1);                   // 2081-03-31 (clamped)
BsDate.today();                                     // today in Nepal (UTC+05:45)
BsDate.parse('२०८१-०१-१५');

NepaliDateFormat.full(NepalKitLanguage.ne).formatBs(d);   // सोमबार, १ बैशाख २०८२
NepaliDateFormat('d MMMM yyyy G').formatBs(d);            // 1 Baishakh 2082 BS
NepaliDateFormat('d MMMM yyyy', language: NepalKitLanguage.ne)
    .formatAd(DateTime(2025, 4, 14));                       // १४ अप्रिल २०२५
BsMonthGrid(2081, 1).weeks;                               // calendar rows, Sunday first
```

- **Range:** BS 1970–2100 (AD 13 April 1913 to April 2044). Outside that
  range, conversion throws a `RangeError`.
- **Time zones:** `fromAd` reads only the calendar fields of the `DateTime`
  you pass, and `toAd` returns UTC midnight, so no time-zone shift can move
  a date by a day. That shift is the `nepali_utils` bug Sambandha works
  around.

### Where the calendar data comes from, and how it is checked

The month table is lifted from sabdabhandar (`lib/utils/bikram_sambat.dart`).
For every month of BS 1970–2100 it agrees exactly with:

- Tipot's table (`lib/core/util/nepali_date.dart`, which covers 2000–2100);
- the `nepali_utils` package.

`test/bs_date_test.dart` pins the data in three ways:

- **Year lengths:** every year's length matches the ahargana (day-count)
  column of flutter_astrology_calc's Calendar table. That table is an
  independent source, copied into `test/fixtures/ahargana.dart`.
- **Known dates:** ten anchors, from the 1970 epoch through the New Years
  of 2080–2083, Constitution Day, Republic Day and others.
- **Round trip:** every one of the roughly 47,800 days round-trips without
  a gap.

flutter_astrology_calc's Calendar table spreads days across months
differently. It is an astrological solar-month table, not the civil patro,
so only its year lengths are used.

## Numbers and money

```dart
groupLakh(12345678);                 // 1,23,45,678
toDevanagariDigits('2081');          // २०८१
const rent = Npr.rupees(15000);      // stored as 1500000 paisa
rent.format();                       // Rs. 15,000
rent.format(symbol: NprSymbol.rupee, devanagari: true);  // रु १५,०००
Npr.parse('रु १,२५०.५०');            // 125050 paisa
rent.split(3);                       // [5000.00, 5000.00, 5000.00], exact to the paisa
rent.inWords();                      // Rupees fifteen thousand only
rent.inWords(language: AmountWordsLanguage.ne);  // पन्ध्र हजार रुपैयाँ मात्र
numberInWords(1250000000, language: AmountWordsLanguage.ne);  // एक अर्ब पच्चीस करोड
applyVat(const Npr.rupees(1000), VatRule.nepalStandard).total; // Rs. 1,130
```

- **Money:** always integer paisa. `times` and `percent` round half away
  from zero. `allocate` and `split` always add back up to the original
  amount.
- **Number words:** English uses the lakh and crore scale. Nepali goes on to
  अर्ब (arba) and खर्ब (kharba).

## Phone numbers

```dart
final p = NepaliPhone.tryParse('+977 984-1234567')!;
p.e164;           // +9779841234567  (store this)
p.format();       // 984-1234567
p.carrier;        // NepalCarrier.ntc
normalizeNepaliMobile('९८४१२३४५६७');      // +9779841234567
NepaliPhone.validate('9901234567').error;  // PhoneError.unknownPrefix
NepaliPhone.tryParse('01-4123456')!.e164;  // +97714123456 (landline)
```

**Prefixes:**

| Carrier | Prefixes |
| --- | --- |
| NTC | 984, 985, 986, 974, 975, 976 |
| Ncell | 980, 981, 982, 970, 971 (971 opened in 2025) |

The Smart (961, 962, 988), UTL (972) and Hello (963) ranges are rejected
unless you pass `allowInactive`. Nepal has no number portability yet, so the
prefix still identifies the carrier. The list comes from operator and
trade-press reports; I found no official NTA list. The error messages are
in `NepalKitStrings.*.phoneErrors`.

## Address data

```dart
NepalAddress.provinces;                         // 7
NepalAddress.districtsOf(3);                    // Bagmati's 13
NepalAddress.localLevelsOf(districtId);         // its municipalities
NepalAddress.searchLocalLevels('पोखरा');         // Pokhara Metropolitan City first
NepaliAddress(localLevel: l, ward: 10, district: d).format(nepali: true);
```

The package has 7 provinces, 77 districts and 753 local levels: 6
metropolitan cities, 11 sub-metropolitan cities, 276 municipalities and 460
rural municipalities. Each has English and Nepali names and a ward count.

The data comes from
[sagautam5/local-states-nepal](https://github.com/sagautam5/local-states-nepal)
(MIT). A copy is in `tool/data/` and `dart run tool/gen_address_data.dart`
regenerates the Dart file from it. The generator also fixes vowel signs that
the dataset types in two parts.

## Receipt and invoice PDF

```dart
final doc = ReceiptDocument(
  kind: ReceiptKind.taxInvoice,
  number: 'INV-0042',
  issuedAt: DateTime.now(),
  business: const ReceiptParty(name: 'हिमाल हार्डवेयर', pan: '301234567'),
  customer: const ReceiptParty(name: 'राम श्रेष्ठ', phone: '984-1234567'),
  lines: [ReceiptLine('पेन्ट', const Npr.rupees(2450), quantity: 2)],
  vat: VatRule.nepalStandard,
  language: NepalKitLanguage.ne,
);
doc.totals;                        // subtotal, discount, taxable, vat, total, balance

// Flutter (nepal_kit_flutter):
await printReceipt(doc);           // system print dialog
await shareReceipt(doc);           // share sheet, INV-0042.pdf
ReceiptPreview(doc: doc);          // pages as images, no Material needed
final bytes = await buildReceiptPdfFlutter(doc, pageFormat: PdfPageFormat.roll80);

// Server / CLI (pure Dart):
import 'package:nepal_kit/fonts_io.dart';
final pdf = await buildReceiptPdf(doc, fonts: await loadBundledReceiptFonts());
```

The PDF can carry:

- a logo;
- business and customer blocks with PAN and VAT numbers;
- the BS and AD dates and a due date;
- a lines table with fractional quantities and units;
- subtotal, discount, taxable amount, VAT (exclusive or inclusive), total,
  paid and balance;
- the amount in words;
- notes, a signature line, and a PAID or CANCELLED stamp.

Page sizes are A4 and A5, plus a compact layout for 80 mm thermal rolls.
The layout follows Achiver's `InvoicePdfService`.

**Devanagari in PDFs.** The `pdf` package has no Indic shaping. If you set
Devanagari as plain PDF text, conjuncts, reph and the i-matra come out wrong:
बिजक prints as "बजिक" and श्रेष्ठ shows a loose halant. With a `TextRasterizer`, every
Devanagari string is drawn by Flutter's text engine and embedded as a
roughly 290 dpi image, and the output is correct (checked by eye in the
example app). Latin text and numbers stay real PDF text.

- **Flutter:** `nepal_kit_flutter` does this automatically.
- **Servers:** without Flutter there is no rasteriser yet. Use English
  labels, or accept the broken joins.

The PDF embeds Noto Sans Devanagari regular and bold under the SIL Open
Font License (`packages/nepal_kit/lib/fonts/OFL.txt`).

## SMS reminders

```dart
final gateway = SandeshSmsGateway(
  baseUrl: Uri.parse('https://192.168.1.20:8443'),
  apiKey: 'snd_…',                                   // sms:send scope
  client: sandeshPinnedClient(fingerprint),          // package:nepal_kit/sandesh_io.dart
);
// or MockSmsGateway() in tests and demos

final text = ReminderTemplates.render(ReminderKind.rentDue,
    language: NepalKitLanguage.ne, name: 'हरि', business: 'सजिलो रेन्ट',
    amount: const Npr.rupees(15000), date: BsDate(2081, 5, 1));
// आदरणीय हरि, तपाईंको रु १५,००० भाडा १ भदौ २०८१ मा बुझाउनुपर्ने छ। - सजिलो रेन्ट

final scheduler = ReminderScheduler(gateway: gateway, store: myStore);
await scheduler.schedule(Reminder(id: 'rent-42', to: '9841234567', body: text, sendAt: due));
await scheduler.dispatchDue();      // from a timer, WorkManager, app start or a cron
await gateway.sendBulk('Hi {name}, …', recipients);   // a Sandesh bulk job
```

- **API calls:** `SmsGateway` is the interface. `SandeshSmsGateway` calls
  Sandesh's `POST /api/v1/messages` and `POST /api/v1/jobs` and maps its
  error envelope.
- **Templates:** placeholders use Sandesh's `{placeholder}` syntax. The
  renderer is lifted from `sandesh_api`, so a preview here matches what the
  phone sends.
- **Scheduling:** Sandesh has no scheduled sends, so `ReminderScheduler`
  holds reminders on the client and retries failures. Back it with your
  database through `ReminderStore`.
- **Built-in wording:** reminder texts for rent due, udhaaro and
  appointments, in English and Nepali.

## Localisation

`NepalKitStrings.en` and `NepalKitStrings.ne` are plain Dart, so servers can
use them too. They cover:

- month and weekday names (BS and AD);
- era names;
- picker labels;
- phone errors;
- receipt labels.

In Flutter, add `NepalKitLocalizations.delegate`. Alternatively, wrap a
subtree in `NepalKitLanguageScope` to set the language apart from the app
locale, for example behind a "dates in Nepali" switch, or in apps without
Nepali Material localizations.

## Widgets

```dart
final picked = await showBsDatePicker(context: context, initialDate: BsDate.today());
BsMonthCalendar(month: m, selected: d, markedDates: dueDates,
    onDateSelected: …, onMonthChanged: …);
NepalKitTheme(data: NepalKitThemeData(primary: scheme.primary, …), child: …);
```

**The date picker:**

- shows each day's AD date in small type;
- marks Saturdays in the holiday colour;
- has a month and year chooser and a Today button;
- has semantics labels for each day ("Wednesday, 5 Baishakh 2081");
- accepts min and max bounds.

## Example app

```sh
flutter pub get
cd example && flutter run            # or: flutter build web, then open ?tab=receipt&lang=ne
```

It has tabs for Dates, Money, Phone, Address (cascading pickers), Receipt
(preview, print, share, 80 mm) and SMS (mock gateway and scheduler).

## What was reused

| From | What |
| --- | --- |
| sabdabhandar `utils/bikram_sambat.dart` | BS month table (cross-checked against Tipot, `nepali_utils` and flutter_astrology_calc) |
| flutter_astrology_calc `classic_siddhanta` Calendar table | Ahargana year lengths, used as independent test evidence |
| Tipot `feat/receipts` `domain/money.dart`, `amount_words.dart`, `vat.dart` and tests | Digits, lakh grouping, paisa parsing and formatting, number words, VAT |
| Sandesh `sandesh_api` `template.dart`, `phone.dart`, `docs/api.md` | Template renderer, phone input clean-up, API shape and certificate pinning |
| Achiver `invoice_pdf_service.dart` | PDF layout |
| Moksha `assets/fonts` | Noto Sans Devanagari 400 and 700 |
| sagautam5/local-states-nepal (MIT) | Provinces, districts and local levels |

## Development

```sh
flutter pub get
cd packages/nepal_kit && dart analyze && dart test
cd packages/nepal_kit_flutter && flutter analyze && flutter test
```

## Releasing

Releases go to pub.dev from GitHub Actions (automated publishing) when a
tag is pushed:

1. Bump `version` in the package's `pubspec.yaml` and add a `CHANGELOG.md`
   entry, then commit.
2. Tag and push: `git tag nepal_kit-v0.1.1 && git push origin nepal_kit-v0.1.1`
   (or `nepal_kit_flutter-v…`). Release `nepal_kit` first when both change.

## License

MIT, see [LICENSE](LICENSE). The bundled Noto Sans Devanagari fonts are
under the SIL Open Font License; the address data is MIT
(sagautam5/local-states-nepal).
