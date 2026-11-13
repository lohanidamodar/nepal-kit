import 'package:nepal_kit/nepal_kit.dart';
import 'package:test/test.dart';

void main() {
  final d = BsDate(2081, 1, 5); // Wednesday 17 April 2024

  test('English', () {
    expect(NepaliDateFormat.long().formatBs(d), '5 Baishakh 2081');
    expect(NepaliDateFormat.full().formatBs(d), 'Wednesday, 5 Baishakh 2081');
    expect(NepaliDateFormat.numeric().formatBs(d), '2081/01/05');
    expect(NepaliDateFormat('EEE d MMM yy G').formatBs(d), 'Wed 5 Bai 81 BS');
  });

  test('Nepali uses Devanagari digits and names', () {
    const ne = NepalKitLanguage.ne;
    expect(NepaliDateFormat.long(ne).formatBs(d), '५ बैशाख २०८१');
    expect(NepaliDateFormat.full(ne).formatBs(d), 'बुधबार, ५ बैशाख २०८१');
    expect(NepaliDateFormat.numeric(ne).formatBs(d), '२०८१/०१/०५');
    expect(
      NepaliDateFormat('d MMMM yyyy G', language: ne).formatBs(d),
      '५ बैशाख २०८१ वि.सं.',
    );
    expect(
      NepaliDateFormat(
        'd MMMM',
        language: ne,
        devanagariDigits: false,
      ).formatBs(d),
      '5 बैशाख',
    );
  });

  test('AD dates', () {
    final ad = DateTime(2024, 4, 17);
    expect(NepaliDateFormat('d MMMM yyyy G').formatAd(ad), '17 April 2024 AD');
    expect(
      NepaliDateFormat(
        'd MMMM yyyy',
        language: NepalKitLanguage.ne,
      ).formatAd(ad),
      '१७ अप्रिल २०२४',
    );
    expect(NepaliDateFormat.long().formatAdAsBs(ad), '5 Baishakh 2081');
  });

  test('quoted literals', () {
    expect(
      NepaliDateFormat("'Date:' yyyy-MM-dd").formatBs(d),
      'Date: 2081-01-05',
    );
    expect(NepaliDateFormat("d 'o''clock'").formatBs(d), "5 o'clock");
    expect(NepaliDateFormat.iso().formatBs(d), '2081-01-05');
  });

  test('every month name is there', () {
    for (var m = 1; m <= 12; m++) {
      final b = BsDate(2081, m, 1);
      expect(
        NepaliDateFormat('MMMM').formatBs(b),
        NepalKitStrings.en.bsMonths[m - 1],
      );
      expect(
        NepaliDateFormat('MMMM', language: NepalKitLanguage.ne).formatBs(b),
        NepalKitStrings.ne.bsMonths[m - 1],
      );
    }
  });

  test('month grid starts on Sunday by default', () {
    // 1 Baishakh 2081 is a Saturday: six blanks, then 31 days.
    final g = BsMonthGrid(2081, 1);
    expect(g.leadingBlanks, 6);
    expect(g.columnWeekdays.first, DateTime.sunday);
    expect(g.weeks.first.last, BsDate(2081, 1, 1));
    expect(g.weeks.expand((w) => w).whereType<BsDate>(), hasLength(31));
    expect(g.weeks.every((w) => w.length == 7), isTrue);
    final mon = BsMonthGrid(2081, 1, firstWeekday: DateTime.monday);
    expect(mon.leadingBlanks, 5);
    expect(g.previous!.month, 12);
    expect(g.next!.month, 2);
    expect(BsMonthGrid(1970, 1).previous, isNull);
    expect(BsMonthGrid(2100, 12).next, isNull);
  });
}
