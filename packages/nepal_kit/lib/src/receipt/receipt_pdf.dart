// Receipt / invoice PDF.
//
// The layout (header with stamp, from / bill-to blocks, line table, totals
// box, notes) follows Achiver's InvoicePdfService (achiver: lib/features/
// invoices/data/invoice_pdf_service.dart), extended with a logo, PAN/VAT
// fields, BS and AD dates, amount in words and Devanagari.
//
// Devanagari: the `pdf` package writes glyphs one by one and has no Indic
// shaping, so conjuncts (क्ष, त्र), reph (र्क) and the i-matra (कि) come out
// wrong when Devanagari is set as PDF text. Pass a [TextRasterizer] (the
// Flutter one is in nepal_kit_flutter) and every string containing
// Devanagari is drawn by the platform's text engine and embedded as a
// high-resolution image. Without one, Devanagari is set as text with the
// bundled Noto Sans Devanagari: every letter is there, but joined forms
// are not.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../date/bs_date.dart';
import '../date/date_format.dart';
import '../l10n/strings.dart';
import '../number/amount_words.dart';
import '../number/digits.dart';
import '../number/npr.dart';
import '../number/vat.dart';
import 'receipt.dart';

/// Fonts for [buildReceiptPdf].
class ReceiptFonts {
  /// Noto Sans Devanagari regular and bold, as loaded TTF bytes. Latin text
  /// uses the PDF base font Helvetica.
  ReceiptFonts({required ByteData devanagari, required ByteData devanagariBold})
    : devanagari = pw.Font.ttf(devanagari),
      devanagariBold = pw.Font.ttf(devanagariBold);

  /// Devanagari, regular.
  final pw.Font devanagari;

  /// Devanagari, bold.
  final pw.Font devanagariBold;

  /// Asset paths of the bundled fonts, for
  /// `rootBundle.load(ReceiptFonts.regularAsset)` in Flutter.
  static const String regularAsset =
      'packages/nepal_kit/lib/fonts/NotoSansDevanagari-Regular.ttf';

  /// See [regularAsset].
  static const String boldAsset =
      'packages/nepal_kit/lib/fonts/NotoSansDevanagari-Bold.ttf';
}

/// A line of text drawn as an image, sized in PDF points.
class RasterText {
  /// [png] bytes showing the text at [width] × [height] points.
  const RasterText(this.png, this.width, this.height);

  /// PNG image.
  final Uint8List png;

  /// Width, points.
  final double width;

  /// Height, points.
  final double height;
}

/// Draws text with a real text engine (HarfBuzz in Flutter), so Devanagari
/// shapes correctly in the PDF.
abstract interface class TextRasterizer {
  /// Draws [text] at [fontSize] points in [color] (0xAARRGGBB). Wraps at
  /// [maxWidth] points when given.
  Future<RasterText> rasterize(
    String text, {
    required double fontSize,
    required bool bold,
    required int color,
    double? maxWidth,
  });
}

/// Builds the PDF of [doc].
///
/// [pageFormat] defaults to A4; [PdfPageFormat.roll80] gives a narrow
/// layout for 80 mm thermal printers.
Future<Uint8List> buildReceiptPdf(
  ReceiptDocument doc, {
  required ReceiptFonts fonts,
  TextRasterizer? rasterizer,
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) async {
  final layout = _ReceiptLayout(doc, fonts, pageFormat);
  if (rasterizer != null) {
    // First pass: find the Devanagari strings the layout will draw.
    layout.collecting = true;
    layout.content();
    layout.collecting = false;
    for (final k in layout.wanted) {
      layout.images[k] = await rasterizer.rasterize(
        k.text,
        fontSize: k.size,
        bold: k.bold,
        color: k.color,
        maxWidth: k.maxWidth,
      );
    }
  }
  final pdf = pw.Document(
    title: '${layout.title} ${doc.number}',
    author: doc.business.name,
    creator: 'nepal_kit',
  );
  final theme = pw.ThemeData.withFont(
    base: pw.Font.helvetica(),
    bold: pw.Font.helveticaBold(),
    fontFallback: [fonts.devanagari],
  );
  final margin = layout.compact
      ? const pw.EdgeInsets.all(10)
      : const pw.EdgeInsets.all(36);
  if (pageFormat.height == double.infinity) {
    // A roll: one page as long as the receipt.
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: margin,
        theme: theme,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: layout.content(),
        ),
      ),
    );
  } else {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: margin,
        theme: theme,
        footer: layout.compact ? null : layout.footer,
        build: (_) => layout.content(),
      ),
    );
  }
  return pdf.save();
}

