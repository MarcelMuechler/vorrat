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
}) => StockItem(
  id: amount.hashCode ^ productId,
  productId: productId,
  amount: amount,
  productName: name,
  locationName: location,
  status: status,
);

void main() {
  test('groupedItems sums amount and takes the worst status per product', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    provider.items = [
      _item(productId: 1, name: 'Milk', amount: 2, status: 'ok', location: 'Fridge'),
      _item(productId: 1, name: 'Milk', amount: 1, status: 'expired', location: 'Pantry'),
      _item(productId: 2, name: 'Bread', amount: 3, status: 'ok'),
    ];

    final groups = {for (final g in provider.groupedItems) g.productId: g};

    expect(groups[1]!.totalAmount, 3);
    expect(groups[1]!.status, 'expired');
    expect(groups[1]!.locationNames, {'Fridge', 'Pantry'});

    expect(groups[2]!.totalAmount, 3);
    expect(groups[2]!.status, 'ok');
    expect(groups[2]!.locationNames, isEmpty);
  });
}
