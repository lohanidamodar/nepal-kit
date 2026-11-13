import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../phone/nepali_phone.dart';
import 'template.dart';

/// Where an SMS stands.
enum SmsStatus {
  /// Accepted, waiting for its SIM lane.
  queued,

  /// Being sent.
  sending,

  /// Handed to the network.
  sent,

  /// The network reported delivery.
  delivered,

  /// Not sent; see [SmsReceipt.failureReason].
  failed;

  static SmsStatus _parse(Object? s) =>
      SmsStatus.values.asNameMap()[s] ?? SmsStatus.queued;
}

/// What a gateway answered for one message.
class SmsReceipt {
  /// A receipt.
  const SmsReceipt({
    required this.id,
    required this.to,
    required this.body,
    required this.status,
    this.failureReason,
  });

  /// Gateway's message id.
  final String id;

  /// Recipient, E.164.
  final String to;

  /// Text sent.
  final String body;

  /// Status at the time of the answer.
  final SmsStatus status;

  /// Why it failed, when [status] is [SmsStatus.failed].
  final String? failureReason;
}

/// One recipient of a templated bulk send.
class SmsRecipient {
  /// [phone] with values for the template's `{placeholders}`.
  const SmsRecipient(this.phone, [this.fields = const {}]);

  /// Number as typed; gateways normalise it.
  final String phone;

  /// Placeholder values.
  final Map<String, String> fields;
}

/// What a gateway answered for a bulk send.
class SmsBulkReceipt {
  /// A receipt.
  const SmsBulkReceipt({required this.id, required this.state, this.total});

  /// Gateway's job id.
  final String id;

  /// Gateway's job state (`running`, `paused`, ...).
  final String state;

  /// Recipients accepted, when the gateway says.
  final int? total;
}

/// A failure the gateway reported.
class SmsGatewayException implements Exception {
  /// An error with the gateway's [code] (`validation_failed`,
  /// `rate_limited`, ...) and HTTP [status].
  const SmsGatewayException(this.code, this.message, {this.status});

  /// Machine-readable code.
  final String code;

  /// Human-readable message.
  final String message;

  /// HTTP status, when there was a response.
  final int? status;

  @override
  String toString() => 'SmsGatewayException($status $code: $message)';
}

/// Sends SMS. Apps depend on this interface, so tests and demos can use
/// [MockSmsGateway] and production can use [SandeshSmsGateway].
abstract interface class SmsGateway {
  /// Sends [body] to [to].
  Future<SmsReceipt> send(String to, String body);

  /// Sends [template] to each recipient, filled with its fields.
  Future<SmsBulkReceipt> sendBulk(
    String template,
    List<SmsRecipient> recipients,
  );
}

/// A client for a Sandesh phone's REST API (`/api/v1`).
///
/// Give it the phone's address and an API key with the `sms:send` scope
/// (pair in the Sandesh app to get one). Over HTTPS the phone's
/// certificate is self-signed; pass an [http.Client] that pins it, such as
/// `sandeshPinnedClient(fingerprint)` from `package:nepal_kit/sandesh_io.dart`.
///
/// Sandesh queues and throttles sends per SIM itself; this client only
/// submits. Sandesh has no scheduled sends, so use [ReminderScheduler] to
/// hold a message until it is due.
class SandeshSmsGateway implements SmsGateway {
  /// A client for the phone at [baseUrl] (`https://192.168.1.20:8443`).
  SandeshSmsGateway({
    required Uri baseUrl,
    required String apiKey,
    http.Client? client,
    this.simId,
    this.timeout = const Duration(seconds: 20),
  }) : _base = baseUrl,
       _key = apiKey,
       _client = client ?? http.Client();

  final Uri _base;
  final String _key;
  final http.Client _client;

  /// SIM to send from; null lets the phone use its default.
  final int? simId;

  /// Per-request timeout.
  final Duration timeout;

