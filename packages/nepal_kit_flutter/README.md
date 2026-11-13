# nepal_kit_flutter

Flutter widgets for [`nepal_kit`](https://pub.dev/packages/nepal_kit):

- a Bikram Sambat date picker and month calendar;
- receipt and invoice preview, print and share, with correctly shaped
  Devanagari;
- a localizations delegate for ne/en.

It re-exports `nepal_kit`, so one import gives you dates, money, phone
numbers, address data and SMS reminders as well.

Everything is built on `package:flutter/widgets.dart` only, so it works in
apps on Flutter's Material, on `package:material_ui`, on Cupertino, or on a
custom design system. Style it with `NepalKitTheme`.

```yaml
dependencies:
  nepal_kit_flutter: ^0.1.0
```

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

## Example app

```sh
flutter pub get
cd example && flutter run            # or: flutter build web, then open ?tab=receipt&lang=ne
```

It has tabs for Dates, Money, Phone, Address (cascading pickers), Receipt
(preview, print, share, 80 mm) and SMS (mock gateway and scheduler).


## More

The source, an example app and the full documentation are at
https://github.com/lohanidamodar/nepal-kit. Licensed under MIT; the bundled
Noto Sans Devanagari fonts are under the SIL Open Font License.
