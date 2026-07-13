import 'package:flutter_test/flutter_test.dart';
import 'package:vorrat/api/client.dart';
import 'package:vorrat/models/models.dart';
import 'package:vorrat/state/settings_provider.dart';
import 'package:vorrat/state/stock_provider.dart';

StockItem _item({required String name, required double amount, String? location}) => StockItem(
  id: name.hashCode,
  productId: 1,
  amount: amount,
  productName: name,
  locationName: location,
  status: 'ok',
);

void main() {
  test('sortedItems orders by the selected StockSort', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    provider.items = [
      _item(name: 'Milk', amount: 3, location: 'Fridge'),
      _item(name: 'Apples', amount: 1, location: 'Pantry'),
      _item(name: 'Bread', amount: 2),
    ];

    provider.setSort(StockSort.name);
    expect(provider.sortedItems.map((e) => e.productName), ['Apples', 'Bread', 'Milk']);

    provider.setSort(StockSort.amount);
    expect(provider.sortedItems.map((e) => e.amount), [1, 2, 3]);

    provider.setSort(StockSort.location);
    expect(provider.sortedItems.map((e) => e.locationName), [null, 'Fridge', 'Pantry']);
  });
}
