import 'package:flutter_test/flutter_test.dart';
import 'package:vorrat/api/client.dart';
import 'package:vorrat/models/models.dart';
import 'package:vorrat/state/settings_provider.dart';
import 'package:vorrat/state/stock_provider.dart';

// effectiveExpiryDate defaults to bbd when not given, matching the
// backend's own fallback (effective expiry == best_before_date when there's
// no opened_at/open-shelf-life override) -- see StockOverviewItem's
// effective_expiry_date docstring in backend/app/schemas.py.
StockItem _item({required String name, DateTime? bbd, DateTime? effectiveExpiry}) => StockItem(
  id: name.hashCode,
  productId: 1,
  amount: 1,
  productName: name,
  bestBeforeDate: bbd,
  effectiveExpiryDate: effectiveExpiry ?? bbd,
  status: 'ok',
);

void main() {
  test('expiryBreakdown buckets by best-before date, skipping empty buckets', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    final today = DateTime.now();
    provider.items = [
      _item(name: 'Old Milk', bbd: today.subtract(const Duration(days: 2))),
      _item(name: 'Todays Bread', bbd: DateTime(today.year, today.month, today.day)),
      _item(name: 'Soon Cheese', bbd: today.add(const Duration(days: 5))),
      _item(name: 'Far Rice', bbd: today.add(const Duration(days: 30))),
      _item(name: 'No Date Salt'),
    ];

    final buckets = {for (final b in provider.expiryBreakdown) b.key: b.items};

    expect(buckets[ExpiryBucketKey.expired]!.single.productName, 'Old Milk');
    expect(buckets[ExpiryBucketKey.today]!.single.productName, 'Todays Bread');
    expect(buckets[ExpiryBucketKey.thisWeek]!.single.productName, 'Soon Cheese');
    expect(buckets[ExpiryBucketKey.later]!.single.productName, 'Far Rice');
    expect(buckets[ExpiryBucketKey.noDate]!.single.productName, 'No Date Salt');
  });

  test('omits buckets with no items', () {
    final provider = StockProvider(ApiClient(SettingsProvider()));
    provider.items = [_item(name: 'Only This', bbd: DateTime.now())];

    expect(provider.expiryBreakdown.map((b) => b.key).toList(), [ExpiryBucketKey.today]);
  });

  test(
    'an opened batch with no best-before date buckets by effectiveExpiryDate, not into noDate (#225)',
    () {
      final provider = StockProvider(ApiClient(SettingsProvider()));
      final today = DateTime.now();
      provider.items = [
        // No bestBeforeDate at all -- only opened_at + open shelf life (as
        // the backend would compute) gives it an expiry, landing it in
        // "today" instead of the noDate bucket the old bbd-only logic would
        // have produced.
        _item(name: 'Opened Yogurt', effectiveExpiry: DateTime(today.year, today.month, today.day)),
      ];

      final buckets = {for (final b in provider.expiryBreakdown) b.key: b.items};

      expect(buckets[ExpiryBucketKey.today]!.single.productName, 'Opened Yogurt');
      expect(buckets.containsKey(ExpiryBucketKey.noDate), isFalse);
    },
  );

  test(
    'an open-shelf-life expiry earlier than the best-before date drives the bucket (#225)',
    () {
      final provider = StockProvider(ApiClient(SettingsProvider()));
      final today = DateTime.now();
      provider.items = [
        _item(
          name: 'Opened Jam',
          bbd: today.add(const Duration(days: 30)),
          effectiveExpiry: DateTime(today.year, today.month, today.day),
        ),
      ];

      final buckets = {for (final b in provider.expiryBreakdown) b.key: b.items};

      expect(buckets[ExpiryBucketKey.today]!.single.productName, 'Opened Jam');
      expect(buckets.containsKey(ExpiryBucketKey.later), isFalse);
    },
  );
}
