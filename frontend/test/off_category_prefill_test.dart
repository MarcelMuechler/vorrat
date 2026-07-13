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
  Map<String, dynamic>? createProductPayload;

  @override
  Future<List<Location>> listLocations() async => [];

  @override
  Future<List<Category>> listCategories() async => [];

  @override
  Future<Category> createCategory(String name) async => Category(id: 7, name: name);

  @override
  Future<Product> createProduct(Map<String, dynamic> payload) async {
    createProductPayload = payload;
    return Product(id: 1, name: payload['name'] as String);
  }

  @override
  Future<void> addStock(Map<String, dynamic> payload) async {}
}

void main() {
  testWidgets('OFF category suggestion is prefilled as real text with a clear button, not just a hint (#70)', (
    tester,
  ) async {
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
            prefill: ProductPrefill(barcode: '123', name: 'Milk', category: 'Dairy'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Prefilled as real text -- not merely a hint -- so the clear button is
    // already showing without the user typing anything.
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(api.createProductPayload?['category_id'], 7);
  });

  testWidgets('clearing the prefilled category saves with no category at all', (tester) async {
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
            prefill: ProductPrefill(barcode: '123', name: 'Milk', category: 'Dairy'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(api.createProductPayload?['category_id'], isNull);
  });
}
