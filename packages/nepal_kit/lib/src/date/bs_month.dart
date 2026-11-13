import 'bs_date.dart';

/// A BS month laid out as calendar weeks, for month views and pickers.
///
/// Weeks start on [firstWeekday] ([DateTime.sunday] by default, as Nepali
/// calendars print them). Cells before the 1st and after the last day are
/// null.
class BsMonthGrid {
  /// The grid of BS [year]-[month].
  BsMonthGrid(this.year, this.month, {this.firstWeekday = DateTime.sunday})
    : assert(firstWeekday >= 1 && firstWeekday <= 7) {
    RangeError.checkValueInInterval(year, BsDate.minYear, BsDate.maxYear);
    RangeError.checkValueInInterval(month, 1, 12);
  }

  /// The grid of the month containing [date].
  factory BsMonthGrid.of(BsDate date, {int firstWeekday = DateTime.sunday}) =>
      BsMonthGrid(date.year, date.month, firstWeekday: firstWeekday);

  /// BS year.
  final int year;

  /// BS month, 1..12.
  final int month;

  /// The weekday ([DateTime] numbering) of each row's first column.
  final int firstWeekday;

  /// Days in the month.
  int get daysInMonth => BsDate.daysInMonthOf(year, month);

  /// 1st of the month.
  BsDate get first => BsDate(year, month, 1);

  /// Empty cells before the 1st.
  int get leadingBlanks => (first.weekday - firstWeekday) % 7;

  /// Weekdays ([DateTime] numbering) of the columns, in order.
  List<int> get columnWeekdays => [
    for (var i = 0; i < 7; i++) (firstWeekday - 1 + i) % 7 + 1,
  ];

  /// Rows of seven cells.
  List<List<BsDate?>> get weeks {
    final cells = <BsDate?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++) BsDate(year, month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }

  /// The previous month's grid, or null at the start of the table.
  BsMonthGrid? get previous {
    if (year == BsDate.minYear && month == 1) return null;
    return month == 1
        ? BsMonthGrid(year - 1, 12, firstWeekday: firstWeekday)
        : BsMonthGrid(year, month - 1, firstWeekday: firstWeekday);
  }

  /// The next month's grid, or null at the end of the table.
  BsMonthGrid? get next {
    if (year == BsDate.maxYear && month == 12) return null;
    return month == 12
        ? BsMonthGrid(year + 1, 1, firstWeekday: firstWeekday)
        : BsMonthGrid(year, month + 1, firstWeekday: firstWeekday);
  }
}
