import 'package:flutter/widgets.dart';

/// Colours and text styles for nepal_kit widgets.
///
/// The widgets use only `package:flutter/widgets.dart`, so they work in
/// apps on Flutter's built-in Material, on `package:material_ui`, on
/// Cupertino, or on none. Map your design system onto this once, near the
/// root:
///
/// ```dart
/// NepalKitTheme(
///   data: NepalKitThemeData(
///     primary: scheme.primary,
///     onPrimary: scheme.onPrimary,
///     surface: scheme.surfaceContainerHigh,
///     onSurface: scheme.onSurface,
///     muted: scheme.onSurfaceVariant,
///     outline: scheme.outlineVariant,
///   ),
///   child: ...,
/// )
/// ```
@immutable
class NepalKitThemeData {
  /// A theme; the defaults are a neutral light scheme.
  const NepalKitThemeData({
    this.primary = const Color(0xFF1565C0),
    this.onPrimary = const Color(0xFFFFFFFF),
    this.surface = const Color(0xFFFFFFFF),
    this.onSurface = const Color(0xFF1C1B1F),
    this.muted = const Color(0xFF6B6B70),
    this.outline = const Color(0xFFD0D0D6),
    this.holiday = const Color(0xFFC62828),
    this.barrier = const Color(0x8A000000),
    this.radius = 16,
  });

  /// Selection and accents.
  final Color primary;

  /// Text on [primary].
  final Color onPrimary;

  /// Background of the calendar and dialog.
  final Color surface;

  /// Main text.
  final Color onSurface;

  /// Secondary text (weekday headers, AD dates, disabled days).
  final Color muted;

  /// Borders (today's ring uses [primary]).
  final Color outline;

  /// Saturdays, the public holiday of the Nepali week.
  final Color holiday;

  /// Modal barrier behind the date picker.
  final Color barrier;

  /// Corner radius of the dialog.
  final double radius;

  /// A copy with the given fields replaced.
  NepalKitThemeData copyWith({
    Color? primary,
    Color? onPrimary,
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? outline,
    Color? holiday,
    Color? barrier,
    double? radius,
  }) => NepalKitThemeData(
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    surface: surface ?? this.surface,
    onSurface: onSurface ?? this.onSurface,
    muted: muted ?? this.muted,
    outline: outline ?? this.outline,
    holiday: holiday ?? this.holiday,
    barrier: barrier ?? this.barrier,
    radius: radius ?? this.radius,
  );

  @override
  bool operator ==(Object other) =>
      other is NepalKitThemeData &&
      other.primary == primary &&
      other.onPrimary == onPrimary &&
      other.surface == surface &&
      other.onSurface == onSurface &&
      other.muted == muted &&
      other.outline == outline &&
      other.holiday == holiday &&
      other.barrier == barrier &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(
    primary,
    onPrimary,
    surface,
    onSurface,
    muted,
    outline,
    holiday,
    barrier,
    radius,
  );
}

/// Provides [NepalKitThemeData] to nepal_kit widgets below it.
class NepalKitTheme extends InheritedWidget {
  /// Applies [data] to [child].
  const NepalKitTheme({super.key, required this.data, required super.child});

  /// The theme.
  final NepalKitThemeData data;

  /// The nearest theme, or the defaults.
  static NepalKitThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NepalKitTheme>()?.data ??
      const NepalKitThemeData();

  @override
  bool updateShouldNotify(NepalKitTheme oldWidget) => data != oldWidget.data;
}