class _Key {
  const _Key(this.text, this.size, this.bold, this.color, this.maxWidth);
  final String text;
  final double size;
  final bool bold;
  final int color;
  final double? maxWidth;

  @override
  bool operator ==(Object o) =>
      o is _Key &&
      o.text == text &&
      o.size == size &&
      o.bold == bold &&
      o.color == color &&
      o.maxWidth == maxWidth;

  @override
  int get hashCode => Object.hash(text, size, bold, color, maxWidth);
}

class _ReceiptLayout {
  _ReceiptLayout(this.doc, this.fonts, this.format)
    : s = NepalKitStrings.of(doc.language).receipt,
      ne = doc.language == NepalKitLanguage.ne,
      compact = format.width < 300,
      totals = doc.totals;

  final ReceiptDocument doc;
  final ReceiptFonts fonts;
  final PdfPageFormat format;
  final ReceiptStrings s;
  final bool ne;
  final bool compact;
  final ReceiptTotals totals;

  bool collecting = false;
  final Set<_Key> wanted = {};
  final Map<_Key, RasterText> images = {};

  static const _grey = 0xFF616161;
  static const _black = 0xFF000000;

  double get _contentWidth => format.width - (compact ? 20 : 72);

  String get title => switch (doc.kind) {
    ReceiptKind.receipt => s.receipt,
    ReceiptKind.invoice => s.invoice,
    ReceiptKind.taxInvoice => s.taxInvoice,
    ReceiptKind.estimate => s.estimate,
  };

  String _money(Npr v) => v.format(
    symbol: NprSymbol.none,
    devanagari: ne,
    paisaDisplay: PaisaDisplay.always,
  );

  String _num(String v) => ne ? toDevanagariDigits(v) : v;

