import '../date/bs_date.dart';
import '../date/date_format.dart';
import '../l10n/strings.dart';
import '../number/npr.dart';
import 'sms_gateway.dart';
import 'template.dart';

/// Kinds of reminder nepal_kit ships wording for.
enum ReminderKind {
  /// Rent is due (Sajilo Rent / Bhadama).
  rentDue,

  /// Udhaaro (credit) is outstanding (shops, Tipot receipts).
  udhaaro,

  /// An appointment or visit (Gaadidesk test drives, Sambandha follow-ups).
  appointment,
}

/// Built-in reminder wording, with `{placeholder}` fields in Sandesh's
/// template syntax. Apps may pass their own text instead.
///
/// Fields: `{name}`, `{business}`, `{amount}`, `{date}`, `{time}`,
/// `{place}`, `{phone}`.
abstract final class ReminderTemplates {
  /// The template for [kind] in [language].
  static String of(ReminderKind kind, NepalKitLanguage language) =>
      (language == NepalKitLanguage.ne ? _ne : _en)[kind]!;

  static const Map<ReminderKind, String> _en = {
    ReminderKind.rentDue:
        'Dear {name}, your rent of {amount} is due on {date}. - {business}',
    ReminderKind.udhaaro:
        'Dear {name}, {amount} is outstanding on your account with {business} '
        'as of {date}. Please settle when you can. Thank you.',
    ReminderKind.appointment:
        'Dear {name}, a reminder of your appointment on {date} at {time}, '
        '{place}. - {business}',
  };

  static const Map<ReminderKind, String> _ne = {
    ReminderKind.rentDue:
        'आदरणीय {name}, तपाईंको {amount} भाडा {date} मा बुझाउनुपर्ने छ। - {business}',
    ReminderKind.udhaaro:
        'आदरणीय {name}, {date} सम्म {business} मा तपाईंको {amount} उधारो बाँकी छ। '
        'सुविधा अनुसार चुक्ता गरिदिनुहोला। धन्यवाद।',
    ReminderKind.appointment:
        'आदरणीय {name}, {date} {time} मा {place} मा तपाईंको भेटघाट छ। - {business}',
  };

  /// Fills the built-in template for [kind], formatting [amount] as NPR
  /// and [date] as a BS date in [language].
  static String render(
    ReminderKind kind, {
    required NepalKitLanguage language,
    required String name,
    required String business,
    Npr? amount,
    BsDate? date,
    String? time,
    String? place,
    String? template,
  }) {
    final ne = language == NepalKitLanguage.ne;
    return renderTemplate(template ?? of(kind, language), {
      'name': name,
      'business': business,
      if (amount != null)
        'amount': amount.format(
          symbol: ne ? NprSymbol.rupee : NprSymbol.rs,
          devanagari: ne,
        ),
      if (date != null) 'date': NepaliDateFormat.long(language).formatBs(date),
      'time': ?time,
      'place': ?place,
    }).text;
  }
}

/// A reminder waiting to be sent.
class Reminder {
  /// A reminder of [body] to [to], to be sent at or after [sendAt].
  const Reminder({
    required this.id,
    required this.to,
    required this.body,
    required this.sendAt,
    this.kind,
    this.attempts = 0,
    this.lastError,
  });

  /// Caller's id (for example the rent invoice's id), unique per store.
  final String id;

  /// Recipient.
  final String to;

  /// Text.
  final String body;

  /// Earliest time to send.
  final DateTime sendAt;

  /// What it is about, if one of the built-in kinds.
  final ReminderKind? kind;

  /// Failed attempts so far.
  final int attempts;

  /// The last failure.
  final String? lastError;

  /// A copy with the given fields changed.
  Reminder copyWith({DateTime? sendAt, int? attempts, String? lastError}) =>
      Reminder(
        id: id,
        to: to,
        body: body,
        sendAt: sendAt ?? this.sendAt,
        kind: kind,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
      );
}

/// Where a [ReminderScheduler] keeps pending reminders. Apps back it with
/// their own database; [InMemoryReminderStore] is for tests and demos.
abstract interface class ReminderStore {
  /// Adds or replaces the reminder with the same id.
  Future<void> put(Reminder reminder);

  /// Removes a reminder; no-op if absent.
  Future<void> remove(String id);

  /// Pending reminders with `sendAt` at or before [now].
  Future<List<Reminder>> due(DateTime now);

  /// All pending reminders.
  Future<List<Reminder>> all();
}

/// A [ReminderStore] in memory.
class InMemoryReminderStore implements ReminderStore {
  final Map<String, Reminder> _items = {};

  @override
  Future<void> put(Reminder reminder) async => _items[reminder.id] = reminder;

  @override
  Future<void> remove(String id) async => _items.remove(id);

  @override
  Future<List<Reminder>> due(DateTime now) async => [
    for (final r in _items.values)
      if (!r.sendAt.isAfter(now)) r,
  ]..sort((a, b) => a.sendAt.compareTo(b.sendAt));

  @override
  Future<List<Reminder>> all() async => _items.values.toList();
}

/// What one [ReminderScheduler.dispatchDue] run did.
class DispatchReport {
  /// A report.
  const DispatchReport(this.sent, this.retrying, this.gaveUp);

  /// Reminders sent.
  final List<SmsReceipt> sent;

  /// Reminders that failed and will be retried.
  final List<Reminder> retrying;

  /// Reminders dropped after [ReminderScheduler.maxAttempts] failures.
  final List<Reminder> gaveUp;
}

/// Holds reminders until they are due and sends them through an
/// [SmsGateway].
///
/// Sandesh sends what it is given straight away, so scheduling lives on
/// the client. Call [dispatchDue] from whatever wakes the app: a timer, a
/// background task (WorkManager), app start, or a server cron.
class ReminderScheduler {
  /// A scheduler sending through [gateway] and keeping reminders in
  /// [store].
  ReminderScheduler({
    required this.gateway,
    ReminderStore? store,
    this.maxAttempts = 3,
    this.retryAfter = const Duration(minutes: 30),
    DateTime Function()? clock,
  }) : store = store ?? InMemoryReminderStore(),
       _clock = clock ?? DateTime.now;

  /// Where messages go.
  final SmsGateway gateway;

  /// Where pending reminders are kept.
  final ReminderStore store;

  /// Failures before a reminder is dropped.
  final int maxAttempts;

  /// Delay before retrying a failed reminder.
  final Duration retryAfter;

  final DateTime Function() _clock;

  /// Schedules [reminder] (replacing one with the same id).
  Future<void> schedule(Reminder reminder) => store.put(reminder);

  /// Cancels a pending reminder.
  Future<void> cancel(String id) => store.remove(id);

  /// Sends every due reminder once. A failed one is retried after
  /// [retryAfter], up to [maxAttempts] times.
  Future<DispatchReport> dispatchDue() async {
    final now = _clock();
    final sent = <SmsReceipt>[];
    final retrying = <Reminder>[];
    final gaveUp = <Reminder>[];
    for (final r in await store.due(now)) {
      try {
        sent.add(await gateway.send(r.to, r.body));
        await store.remove(r.id);
      } on SmsGatewayException catch (e) {
        final next = r.copyWith(
          attempts: r.attempts + 1,
          lastError: e.code,
          sendAt: now.add(retryAfter),
        );
        final permanent = e.code == 'validation_failed';
        if (permanent || next.attempts >= maxAttempts) {
          await store.remove(r.id);
          gaveUp.add(next);
        } else {
          await store.put(next);
          retrying.add(next);
        }
      }
    }
    return DispatchReport(sent, retrying, gaveUp);
  }
}
