import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vorrat/api/client.dart';
import 'package:vorrat/l10n/app_localizations.dart';
import 'package:vorrat/models/models.dart';
import 'package:vorrat/screens/product_detail_screen.dart';
import 'package:vorrat/state/settings_provider.dart';
import 'package:vorrat/state/stock_provider.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient(super.settings);
  @override
  Future<List<Location>> listLocations() async => [];
}

void main() {
  testWidgets('shows OFF hint and image when prefilled', (tester) async {
    final settings = SettingsProvider();
    final api = FakeApiClient(settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          Provider<ApiClient>.value(value: api),
          ChangeNotifierProvider<StockProvider>(create: (_) => StockProvider(api)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductDetailScreen(
            barcode: '123',
            prefill: ProductPrefill(barcode: '123', name: 'Milk', imageUrl: 'https://example.com/milk.png'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('From Open Food Facts'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
