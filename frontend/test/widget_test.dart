import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vorrat/main.dart';
import 'package:vorrat/state/scan_history.dart';
import 'package:vorrat/state/scan_queue.dart';
import 'package:vorrat/state/settings_provider.dart';

void main() {
  testWidgets('app boots to the Stock tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      VorratApp(settings: SettingsProvider(), scanQueue: ScanQueue(), scanHistory: ScanHistory()),
    );
    await tester.pump();

    expect(find.text('Stock'), findsWidgets);
  });

  testWidgets('wide screens show a NavigationRail instead of the bottom bar', (
    WidgetTester tester,
  ) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });

    await tester.pumpWidget(
      VorratApp(settings: SettingsProvider(), scanQueue: ScanQueue(), scanHistory: ScanHistory()),
    );
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