  @override
  Future<SmsReceipt> send(String to, String body) async {
    final json = await _post('/api/v1/messages', {
      'to': NepaliPhone.tryParse(to)?.e164 ?? to,
      'body': body,
      'simId': ?simId,
    });
    return SmsReceipt(
      id: json['id'] as String,
      to: json['to'] as String? ?? to,
      body: json['body'] as String? ?? body,
      status: SmsStatus._parse(json['status']),
      failureReason: json['failureReason'] as String?,
    );
  }

  @override
  Future<SmsBulkReceipt> sendBulk(
    String template,
    List<SmsRecipient> recipients,
  ) async {
    final json = await _post('/api/v1/jobs', {
      'template': template,
      'recipients': [
        for (final r in recipients)
          {
            'number': NepaliPhone.tryParse(r.phone)?.e164 ?? r.phone,
            'fields': r.fields,
          },
      ],
      'simId': ?simId,
      'skipInvalid': true,
    });
    final counts = json['counts'];
    return SmsBulkReceipt(
      id: json['id'] as String,
      state: json['state'] as String? ?? 'unknown',
      total: counts is Map ? counts['total'] as int? : null,
    );
  }

  /// Closes the underlying client.
  void close() => _client.close();

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final uri = _base.replace(path: path);
    http.Response r;
    try {
      r = await _client
          .post(
            uri,
            headers: {
              'authorization': 'Bearer $_key',
              'content-type': 'application/json; charset=utf-8',
              'accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const SmsGatewayException(
        'timeout',
        'Sandesh did not answer in time',
      );
    } on http.ClientException catch (e) {
      throw SmsGatewayException('network', e.message);
    }
    Object? decoded;
    try {
      decoded = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      decoded = null;
    }
    if (r.statusCode >= 200 &&
        r.statusCode < 300 &&
        decoded is Map<String, Object?>) {
      return decoded;
    }
    final err = decoded is Map && decoded['error'] is Map
        ? decoded['error'] as Map
        : null;
    throw SmsGatewayException(
      err?['code'] as String? ?? 'http_${r.statusCode}',
      err?['message'] as String? ?? 'Unexpected response from Sandesh',
      status: r.statusCode,
    );
  }
}

/// A message [MockSmsGateway] recorded.
class MockSms {
  /// A recorded message.
  const MockSms(this.to, this.body, this.at);

  /// Recipient as given.
  final String to;

  /// Text.
  final String body;

  /// When it was "sent".
  final DateTime at;
}

/// An in-memory [SmsGateway] for tests, demos and development. It sends
/// nothing; it records each message in [sent].
class MockSmsGateway implements SmsGateway {
  /// A mock. Numbers that are not valid Nepali mobiles fail, as they would
  /// on Sandesh; set [validateNumbers] to false to accept anything.
  MockSmsGateway({this.validateNumbers = true, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Whether to reject numbers that are not Nepali mobiles.
  final bool validateNumbers;

  final DateTime Function() _clock;

  /// Every message accepted, oldest first.
  final List<MockSms> sent = [];

  /// Throw this from the next [send] (then clear it), to test failures.
  SmsGatewayException? failNext;

  var _id = 0;

  @override
  Future<SmsReceipt> send(String to, String body) async {
    final fail = failNext;
    if (fail != null) {
      failNext = null;
      throw fail;
    }
    final phone = NepaliPhone.tryParse(to, mobileOnly: true);
    if (validateNumbers && phone == null) {
      throw SmsGatewayException(
        'validation_failed',
        'Not a valid number: $to',
        status: 422,
      );
    }
    sent.add(MockSms(to, body, _clock()));
    return SmsReceipt(
      id: 'mock-${++_id}',
      to: phone?.e164 ?? to,
      body: body,
      status: SmsStatus.sent,
    );
  }

  @override
  Future<SmsBulkReceipt> sendBulk(
    String template,
    List<SmsRecipient> recipients,
  ) async {
    var n = 0;
    for (final r in recipients) {
      if (validateNumbers &&
          NepaliPhone.tryParse(r.phone, mobileOnly: true) == null) {
        continue;
      }
      sent.add(
        MockSms(r.phone, renderTemplate(template, r.fields).text, _clock()),
      );
      n++;
    }
    return SmsBulkReceipt(id: 'mock-job-${++_id}', state: 'finished', total: n);
  }
}