  /// A text run: an image when Devanagari and a rasterizer is in use,
  /// otherwise PDF text.
  pw.Widget t(
    String text, {
    double size = 10,
    bool bold = false,
    int color = _black,
    double? maxWidth,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    if (hasDevanagari(text)) {
      final k = _Key(text, size, bold, color, maxWidth);
      if (collecting) {
        wanted.add(k);
        return pw.SizedBox();
      }
      final img = images[k];
      if (img != null) {
        // Never wider than the space it is given: scale down, keep aspect.
        return pw.ConstrainedBox(
          constraints: pw.BoxConstraints(
            maxWidth: img.width,
            maxHeight: img.height,
          ),
          child: pw.Image(pw.MemoryImage(img.png), fit: pw.BoxFit.contain),
        );
      }
    }
    return pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: PdfColor.fromInt(color),
        font: hasDevanagari(text)
            ? (bold ? fonts.devanagariBold : fonts.devanagari)
            : null,
        fontFallback: [fonts.devanagari],
      ),
    );
  }

  List<pw.Widget> content() => [
    _header(),
    pw.SizedBox(height: compact ? 8 : 18),
    _parties(),
    pw.SizedBox(height: compact ? 8 : 18),
    _lines(),
    pw.SizedBox(height: 10),
    _totals(),
    if (doc.showAmountInWords) ...[pw.SizedBox(height: 8), _inWords()],
    if (doc.notes != null && doc.notes!.trim().isNotEmpty) ...[
      pw.SizedBox(height: 14),
      t(s.notes.toUpperCase(), size: 8, bold: true, color: _grey),
      pw.SizedBox(height: 2),
      t(doc.notes!.trim(), size: 9, maxWidth: _contentWidth),
    ],
    if (doc.signatureLine && !compact) ...[
      pw.SizedBox(height: 40),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 160,
            padding: const pw.EdgeInsets.only(top: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
            ),
            child: pw.Center(child: t(s.signature, size: 9, color: _grey)),
          ),
        ],
      ),
    ],
    if (compact && doc.footer != null) ...[
      pw.SizedBox(height: 10),
      pw.Center(child: t(doc.footer!, size: 8, maxWidth: _contentWidth)),
    ],
  ];

  pw.Widget footer(pw.Context ctx) => pw.Column(
    children: [
      if (doc.footer != null && ctx.pageNumber == ctx.pagesCount)
        pw.Center(
          child: t(doc.footer!, size: 9, color: _grey, maxWidth: _contentWidth),
        ),
      if (ctx.pagesCount > 1)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
    ],
  );

  List<String> _dates(DateTime d) {
    final bs = BsDate.fromAd(d);
    return [
      if (doc.showBsDate)
        '${NepaliDateFormat.numeric(doc.language).formatBs(bs)} ${ne ? 'वि.सं.' : 'BS'}',
      if (doc.showAdDate)
        '${NepaliDateFormat('yyyy-MM-dd', language: doc.language).formatAd(d)} ${ne ? 'ई.सं.' : 'AD'}',
    ];
  }

  pw.Widget _business() {
    final b = doc.business;
    return pw.Column(
      crossAxisAlignment: compact
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.start,
      children: [
        if (doc.logo != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Image(
              pw.MemoryImage(doc.logo!),
              height: compact ? 32 : 48,
            ),
          ),
        t(b.name, size: compact ? 12 : 15, bold: true),
        if (b.address != null) t(b.address!, size: 9),
        if (b.phone != null) t('${s.phone}: ${_num(b.phone!)}', size: 9),
        if (b.email != null) t(b.email!, size: 9),
        ..._taxIds(b, size: 9),
      ],
    );
  }

  List<pw.Widget> _taxIds(ReceiptParty p, {required double size}) => [
    if (p.pan != null) t('${s.pan}: ${_num(p.pan!)}', size: size),
    if (p.vatNumber != null && p.vatNumber != p.pan)
      t('${s.vatNo}: ${_num(p.vatNumber!)}', size: size),
  ];

  pw.Widget _stamp(String label, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: color, width: 1.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: t(label, size: 12, bold: true, color: color.toInt()),
  );

  pw.Widget _header() {
    final meta = pw.Column(
      crossAxisAlignment: compact
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.end,
      children: [
        t(title.toUpperCase(), size: compact ? 13 : 22, bold: true),
        pw.SizedBox(height: 2),
        t('${s.number} ${_num(doc.number)}', size: 10),
        for (final d in _dates(doc.issuedAt)) t('${s.date}: $d', size: 9),
        if (doc.dueAt != null)
          for (final d in _dates(doc.dueAt!).take(1))
            t('${s.dueDate}: $d', size: 9),
        if (doc.status == ReceiptStatus.paid &&
            doc.kind != ReceiptKind.estimate) ...[
          pw.SizedBox(height: 4),
          _stamp(s.paidStamp, PdfColors.green700),
        ],
        if (doc.status == ReceiptStatus.cancelled) ...[
          pw.SizedBox(height: 4),
          _stamp(s.cancelledStamp, PdfColors.red700),
        ],
      ],
    );
    if (compact) {
      return pw.Column(children: [_business(), pw.Divider(), meta]);
    }
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: _business()),
        pw.SizedBox(width: 16),
        meta,
      ],
    );
  }

  pw.Widget _parties() {
    final c = doc.customer;
    if (c == null) return pw.SizedBox();
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          t(s.billTo.toUpperCase(), size: 8, bold: true, color: _grey),
          pw.SizedBox(height: 2),
          t(c.name, size: 11, bold: true),
          if (c.address != null) t(c.address!, size: 9),
          if (c.phone != null) t('${s.phone}: ${_num(c.phone!)}', size: 9),
          if (c.email != null) t(c.email!, size: 9),
          ..._taxIds(c, size: 9),
        ],
      ),
    );
  }

  pw.Widget _cell(
    String text, {
    bool header = false,
    bool right = false,
    double? maxWidth,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: pw.Align(
      alignment: right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: t(
        text,
        size: header ? 8 : (compact ? 8 : 9.5),
        bold: header,
        color: header ? _grey : _black,
        maxWidth: maxWidth,
        align: right ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    ),
  );

  pw.Widget _lines() {
    final descWidth = _contentWidth * (compact ? 0.45 : 0.45) - 8;
    final header = [
      if (!compact) s.serialNo,
      s.description,
      s.quantity,
      s.rate,
      s.amount,
    ];
    final firstNumeric = compact ? 1 : 2;
    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfColors.grey400),
        bottom: pw.BorderSide(color: PdfColors.grey400),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      columnWidths: {
        if (!compact) 0: const pw.FlexColumnWidth(0.5),
        if (!compact)
          1: const pw.FlexColumnWidth(4.5)
        else
          0: const pw.FlexColumnWidth(4.5),
        firstNumeric: const pw.FlexColumnWidth(1.2),
        firstNumeric + 1: const pw.FlexColumnWidth(1.8),
        firstNumeric + 2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            for (var i = 0; i < header.length; i++)
              _cell(header[i], header: true, right: i >= firstNumeric),
          ],
        ),
        for (var i = 0; i < doc.lines.length; i++)
          pw.TableRow(
            children: [
              if (!compact) _cell(_num('${i + 1}')),
              _cell(doc.lines[i].description, maxWidth: descWidth),
              _cell(
                _num(doc.lines[i].quantityText) +
                    (doc.lines[i].unit == null ? '' : ' ${doc.lines[i].unit}'),
                right: true,
              ),
              _cell(_money(doc.lines[i].rate), right: true),
              _cell(_money(doc.lines[i].amount), right: true),
            ],
          ),
      ],
    );
  }

  pw.Widget _row(String label, String value, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        t(label, size: bold ? 10.5 : 9.5, bold: bold),
        t(value, size: bold ? 10.5 : 9.5, bold: bold),
      ],
    ),
  );

  pw.Widget _totals() {
    final tt = totals;
    final vatLabel = doc.vat.charges
        ? '${s.vat} (${_num(formatVatRate(doc.vat.rateBp))}%${doc.vat.inclusive ? (ne ? ' समावेश' : ' incl.') : ''})'
        : null;
    final box = pw.Column(
      children: [
        _row(s.subtotal, _money(tt.subtotal)),
        if (!tt.discount.isZero) _row(s.discount, '-${_money(tt.discount)}'),
        if (vatLabel != null) ...[
          _row(s.taxable, _money(tt.taxable)),
          _row(vatLabel, _money(tt.vat)),
        ],
        pw.Divider(color: PdfColors.grey400, height: 6),
        _row('${s.total} (${ne ? 'रु' : 'Rs.'})', _money(tt.total), bold: true),
        if (!tt.paid.isZero) ...[
          _row(s.paid, _money(tt.paid)),
          _row(s.balance, _money(tt.balance), bold: true),
        ],
      ],
    );
    if (compact) return box;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [pw.SizedBox(width: 230, child: box)],
    );
  }

  pw.Widget _inWords() {
    final words = nprInWords(
      totals.total,
      language: ne ? AmountWordsLanguage.ne : AmountWordsLanguage.en,
    );
    final text =
        '${s.inWords}: ${ne ? words : '${words[0].toUpperCase()}${words.substring(1)}'}';
    return t(text, size: 9, maxWidth: _contentWidth);
  }
}
