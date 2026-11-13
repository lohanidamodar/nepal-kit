/// Loads the bundled Noto Sans Devanagari fonts from the package on disk,
/// for servers and command-line tools that build receipt PDFs. Uses
/// `dart:io`; Flutter apps load them with `rootBundle` instead (see
/// `ReceiptFonts.regularAsset`).
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'src/receipt/receipt_pdf.dart';

/// The bundled receipt fonts, read through the package's `package:` URI.
Future<ReceiptFonts> loadBundledReceiptFonts() async {
  Future<ByteData> read(String name) async {
    final uri = await Isolate.resolvePackageUri(
      Uri.parse('package:nepal_kit/fonts/$name'),
    );
    if (uri == null) throw StateError('package:nepal_kit is not resolvable');
    final bytes = await File.fromUri(uri).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  return ReceiptFonts(
    devanagari: await read('NotoSansDevanagari-Regular.ttf'),
    devanagariBold: await read('NotoSansDevanagari-Bold.ttf'),
  );
}
