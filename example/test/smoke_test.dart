import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nepal_kit_example/main.dart';

void main() {
  testWidgets('every demo tab except Receipt builds, in both languages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1400));
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();
    for (final lang in ['en', 'ne']) {
      if (lang == 'ne') {
        await tester.tap(find.text('नेपाली'));
        await tester.pumpAndSettle();
      }
      // Receipt renders through the printing plugin, which flutter test lacks.
      for (final tab in ['Dates', 'Money', 'Phone', 'Address', 'SMS']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lang $tab');
      }
    }
    await tester.tap(find.text('SMS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send now (mock)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('mock-1'), findsOneWidget);
  });
}
