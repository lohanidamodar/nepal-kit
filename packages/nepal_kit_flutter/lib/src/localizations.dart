import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nepal_kit/nepal_kit.dart';

/// nepal_kit's ne/en strings for the current locale.
///
/// Add [NepalKitLocalizations.delegate] to your app's
/// `localizationsDelegates`. Without it, widgets fall back to the
/// ambient [Localizations] locale, and then to English. Any locale other
/// than Nepali gets English.
class NepalKitLocalizations {
  /// Strings for [language].
  const NepalKitLocalizations(this.language);

  /// The language in use.
  final NepalKitLanguage language;

  /// The strings.
  NepalKitStrings get strings => NepalKitStrings.of(language);

  /// The delegate.
  static const LocalizationsDelegate<NepalKitLocalizations> delegate =
      _Delegate();

  /// Locales with their own strings.
  static const List<Locale> supportedLocales = [Locale('en'), Locale('ne')];

  /// The strings for [context]'s locale.
  static NepalKitStrings of(BuildContext context) =>
      languageOf(context) == NepalKitLanguage.ne
      ? NepalKitStrings.ne
      : NepalKitStrings.en;

  /// The language for [context]: a [NepalKitLanguageScope] if there is
  /// one, else the delegate if registered, else the ambient locale.
  static NepalKitLanguage languageOf(BuildContext context) {
    final scoped = context
        .dependOnInheritedWidgetOfExactType<NepalKitLanguageScope>()
        ?.language;
    if (scoped != null) return scoped;
    final l = Localizations.of<NepalKitLocalizations>(
      context,
      NepalKitLocalizations,
    );
    if (l != null) return l.language;
    final locale = Localizations.maybeLocaleOf(context);
    return locale == null
        ? NepalKitLanguage.en
        : NepalKitLanguage.fromCode(locale.languageCode);
  }
}

class _Delegate extends LocalizationsDelegate<NepalKitLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<NepalKitLocalizations> load(Locale locale) => SynchronousFuture(
    NepalKitLocalizations(NepalKitLanguage.fromCode(locale.languageCode)),
  );

  @override
  bool shouldReload(_Delegate old) => false;
}

/// Sets nepal_kit's language for a subtree, whatever the app locale.
///
/// For apps whose own UI stays in one language while dates, numbers and
/// receipts follow a separate setting (a "show dates in Nepali" switch),
/// or whose design system has no Nepali localizations.
class NepalKitLanguageScope extends InheritedWidget {
  /// Uses [language] below this widget.
  const NepalKitLanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  /// The language.
  final NepalKitLanguage language;

  @override
  bool updateShouldNotify(NepalKitLanguageScope oldWidget) =>
      language != oldWidget.language;
}
