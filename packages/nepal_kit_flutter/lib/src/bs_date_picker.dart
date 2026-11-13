import 'package:flutter/widgets.dart';
import 'package:nepal_kit/nepal_kit.dart';

import 'bs_calendar.dart';
import 'localizations.dart';
import 'theme.dart';

/// Shows a Bikram Sambat date picker and returns the chosen day, or null
/// when dismissed.
///
/// Built on `showGeneralDialog` from the widgets layer, so it needs no
/// Material or Cupertino ancestor. Bounds are clamped to the table
/// ([BsDate.min]..[BsDate.max]). Convert the result with
/// [BsDate.toAdLocal] where an API wants an AD [DateTime].
Future<BsDate?> showBsDatePicker({
  required BuildContext context,
  BsDate? initialDate,
  BsDate? firstDate,
  BsDate? lastDate,
  String? helpText,
  bool showAdDates = true,
  Set<BsDate> markedDates = const {},
}) {
  final first = _max(firstDate ?? BsDate.min, BsDate.min);
  final last = _min(lastDate ?? BsDate.max, BsDate.max);
  if (last.isBefore(first)) {
    throw ArgumentError('lastDate is before firstDate');
  }
  var initial = initialDate ?? BsDate.today();
  if (initial.isBefore(first)) initial = first;
  if (initial.isAfter(last)) initial = last;
  final theme = NepalKitTheme.of(context);
  final s = NepalKitLocalizations.of(context);
  return showGeneralDialog<BsDate>(
    context: context,
    barrierDismissible: true,
    barrierLabel: s.cancel,
    barrierColor: theme.barrier,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (context, _, _) => BsDatePickerDialog(
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: helpText,
      showAdDates: showAdDates,
      markedDates: markedDates,
      onDone: (d) => Navigator.of(context).pop(d),
    ),
    transitionBuilder: (context, a, _, child) =>
        FadeTransition(opacity: a, child: child),
  );
}

BsDate _max(BsDate a, BsDate b) => a.isAfter(b) ? a : b;
BsDate _min(BsDate a, BsDate b) => a.isBefore(b) ? a : b;

/// The date picker's content: a header, a [BsMonthCalendar] (or a
/// month/year chooser after tapping the title) and Today / Cancel / OK.
///
/// Use [showBsDatePicker] for a dialog, or place this inline.
class BsDatePickerDialog extends StatefulWidget {
  /// A picker.
  const BsDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDone,
    this.helpText,
    this.showAdDates = true,
    this.markedDates = const {},
  });

  /// Initially selected day.
  final BsDate initialDate;

  /// Earliest day.
  final BsDate firstDate;

  /// Latest day.
  final BsDate lastDate;

  /// Called with the chosen day, or null for Cancel.
  final ValueChanged<BsDate?> onDone;

  /// Header text; defaults to "Select date".
  final String? helpText;

  /// Show AD dates in the cells.
  final bool showAdDates;

  /// Days with a dot.
  final Set<BsDate> markedDates;

  @override
  State<BsDatePickerDialog> createState() => _BsDatePickerDialogState();
}

class _BsDatePickerDialogState extends State<BsDatePickerDialog> {
  late BsDate _selected = widget.initialDate;
  late BsDate _month = widget.initialDate.firstOfMonth;
  bool _choosingMonth = false;
  late int _chooserYear = widget.initialDate.year;

