import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nepal_kit/nepal_kit.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Font family [FlutterTextRasterizer] registers the bundled Noto Sans
/// Devanagari under.
const String nepalKitDevanagariFamily = 'NepalKitDevanagari';

/// Loads the bundled Noto Sans Devanagari fonts from the asset bundle.
Future<ReceiptFonts> loadReceiptFonts({AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  return ReceiptFonts(
    devanagari: await b.load(ReceiptFonts.regularAsset),
    devanagariBold: await b.load(ReceiptFonts.boldAsset),
  );
}

/// A [TextRasterizer] that draws with Flutter's text engine, which shapes
/// Devanagari properly (conjuncts, reph, matras). Text is drawn at
/// [scale]× (default 4, about 290 dpi) with the bundled Noto Sans
/// Devanagari, so it looks the same on every platform.
class FlutterTextRasterizer implements TextRasterizer {
  /// A rasterizer; [fonts] are registered with the engine on first use.
  FlutterTextRasterizer({this.scale = 4, ReceiptFontsBytes? fonts})
    // ignore: prefer_initializing_formals
    : _fonts = fonts;

  /// Pixels per PDF point.
  final double scale;

  final ReceiptFontsBytes? _fonts;
  Future<void>? _loading;

  Future<void> _ensureFont() => _loading ??= () async {
    final f = _fonts ?? await ReceiptFontsBytes.load();
    final loader = FontLoader(nepalKitDevanagariFamily)
      ..addFont(Future.value(f.regular))
      ..addFont(Future.value(f.bold));
    await loader.load();
  }();

  @override
  Future<RasterText> rasterize(
    String text, {
    required double fontSize,
    required bool bold,
    required int color,
    double? maxWidth,
  }) async {
    await _ensureFont();
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: nepalKitDevanagariFamily,
              fontSize: fontSize * scale,
              fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
              height: 1.25,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: ui.Color(color),
              fontFamily: nepalKitDevanagariFamily,
              fontFamilyFallback: const [
                'Helvetica',
                'Arial',
                'Roboto',
                'sans-serif',
              ],
            ),
          )
          ..addText(text);
    final paragraph = builder.build()
      ..layout(
        ui.ParagraphConstraints(
          width: maxWidth == null ? double.infinity : maxWidth * scale,
        ),
      );
    final w = math
        .max(
          1.0,
          (maxWidth == null
              ? paragraph.maxIntrinsicWidth
              : math.min(paragraph.longestLine, maxWidth * scale)),
        )
        .ceilToDouble();
    final h = math.max(1.0, paragraph.height).ceilToDouble();
    if (maxWidth == null) {
      paragraph.layout(ui.ParagraphConstraints(width: w));
    }
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawParagraph(paragraph, Offset.zero);
    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    paragraph.dispose();
    return RasterText(png!.buffer.asUint8List(), w / scale, h / scale);
  }
}

/// The bundled font files as raw bytes.
class ReceiptFontsBytes {
  /// Bytes of the regular and bold files.
  const ReceiptFontsBytes(this.regular, this.bold);

  /// Regular.
  final ByteData regular;

  /// Bold.
  final ByteData bold;

  /// Loads them from the asset bundle.
  static Future<ReceiptFontsBytes> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    return ReceiptFontsBytes(
      await b.load(ReceiptFonts.regularAsset),
      await b.load(ReceiptFonts.boldAsset),
    );
  }
}

/// Builds [doc]'s PDF with correctly shaped Devanagari (through
/// [FlutterTextRasterizer]) and the bundled fonts.
Future<Uint8List> buildReceiptPdfFlutter(
  ReceiptDocument doc, {
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  TextRasterizer? rasterizer,
}) async => buildReceiptPdf(
  doc,
  fonts: await loadReceiptFonts(),
  rasterizer: rasterizer ?? _sharedRasterizer,
  pageFormat: pageFormat,
);

final FlutterTextRasterizer _sharedRasterizer = FlutterTextRasterizer();

/// Sends [doc] to the system print dialog.
Future<bool> printReceipt(
  ReceiptDocument doc, {
  PdfPageFormat pageFormat = PdfPageFormat.a4,
}) => Printing.layoutPdf(
  name: '${doc.number}.pdf',
  format: pageFormat,
  onLayout: (_) => buildReceiptPdfFlutter(doc, pageFormat: pageFormat),
);

/// Opens the platform share sheet with [doc] as a PDF named
/// `<number>.pdf`.
Future<bool> shareReceipt(
  ReceiptDocument doc, {
  PdfPageFormat pageFormat = PdfPageFormat.a4,
  String? filename,
}) async => Printing.sharePdf(
  bytes: await buildReceiptPdfFlutter(doc, pageFormat: pageFormat),
  filename:
      filename ?? '${doc.number.replaceAll(RegExp(r'[^\w\-.]'), '_')}.pdf',
);

/// Shows a receipt's pages as images, using only the widgets layer (no
/// Material), so it fits any design system. Rasterising uses the
/// `printing` plugin, so it needs a running app (not `flutter test`).
class ReceiptPreview extends StatefulWidget {
  /// A preview of [doc].
  const ReceiptPreview({
    super.key,
    required this.doc,
    this.pageFormat = PdfPageFormat.a4,
    this.dpi = 144,
    this.loading,
    this.maxPageWidth = 720,
  });

  /// Widest a page is drawn, logical pixels.
  final double maxPageWidth;

  /// The document.
  final ReceiptDocument doc;

  /// Page size.
  final PdfPageFormat pageFormat;

  /// Preview resolution.
  final double dpi;

  /// Shown while rendering.
  final Widget? loading;

  @override
  State<ReceiptPreview> createState() => _ReceiptPreviewState();
}

class _ReceiptPreviewState extends State<ReceiptPreview> {
  Future<List<ui.Image>>? _pages;

  @override
  void initState() {
    super.initState();
    _render();
  }

  @override
  void didUpdateWidget(ReceiptPreview old) {
    super.didUpdateWidget(old);
    if (old.doc != widget.doc || old.pageFormat != widget.pageFormat) _render();
  }

  void _render() {
    _pages = () async {
      final bytes = await buildReceiptPdfFlutter(
        widget.doc,
        pageFormat: widget.pageFormat,
      );
      return [
        await for (final p in Printing.raster(bytes, dpi: widget.dpi))
          await p.toImage(),
      ];
    }();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ui.Image>>(
    future: _pages,
    builder: (context, snap) {
      if (snap.hasError) {
        return Center(child: Text('${snap.error}'));
      }
      final pages = snap.data;
      if (pages == null) {
        return widget.loading ?? const Center(child: Text('…'));
      }
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final p in pages)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: widget.maxPageWidth),
                  child: AspectRatio(
                    aspectRatio: p.width / p.height,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        boxShadow: [
                          BoxShadow(blurRadius: 6, color: Color(0x33000000)),
                        ],
                      ),
                      child: RawImage(image: p, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
