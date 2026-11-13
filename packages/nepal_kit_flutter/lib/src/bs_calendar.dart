import 'package:flutter/widgets.dart';
import 'package:nepal_kit/nepal_kit.dart';

import 'localizations.dart';
import 'theme.dart';

/// Builds one day cell of a [BsMonthCalendar]. Return null to use the
/// default cell.
typedef BsDayBuilder =
    Widget? Function(BuildContext context, BsDate date, BsDayState state);

/// What a day cell shows.
class BsDayState {
  /// A state.
  const BsDayState({
    required this.selected,
    required this.today,
    required this.enabled,
    required this.marked,
  });

  /// The selected day.
  final bool selected;

  /// Today (in Nepal).
  final bool today;

  /// Inside the allowed range.
  final bool enabled;

  /// Listed in [BsMonthCalendar.markedDates].
  final bool marked;
}

/// A BS month view: a header with the month (and the AD months it spans),
/// weekday names, and the days, each with its AD date in small type.
///
/// Controlled: it shows [month] and reports [onMonthChanged]; tapping a
/// day reports [onDateSelected].
class BsMonthCalendar extends StatelessWidget {
  /// A month view.
  const BsMonthCalendar({
    super.key,
    required this.month,
    this.selected,
    this.onDateSelected,
    this.onMonthChanged,
    this.onTitleTap,
    this.firstDate,
    this.lastDate,
    this.markedDates = const {},
    this.showAdDates = true,
    this.firstWeekday = DateTime.sunday,
    this.dayBuilder,
    this.today,
    this.cellHeight = 48,
  });

  /// Any day of the month to show.
  final BsDate month;

  /// The selected day.
  final BsDate? selected;

  /// Called with the tapped day.
  final ValueChanged<BsDate>? onDateSelected;

  /// Called with the 1st of the month to show when the arrows are used.
  final ValueChanged<BsDate>? onMonthChanged;

  /// Called when the month title is tapped (the picker opens its
  /// month/year chooser).
  final VoidCallback? onTitleTap;

  /// Earliest day that can be picked.
  final BsDate? firstDate;

  /// Latest day that can be picked.
  final BsDate? lastDate;

  /// Days that get a dot (events, due dates).
  final Set<BsDate> markedDates;

  /// Show each day's AD date under it.
  final bool showAdDates;

  /// First column ([DateTime] weekday numbering); Sunday as Nepali
  /// calendars print it.
  final int firstWeekday;

  /// Custom day cells.
  final BsDayBuilder? dayBuilder;

  /// Overrides today (for tests and previews).
  final BsDate? today;

  /// Height of each day cell; cells are as wide as the calendar allows.
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final theme = NepalKitTheme.of(context);
    final s = NepalKitLocalizations.of(context);
    final ne = s.isNepali;
    final grid = BsMonthGrid.of(month, firstWeekday: firstWeekday);
    final todayDate = today ?? BsDate.today();
    final first = grid.first, last = first.lastOfMonth;
    final adStart = first.toAd(), adEnd = last.toAd();
    String adMonth(DateTime d) => s.adMonthsShort[d.month - 1];
    final adSpan = adStart.year == adEnd.year
        ? '${adMonth(adStart)}/${adMonth(adEnd)} ${_n(adEnd.year, false)}'
        : '${adMonth(adStart)} ${_n(adStart.year, false)}/${adMonth(adEnd)} ${_n(adEnd.year, false)}';
    final prev = grid.previous, next = grid.next;
    bool canGo(BsMonthGrid? g) =>
        g != null &&
        (firstDate == null || !g.first.lastOfMonth.isBefore(firstDate!)) &&
        (lastDate == null || !g.first.isAfter(lastDate!));

    Widget arrow(String glyph, String label, BsMonthGrid? target) {
      final enabled = canGo(target) && onMonthChanged != null;
      return Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => onMonthChanged!(target!.first) : null,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                glyph,
                style: TextStyle(
                  fontSize: 26,
                  color: enabled ? theme.onSurface : theme.outline,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            arrow('‹', s.previousMonth, prev),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTitleTap,
                child: Semantics(
                  button: onTitleTap != null,
                  child: Column(
                    children: [
                      Text(
                        '${s.bsMonths[grid.month - 1]} ${_n(grid.year, ne)}',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: theme.onSurface,
                        ),
                      ),
                      if (showAdDates)
                        Text(
                          adSpan,
                          style: TextStyle(fontSize: 12, color: theme.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            arrow('›', s.nextMonth, next),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final wd in grid.columnWeekdays)
              Expanded(
                child: Center(
                  child: Text(
                    s.weekdaysNarrow[wd - 1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: wd == DateTime.saturday
                          ? theme.holiday
                          : theme.muted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final week in grid.weeks)
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: SizedBox(
                    height: cellHeight,
                    child: day == null
                        ? const SizedBox()
                        : _cell(context, theme, day, todayDate, ne),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context,
    NepalKitThemeData theme,
    BsDate day,
    BsDate todayDate,
    bool ne,
  ) {
    final enabled =
        (firstDate == null || !day.isBefore(firstDate!)) &&
        (lastDate == null || !day.isAfter(lastDate!));
    final state = BsDayState(
      selected: day == selected,
      today: day == todayDate,
      enabled: enabled,
      marked: markedDates.contains(day),
    );
    final custom = dayBuilder?.call(context, day, state);
    final saturday = day.weekday == DateTime.saturday;
    final fg = !enabled
        ? theme.outline
        : state.selected
        ? theme.onPrimary
        : saturday
        ? theme.holiday
        : theme.onSurface;
    final ad = day.toAd();
    final label = NepaliDateFormat.full(
      ne ? NepalKitLanguage.ne : NepalKitLanguage.en,
    ).formatBs(day);
    return Semantics(
      button: enabled,
      selected: state.selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled && onDateSelected != null
            ? () => onDateSelected!(day)
            : null,
        child:
            custom ??
            Padding(
              padding: const EdgeInsets.all(2),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: state.selected ? theme.primary : null,
                  borderRadius: BorderRadius.circular(cellHeight / 2),
                  border: state.today && !state.selected
                      ? Border.all(color: theme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _n(day.day, ne),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: state.today
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                    if (showAdDates)
                      Text(
                        '${ad.day}',
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.1,
                          color: state.selected
                              ? theme.onPrimary.withValues(alpha: 0.8)
                              : theme.muted,
                        ),
                      ),
                    if (state.marked)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.selected
                              ? theme.onPrimary
                              : theme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  static String _n(int v, bool ne) => ne ? toDevanagariDigits('$v') : '$v';
}
