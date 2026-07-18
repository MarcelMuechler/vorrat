import 'package:flutter_test/flutter_test.dart';
import 'package:vorrat/api/client.dart';
import 'package:vorrat/models/models.dart';
import 'package:vorrat/state/settings_provider.dart';
import 'package:vorrat/state/stock_provider.dart';

/// listStock's delay is keyed by the search text so the test can make an
/// older request resolve after a newer one -- follows the FakeApiClient
/// pattern used by stock_selection_mode_test.dart etc.
class FakeApiClient extends ApiClient {
  FakeApiClient(super.settings, this.delays);

  final Map<String, Duration> delays;

  @override
  Future<List<StockItem>> listStock({
    int? locationId,
    int? productId,
    String? search,
    int? expiringWithinDays,
    int? categoryId,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(delays[search] ?? Duration.zero);
    return [StockItem(id: 1, productId: 1, amount: 1, productName: search ?? '', status: 'ok')];
  }
}

void main() {
  test('a slower old search completing after a faster new one does not overwrite it (#233)', () async {
    final api = FakeApiClient(SettingsProvider(), {
      'old': const Duration(milliseconds: 50),
      'new': Duration.zero,
    });
    final provider = StockProvider(api);

    provider.searchFilter = 'old';
    final oldRefresh = provider.refresh();

    provider.searchFilter = 'new';
    final newRefresh = provider.refresh();

    await Future.wait([oldRefresh, newRefresh]);

    expect(provider.items.single.productName, 'new');
    expect(provider.loading, isFalse);
  });
}
