import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vorrat/l10n/app_localizations.dart';
import 'package:vorrat/widgets/quantity_unit_field.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('a common unit shows its localized label, no custom field', (tester) async {
    await tester.pumpWidget(_wrap(QuantityUnitField(value: 'kg', label: 'Unit', onChanged: (_) {})));
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('Custom unit'), findsNothing);
  });

  testWidgets('a value outside the fixed list starts in Other mode, prefilled', (tester) async {
    await tester.pumpWidget(_wrap(QuantityUnitField(value: 'cl', label: 'Unit', onChanged: (_) {})));
    expect(find.text('Other…'), findsOneWidget);
    expect(find.text('cl'), findsOneWidget);
  });

  testWidgets('picking Other reveals a text field, typing reports the typed value', (tester) async {
    String? reported;
    await tester.pumpWidget(
      _wrap(QuantityUnitField(value: 'pcs', label: 'Unit', onChanged: (v) => reported = v)),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other…').last);
    await tester.pumpAndSettle();

    expect(find.text('Custom unit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'crate');
    expect(reported, 'crate');
  });
}
