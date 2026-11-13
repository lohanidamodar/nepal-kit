import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_kit_flutter/nepal_kit_flutter.dart';

/// A bare app: WidgetsApp only, no Material, as material_ui apps have.
Widget _app(Widget child, {Locale locale = const Locale('en')}) => WidgetsApp(
  color: const Color(0xFF1565C0),
  locale: locale,
  supportedLocales: NepalKitLocalizations.supportedLocales,
  localizationsDelegates: const [
    NepalKitLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (c, _, _) => builder(c),
  ),
  home: child,
);

void main() {
  group('BsMonthCalendar', () {
    testWidgets('shows the month, AD span, weekdays and days', (tester) async {
      await tester.pumpWidget(
        _app(
          BsMonthCalendar(month: BsDate(2081, 1, 1), today: BsDate(2081, 1, 5)),
        ),
      );
      expect(find.text('Baishakh 2081'), findsOneWidget);
      expect(find.text('Apr/May 2024'), findsOneWidget);
      expect(
        find.text('31'),
        findsOneWidget,
      ); // 31 Baishakh (no AD 31 in the span)
      expect(find.text('S'), findsNWidgets(2));
      expect(
        find.bySemanticsLabel('Wednesday, 5 Baishakh 2081'),
        findsOneWidget,
      );
    });

    testWidgets('Nepali: Devanagari digits and names', (tester) async {
      await tester.pumpWidget(
        _app(
          BsMonthCalendar(month: BsDate(2081, 1, 1), today: BsDate(2081, 1, 5)),
          locale: const Locale('ne'),
        ),
      );
      expect(find.text('बैशाख २०८१'), findsOneWidget);
      expect(find.text('३१'), findsOneWidget);
      expect(find.text('आ'), findsOneWidget);
    });

    testWidgets('taps select, arrows page, bounds disable', (tester) async {
      BsDate? picked, paged;
      await tester.pumpWidget(
        _app(
          BsMonthCalendar(
            month: BsDate(2081, 1, 1),
            firstDate: BsDate(2081, 1, 10),
            onDateSelected: (d) => picked = d,
            onMonthChanged: (m) => paged = m,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Saturday, 15 Baishakh 2081'));
      expect(picked, BsDate(2081, 1, 15));
      picked = null;
      await tester.tap(find.bySemanticsLabel('Thursday, 6 Baishakh 2081'));
      expect(picked, isNull, reason: 'before firstDate');
      await tester.tap(find.text('›'));
      expect(paged, BsDate(2081, 2, 1));
      paged = null;
      await tester.tap(find.text('‹'));
      expect(paged, isNull, reason: 'the previous month is out of range');
    });

    testWidgets('marked dates and custom cells', (tester) async {
      await tester.pumpWidget(
        _app(
          BsMonthCalendar(
            month: BsDate(2081, 1, 1),
            markedDates: {BsDate(2081, 1, 3)},
            dayBuilder: (context, d, s) =>
                s.marked ? const Text('EVENT') : null,
          ),
        ),
      );
      expect(find.text('EVENT'), findsOneWidget);
    });
  });

  group('showBsDatePicker', () {
    Future<(Future<BsDate?>,)> open(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
          locale: locale,
        ),
      );
      final f = showBsDatePicker(
        context: ctx,
        initialDate: BsDate(2081, 1, 5),
        firstDate: BsDate(2080, 1, 1),
        lastDate: BsDate(2082, 12, 30),
      );
      await tester.pumpAndSettle();
      return (f,);
    }

    testWidgets('pick a day and confirm', (tester) async {
      final (f,) = await open(tester);
      expect(find.text('Wednesday, 5 Baishakh 2081'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Thursday, 20 Baishakh 2081'));
      await tester.pump();
      expect(find.text('Thursday, 20 Baishakh 2081'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await f, BsDate(2081, 1, 20));
    });

    testWidgets('cancel returns null', (tester) async {
      final (f,) = await open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await f, isNull);
    });

    testWidgets('month chooser jumps to another month and year', (
      tester,
    ) async {
      final (f,) = await open(tester);
      await tester.tap(find.text('Baishakh 2081'));
      await tester.pump();
      await tester.tap(find.text('›').first);
      await tester.pump();
      expect(find.text('2082'), findsOneWidget);
      await tester.tap(find.text('Poush'));
      await tester.pump();
      expect(find.text('Poush 2082'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel(RegExp(r', 10 Poush 2082$')));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await f, BsDate(2082, 9, 10));
    });

    testWidgets('Nepali labels', (tester) async {
      final (f,) = await open(tester, locale: const Locale('ne'));
      expect(find.text('ठीक छ'), findsOneWidget);
      expect(find.text('बुधबार, ५ बैशाख २०८१'), findsOneWidget);
      await tester.tap(find.text('रद्द'));
      await tester.pumpAndSettle();
      expect(await f, isNull);
    });
  });

  testWidgets('localizations fall back to the ambient locale', (tester) async {
    late NepalKitStrings s;
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('ne', 'NP'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (c) {
            s = NepalKitLocalizations.of(c);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(s.isNepali, isTrue);
  });

  group('receipt output', () {
    testWidgets('bundled fonts load from package assets', (tester) async {
      final fonts = await tester.runAsync(loadReceiptFonts);
      expect(fonts, isNotNull);
    });

    testWidgets('rasterizer draws shaped Devanagari to PNG', (tester) async {
      final r = FlutterTextRasterizer();
      final out = (await tester.runAsync(
        () => r.rasterize(
          'क्षेत्री श्रेष्ठ कि र्क रु',
          fontSize: 10,
          bold: false,
          color: 0xFF000000,
        ),
      ))!;
      expect(out.png.sublist(1, 4), 'PNG'.codeUnits);
      expect(out.width, greaterThan(20));
      expect(out.height, inInclusiveRange(10, 20));
      final wrapped = (await tester.runAsync(
        () => r.rasterize(
          List.filled(20, 'नेपाली').join(' '),
          fontSize: 10,
          bold: true,
          color: 0xFF000000,
          maxWidth: 100,
        ),
      ))!;
      expect(wrapped.width, lessThanOrEqualTo(100));
      expect(
        wrapped.height,
        greaterThan(out.height * 2),
        reason: 'wrapped lines',
      );
    });

    testWidgets('builds a PDF with rasterised Nepali', (tester) async {
      final doc = ReceiptDocument(
        kind: ReceiptKind.receipt,
        number: 'R-1',
        issuedAt: DateTime(2024, 4, 17),
        business: const ReceiptParty(name: 'हिमाल हार्डवेयर', pan: '301234567'),
        lines: [ReceiptLine('पेन्ट', const Npr.rupees(2450), quantity: 2)],
        language: NepalKitLanguage.ne,
      );
      final bytes = (await tester.runAsync(() => buildReceiptPdfFlutter(doc)))!;
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
