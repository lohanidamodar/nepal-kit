/// An HTTP client that pins a Sandesh phone's self-signed certificate.
/// Uses `dart:io`, so it is a separate library from `nepal_kit.dart`
/// (which also runs on the web).
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// A client that trusts exactly the certificate whose SHA-256 fingerprint
/// (lower-case hex of the DER encoding, the `fp` in Sandesh's pairing link)
/// is [fingerprint], and nothing else.
///
/// Pass it to `SandeshSmsGateway(client: ...)`.
http.Client sandeshPinnedClient(String fingerprint) {
  final pin = fingerprint.toLowerCase().replaceAll(':', '');
  final inner = HttpClient()
    ..badCertificateCallback = (cert, host, port) =>
        sha256.convert(cert.der).toString() == pin;
  return IOClient(inner);
}
