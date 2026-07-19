import 'package:flutter_test/flutter_test.dart';
import 'package:vorrat/api/client.dart';
import 'package:vorrat/models/models.dart';
import 'package:vorrat/state/settings_provider.dart';
import 'package:vorrat/state/stock_provider.dart';

StockItem _item({
  required int productId,
  required String name,
  required double amount,
  required String status,
  String? location,
  double? lowStockThreshold,
}) => StockItem(
  id: amount.hashCode ^ productId,
  productId: productId,
  amount: amount,
  productName: name,
  locationName: location,
  status: status,
  lowStockThreshold: lowStockThreshold,
);

void main() {
  test('groupedItems sums amount and takes the worst status per product', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    provider.items = [
      _item(productId: 1, name: 'Milk', amount: 2, status: 'ok', location: 'Fridge'),
      _item(productId: 1, name: 'Milk', amount: 1, status: 'expired', location: 'Pantry'),
      _item(productId: 2, name: 'Bread', amount: 3, status: 'ok'),
    ];
    // No filter active in this scenario -- allItems mirrors items, same as
    // what StockProvider.refresh() would populate.
    provider.allItems = provider.items;

    final groups = {for (final g in provider.groupedItems) g.productId: g};

    expect(groups[1]!.totalAmount, 3);
    expect(groups[1]!.status, 'expired');
    expect(groups[1]!.locationNames, {'Fridge', 'Pantry'});

    expect(groups[2]!.totalAmount, 3);
    expect(groups[2]!.status, 'ok');
    expect(groups[2]!.locationNames, isEmpty);
  });

  test('isLowStock flags a product at or below its threshold, ignores products with none set', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    provider.items = [
      _item(productId: 1, name: 'Flour', amount: 0.2, status: 'ok', lowStockThreshold: 0.5),
      _item(productId: 2, name: 'Milk', amount: 5, status: 'ok', lowStockThreshold: 1),
      _item(productId: 3, name: 'Bread', amount: 1, status: 'ok'),
    ];
    provider.allItems = provider.items;

    final groups = {for (final g in provider.groupedItems) g.productId: g};

    expect(groups[1]!.isLowStock, isTrue);
    expect(groups[2]!.isLowStock, isFalse);
    expect(groups[3]!.isLowStock, isFalse);
  });

  // #255: "X insgesamt" used to sum whatever survived the active filter
  // (items/sortedItems) instead of the product's true total, so toggling a
  // filter chip made the same product's displayed total silently shrink.
  test('groupedItems totalAmount reflects the true stock, not a filtered subtotal', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    // allItems is the full, unfiltered stock: 22 units of Milk across two
    // batches, only one of which ("expiring_soon") survives an active
    // expiring-soon filter.
    provider.allItems = [
      _item(productId: 1, name: 'Milk', amount: 18, status: 'ok', location: 'Fridge'),
      _item(productId: 1, name: 'Milk', amount: 4, status: 'expiring_soon', location: 'Fridge'),
      _item(productId: 2, name: 'Bread', amount: 3, status: 'ok'),
    ];
    // items/sortedItems is what the "Bald ablaufend" filter narrows the API
    // response down to -- only Milk's expiring batch, and nothing of Bread.
    provider.items = [
      _item(productId: 1, name: 'Milk', amount: 4, status: 'expiring_soon', location: 'Fridge'),
    ];

    final groups = {for (final g in provider.groupedItems) g.productId: g};

    // Milk still shows its true total (22), not the filtered subtotal (4).
    expect(groups[1]!.totalAmount, 22);
    // Bread has no batches left under the filter, so it gets no row at all.
    expect(groups.containsKey(2), isFalse);
  });

  test('groupedItems does not double count when allItems and items overlap', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    provider.allItems = [
      _item(productId: 1, name: 'Milk', amount: 2, status: 'ok'),
      _item(productId: 1, name: 'Milk', amount: 1, status: 'ok'),
    ];
    provider.items = provider.allItems;

    final groups = {for (final g in provider.groupedItems) g.productId: g};

    expect(groups[1]!.totalAmount, 3);
  });
}
