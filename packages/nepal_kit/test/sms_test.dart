import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nepal_kit/nepal_kit.dart';
import 'package:test/test.dart';

void main() {
  group('templates (Sandesh semantics)', () {
    test('fills placeholders, ignores case, keeps missing ones', () {
      final r = renderTemplate('Hi {Name}, {amount} due {{soon}} {x}', {
        'name': 'Sita',
        'AMOUNT': 'Rs. 5',
      });
      expect(r.text, 'Hi Sita, Rs. 5 due {soon} {x}');
      expect(r.missing, {'x'});
      expect(placeholdersIn('{a} {B} {{c}}'), {'a', 'b'});
      expect(renderTemplate('{ broken', {}).text, '{ broken');
    });
  });

  group('reminder wording', () {
    test('rent due, English and Nepali', () {
      expect(
        ReminderTemplates.render(
          ReminderKind.rentDue,
          language: NepalKitLanguage.en,
          name: 'Hari',
          business: 'Sajilo Rent',
          amount: const Npr.rupees(15000),
          date: BsDate(2081, 5, 1),
        ),
        'Dear Hari, your rent of Rs. 15,000 is due on 1 Bhadra 2081. - Sajilo Rent',
      );
      expect(
        ReminderTemplates.render(
          ReminderKind.rentDue,
          language: NepalKitLanguage.ne,
          name: 'हरि',
          business: 'सजिलो रेन्ट',
          amount: const Npr.rupees(15000),
          date: BsDate(2081, 5, 1),
        ),
        'आदरणीय हरि, तपाईंको रु १५,००० भाडा १ भदौ २०८१ मा बुझाउनुपर्ने छ। - सजिलो रेन्ट',
      );
    });

    test('every kind fills completely in both languages', () {
      for (final k in ReminderKind.values) {
        for (final l in NepalKitLanguage.values) {
          final text = ReminderTemplates.render(
            k,
            language: l,
            name: 'N',
            business: 'B',
            amount: const Npr(100),
            date: BsDate(2081, 1, 1),
            time: '10:00',
            place: 'P',
          );
          expect(text.contains('{'), isFalse, reason: '$k $l: $text');
        }
      }
    });
  });

  group('MockSmsGateway', () {
    test('records sends and validates numbers', () async {
      final g = MockSmsGateway();
      final r = await g.send('984-1234567', 'hello');
      expect(r.to, '+9779841234567');
      expect(r.status, SmsStatus.sent);
      expect(g.sent.single.body, 'hello');
      await expectLater(
        g.send('12345', 'x'),
        throwsA(isA<SmsGatewayException>()),
      );
    });

    test('bulk renders per recipient and skips invalid numbers', () async {
      final g = MockSmsGateway();
      final r = await g.sendBulk('Hi {name}', [
        const SmsRecipient('9841234567', {'name': 'Ram'}),
        const SmsRecipient('bad', {'name': 'X'}),
        const SmsRecipient('9801234567', {'name': 'Sita'}),
      ]);
      expect(r.total, 2);
      expect(g.sent.map((s) => s.body), ['Hi Ram', 'Hi Sita']);
    });
  });

  group('SandeshSmsGateway', () {
    test('POSTs /api/v1/messages with the key and E.164 number', () async {
      late http.Request seen;
      final client = MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'id': 'm1',
            'to': '+9779841234567',
            'body': 'नमस्ते',
            'status': 'queued',
          }),
          202,
          headers: {'content-type': 'application/json'},
        );
      });
      final g = SandeshSmsGateway(
        baseUrl: Uri.parse('https://192.168.1.20:8443'),
        apiKey: 'snd_abc',
        client: client,
        simId: 2,
      );
      final r = await g.send('984 1234567', 'नमस्ते');
      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://192.168.1.20:8443/api/v1/messages');
      expect(seen.headers['authorization'], 'Bearer snd_abc');
      expect(jsonDecode(seen.body), {
        'to': '+9779841234567',
        'body': 'नमस्ते',
        'simId': 2,
      });
      expect(r.id, 'm1');
      expect(r.status, SmsStatus.queued);
    });

    test('bulk POSTs /api/v1/jobs', () async {
      late Map<String, Object?> body;
      final client = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, Object?>;
        expect(req.url.path, '/api/v1/jobs');
        return http.Response(
          jsonEncode({
            'id': 'j1',
            'state': 'running',
            'counts': {'total': 1},
          }),
          201,
        );
      });
      final g = SandeshSmsGateway(
        baseUrl: Uri.parse('http://phone:8080'),
        apiKey: 'k',
        client: client,
      );
      final r = await g.sendBulk('Hi {name}', [
        const SmsRecipient('9841234567', {'name': 'Ram'}),
      ]);
      expect(body['template'], 'Hi {name}');
      expect(body['recipients'], [
        {
          'number': '+9779841234567',
          'fields': {'name': 'Ram'},
        },
      ]);
      expect(body.containsKey('simId'), isFalse);
      expect([r.id, r.state, r.total], ['j1', 'running', 1]);
    });

    test('maps the error envelope', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'daily_cap_reached', 'message': 'cap'},
          }),
          429,
        ),
      );
      final g = SandeshSmsGateway(
        baseUrl: Uri.parse('http://phone:8080'),
        apiKey: 'k',
        client: client,
      );
      await expectLater(
        g.send('9841234567', 'x'),
        throwsA(
          isA<SmsGatewayException>()
              .having((e) => e.code, 'code', 'daily_cap_reached')
              .having((e) => e.status, 'status', 429),
        ),
      );
    });

    test('non-JSON and network failures', () async {
      final bad = SandeshSmsGateway(
        baseUrl: Uri.parse('http://phone:8080'),
        apiKey: 'k',
        client: MockClient((_) async => http.Response('<html>', 502)),
      );
      await expectLater(
        bad.send('9841234567', 'x'),
        throwsA(
          isA<SmsGatewayException>().having((e) => e.code, 'code', 'http_502'),
        ),
      );
      final down = SandeshSmsGateway(
        baseUrl: Uri.parse('http://phone:8080'),
        apiKey: 'k',
        client: MockClient((_) async => throw http.ClientException('refused')),
      );
      await expectLater(
        down.send('9841234567', 'x'),
        throwsA(
          isA<SmsGatewayException>().having((e) => e.code, 'code', 'network'),
        ),
      );
    });
  });

  group('ReminderScheduler', () {
    test('sends only what is due, retries failures, gives up', () async {
      var now = DateTime.utc(2024, 4, 13, 9);
      final gateway = MockSmsGateway(clock: () => now);
      final s = ReminderScheduler(
        gateway: gateway,
        clock: () => now,
        maxAttempts: 2,
        retryAfter: const Duration(hours: 1),
      );
      await s.schedule(
        Reminder(id: 'a', to: '9841234567', body: 'A', sendAt: now),
      );
      await s.schedule(
        Reminder(
          id: 'b',
          to: '9801234567',
          body: 'B',
          sendAt: now.add(const Duration(days: 1)),
        ),
      );
      await s.schedule(
        Reminder(id: 'c', to: '9811234567', body: 'C', sendAt: now),
      );

      gateway.failNext = const SmsGatewayException('rate_limited', 'slow down');
      var r = await s.dispatchDue();
      expect(r.sent.map((x) => x.body), ['C']);
      expect(r.retrying.single.id, 'a');
      expect((await s.store.all()).map((x) => x.id).toSet(), {'a', 'b'});

      // Not yet time to retry.
      r = await s.dispatchDue();
      expect(r.sent, isEmpty);

      now = now.add(const Duration(hours: 1));
      gateway.failNext = const SmsGatewayException('rate_limited', 'again');
      r = await s.dispatchDue();
      expect(r.gaveUp.single.id, 'a');
      expect(r.gaveUp.single.attempts, 2);

      now = now.add(const Duration(days: 1));
      r = await s.dispatchDue();
      expect(r.sent.map((x) => x.body), ['B']);
      expect(await s.store.all(), isEmpty);
    });

    test('a number the gateway rejects is not retried', () async {
      final now = DateTime.utc(2024);
      final s = ReminderScheduler(gateway: MockSmsGateway(), clock: () => now);
      await s.schedule(Reminder(id: 'x', to: '123', body: 'x', sendAt: now));
      final r = await s.dispatchDue();
      expect(r.gaveUp.single.lastError, 'validation_failed');
      await s.schedule(
        Reminder(id: 'y', to: '9841234567', body: 'y', sendAt: now),
      );
      await s.cancel('y');
      expect((await s.dispatchDue()).sent, isEmpty);
    });
  });
}