  @override
  Widget build(BuildContext context) {
    final theme = NepalKitTheme.of(context);
    final s = NepalKitLocalizations.of(context);
    final lang = s.language;
    final today = BsDate.today();
    final todayAllowed =
        !today.isBefore(widget.firstDate) && !today.isAfter(widget.lastDate);

    Widget button(String label, VoidCallback? onTap, {bool primary = false}) =>
        Semantics(
          button: true,
          enabled: onTap != null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: primary
                  ? BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onTap == null
                      ? theme.outline
                      : primary
                      ? theme.onPrimary
                      : theme.primary,
                ),
              ),
            ),
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(theme.radius),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 24,
                  color: Color(0x33000000),
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: DefaultTextStyle(
                style: TextStyle(color: theme.onSurface, fontSize: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.helpText ?? s.selectDate,
                            style: TextStyle(fontSize: 12, color: theme.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NepaliDateFormat.full(lang).formatBs(_selected),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: theme.onSurface,
                            ),
                          ),
                          if (widget.showAdDates)
                            Text(
                              NepaliDateFormat(
                                'd MMMM yyyy G',
                                language: lang,
                              ).formatAd(_selected.toAd()),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_choosingMonth)
                      _MonthChooser(
                        year: _chooserYear,
                        firstDate: widget.firstDate,
                        lastDate: widget.lastDate,
                        current: _month,
                        onYear: (y) => setState(() => _chooserYear = y),
                        onPicked: (m) => setState(() {
                          _month = m;
                          _choosingMonth = false;
                        }),
                      )
                    else
                      BsMonthCalendar(
                        month: _month,
                        selected: _selected,
                        firstDate: widget.firstDate,
                        lastDate: widget.lastDate,
                        markedDates: widget.markedDates,
                        showAdDates: widget.showAdDates,
                        onMonthChanged: (m) => setState(() => _month = m),
                        onDateSelected: (d) => setState(() => _selected = d),
                        onTitleTap: () => setState(() {
                          _chooserYear = _month.year;
                          _choosingMonth = true;
                        }),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        button(
                          s.today,
                          todayAllowed
                              ? () => setState(() {
                                  _selected = today;
                                  _month = today.firstOfMonth;
                                  _choosingMonth = false;
                                })
                              : null,
                        ),
                        const Spacer(),
                        button(s.cancel, () => widget.onDone(null)),
                        const SizedBox(width: 4),
                        button(
                          s.ok,
                          () => widget.onDone(_selected),
                          primary: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthChooser extends StatelessWidget {
  const _MonthChooser({
    required this.year,
    required this.firstDate,
    required this.lastDate,
    required this.current,
    required this.onYear,
    required this.onPicked,
  });

  final int year;
  final BsDate firstDate, lastDate, current;
  final ValueChanged<int> onYear;
  final ValueChanged<BsDate> onPicked;

  @override
  Widget build(BuildContext context) {
    final theme = NepalKitTheme.of(context);
    final s = NepalKitLocalizations.of(context);
    final ne = s.isNepali;
    String n(int v) => ne ? toDevanagariDigits('$v') : '$v';
    Widget step(String glyph, int to) {
      final ok = to >= firstDate.year && to <= lastDate.year;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: ok ? () => onYear(to) : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Text(
              glyph,
              style: TextStyle(
                fontSize: 26,
                color: ok ? theme.onSurface : theme.outline,
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
            step('‹', year - 1),
            Expanded(
              child: Center(
                child: Text(
                  n(year),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.onSurface,
                  ),
                ),
              ),
            ),
            step('›', year + 1),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < 4; row++)
          Row(
            children: [
              for (var col = 0; col < 3; col++)
                Expanded(child: _month(theme, s, row * 3 + col + 1)),
            ],
          ),
      ],
    );
  }

  Widget _month(NepalKitThemeData theme, NepalKitStrings s, int m) {
    final first = BsDate(year, m, 1);
    final ok =
        !first.lastOfMonth.isBefore(firstDate) && !first.isAfter(lastDate);
    final isCurrent = current.year == year && current.month == m;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: ok ? () => onPicked(first) : null,
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrent ? theme.primary : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          s.bsMonths[m - 1],
          style: TextStyle(
            fontSize: 14,
            color: !ok
                ? theme.outline
                : isCurrent
                ? theme.onPrimary
                : theme.onSurface,
          ),
        ),
      ),
    );
  }
}
