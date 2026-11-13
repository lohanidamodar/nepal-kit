import 'package:material_ui/material_ui.dart';
import 'package:nepal_kit_flutter/nepal_kit_flutter.dart';

import 'demos.dart';

void main() => runApp(const ExampleApp());

/// Shows each nepal_kit component on its own tab.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // `?lang=ne&tab=receipt` opens the web build on a given demo.
  NepalKitLanguage _language = NepalKitLanguage.fromCode(
    Uri.base.queryParameters['lang'] ?? 'en',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nepal_kit',
      // The app chrome stays English; nepal_kit follows the toggle through
      // NepalKitLanguageScope. An app with flutter_localizations would set
      // `locale` and add NepalKitLocalizations.delegate instead.
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1565C0)),
      home: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          // Map the app's colours onto nepal_kit's widgets once.
          return NepalKitLanguageScope(
            language: _language,
            child: NepalKitTheme(
              data: NepalKitThemeData(
                primary: scheme.primary,
                onPrimary: scheme.onPrimary,
                surface: scheme.surfaceContainerHigh,
                onSurface: scheme.onSurface,
                muted: scheme.onSurfaceVariant,
                outline: scheme.outlineVariant,
                holiday: scheme.error,
              ),
              child: Home(
                nepali: _language == NepalKitLanguage.ne,
                onToggleLanguage: () => setState(
                  () => _language = _language == NepalKitLanguage.ne
                      ? NepalKitLanguage.en
                      : NepalKitLanguage.ne,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key, required this.nepali, required this.onToggleLanguage});

  final bool nepali;
  final VoidCallback onToggleLanguage;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Dates', 'Money', 'Phone', 'Address', 'Receipt', 'SMS'];
    final initial = tabs.indexWhere(
      (t) => t.toLowerCase() == Uri.base.queryParameters['tab'],
    );
    return DefaultTabController(
      length: tabs.length,
      initialIndex: initial < 0 ? 0 : initial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('nepal_kit'),
          actions: [
            TextButton(
              onPressed: onToggleLanguage,
              child: Text(nepali ? 'English' : 'नेपाली'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final t in tabs) Tab(text: t)],
          ),
        ),
        body: const TabBarView(
          children: [
            DatesDemo(),
            MoneyDemo(),
            PhoneDemo(),
            AddressDemo(),
            ReceiptDemo(),
            SmsDemo(),
          ],
        ),
      ),
    );
  }
}
