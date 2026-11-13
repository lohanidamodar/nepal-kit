import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:nepal_kit/fonts_io.dart';
import 'package:nepal_kit/nepal_kit.dart';
import 'package:pdf/pdf.dart';
import 'package:test/test.dart';

ReceiptDocument _doc({
  NepalKitLanguage language = NepalKitLanguage.en,
  VatRule vat = VatRule.nepalStandard,
  Npr discount = Npr.zero,
  Npr paid = Npr.zero,
  ReceiptStatus status = ReceiptStatus.issued,
  int lines = 3,
}) => ReceiptDocument(
  kind: ReceiptKind.taxInvoice,
  number: 'INV-0042',
  issuedAt: DateTime(2024, 4, 17),
  dueAt: DateTime(2024, 5, 1),
  business: const ReceiptParty(
    name: 'हिमाल हार्डवेयर',
    address: 'Baneshwor, Kathmandu',
    phone: '01-4123456',
    pan: '301234567',
  ),
  customer: const ReceiptParty(
    name: 'राम श्रेष्ठ',
    phone: '9841234567',
    pan: '609876543',
  ),
  lines: [
    for (var i = 0; i < lines; i++)
      i % 3 == 0
          ? ReceiptLine('पेन्ट (४ लिटर)', const Npr.rupees(2450), quantity: 2)
          : i % 3 == 1
          ? ReceiptLine.fractional(
              'Putty',
              const Npr.rupees(120, 50),
              quantityMilli: 1500,
              unit: 'kg',
            )
          : ReceiptLine('Brush', const Npr.rupees(85)),
  ],
  discount: discount,
  vat: vat,
  paid: paid,
  status: status,
  notes: 'सामान फिर्ता ७ दिनभित्र मात्र।',
  footer: 'Thank you!',
  language: language,
);

class _FakeRasterizer implements TextRasterizer {
  final List<String> seen = [];

  // A 1x1 transparent PNG.
  static final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  );

  @override
  Future<RasterText> rasterize(
    String text, {
    required double fontSize,
    required bool bold,
    required int color,
    double? maxWidth,
  }) async {
    seen.add(text);
    return RasterText(
      Uint8List.fromList(_png),
      text.length * fontSize * 0.5,
      fontSize * 1.4,
    );
  }
}

void main() {
  group('totals', () {
    test('lines, discount, VAT on top, paid and balance', () {
      final t = _doc(
        discount: const Npr.rupees(100),
        paid: const Npr.rupees(3000),
      ).totals;
      // 2 × 2450 + 1.5 × 120.50 + 85 = 4900 + 180.75 + 85
      expect(t.subtotal, const Npr.rupees(5165, 75));
      expect(t.discount, const Npr.rupees(100));
      expect(t.taxable, const Npr.rupees(5065, 75));
      expect(t.vat, const Npr(65855)); // 13% of 5065.75 = 658.5475 -> 658.55
      expect(t.total, const Npr(572430));
      expect(t.balance, const Npr(272430));
    });

    test('VAT-inclusive prices', () {
      final t = _doc(vat: const VatRule(rateBp: 1300, inclusive: true)).totals;
      expect(t.total, t.subtotal);
      expect(t.taxable + t.vat, t.total);
    });

    test('discount is capped at the subtotal, balance never negative', () {
      final t = _doc(
        discount: const Npr.rupees(999999),
        paid: const Npr.rupees(1),
      ).totals;
      expect(t.total, Npr.zero);
      expect(t.balance, Npr.zero);
    });

    test('fractional quantities print trimmed', () {
      expect(
        ReceiptLine.fractional('x', Npr.zero, quantityMilli: 1500).quantityText,
        '1.5',
      );
      expect(
        ReceiptLine.fractional('x', Npr.zero, quantityMilli: 250).quantityText,
        '0.25',
      );
      expect(ReceiptLine('x', Npr.zero, quantity: 3).quantityText, '3');
    });
  });

  group('PDF', () {
    late ReceiptFonts fonts;
    setUpAll(() async => fonts = await loadBundledReceiptFonts());

    test('builds a PDF, English labels, without a rasterizer', () async {
      final bytes = await buildReceiptPdf(_doc(), fonts: fonts);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(
        bytes.length,
        greaterThan(10000),
      ); // the Devanagari font is embedded
    });

    test('Nepali, paid stamp, 80 mm roll, many lines (multi-page)', () async {
      for (final format in [
        PdfPageFormat.a4,
        PdfPageFormat.a5,
        PdfPageFormat.roll80,
      ]) {
        final bytes = await buildReceiptPdf(
          _doc(
            language: NepalKitLanguage.ne,
            status: ReceiptStatus.paid,
            lines: 60,
          ),
          fonts: fonts,
          pageFormat: format,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      }
    });

    test(
      'with a rasterizer every Devanagari string goes through it once',
      () async {
        final r = _FakeRasterizer();
        final bytes = await buildReceiptPdf(
          _doc(language: NepalKitLanguage.ne),
          fonts: fonts,
          rasterizer: r,
        );
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        expect(r.seen, contains('हिमाल हार्डवेयर'));
        expect(r.seen, contains('पेन्ट (४ लिटर)'));
        expect(
          r.seen.any((s) => s.contains('रुपैयाँ')),
          isTrue,
        ); // amount in words
        expect(
          r.seen.toSet().length,
          r.seen.length,
          reason: 'each string once',
        );
        expect(r.seen.every(hasDevanagari), isTrue, reason: 'Latin stays text');
      },
    );

    test('writes a sample when NEPAL_KIT_SAMPLE_DIR is set', () async {
      final dir = Platform.environment['NEPAL_KIT_SAMPLE_DIR'];
      if (dir == null) return;
      for (final l in NepalKitLanguage.values) {
        File('$dir/receipt-${l.name}.pdf').writeAsBytesSync(
          await buildReceiptPdf(_doc(language: l), fonts: fonts),
        );
      }
    });
  });
}
