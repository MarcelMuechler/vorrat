import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../models/models.dart';

enum StockSort { bestBeforeDate, name, amount, location }

class StockProvider extends ChangeNotifier {
  final ApiClient api;

  StockProvider(this.api);

  List<StockItem> items = [];
  bool loading = false;
  String? error;
  int? expiringWithinDaysFilter;
  int? locationIdFilter;
  String searchFilter = '';
  StockSort sort = StockSort.bestBeforeDate;
  int expiringSoonDays = 3;

  /// [items] sorted client-side -- the list is already fully fetched, and
  /// re-querying the API just to change ordering would be wasteful.
  List<StockItem> get sortedItems {
    final sorted = [...items];
    switch (sort) {
      case StockSort.bestBeforeDate:
        break; // already the API's default order
      case StockSort.name:
        sorted.sort((a, b) => a.productName.compareTo(b.productName));
      case StockSort.amount:
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
      case StockSort.location:
        sorted.sort((a, b) => (a.locationName ?? '').compareTo(b.locationName ?? ''));
    }
    return sorted;
  }

  void setSort(StockSort value) {
    sort = value;
    notifyListeners();
  }

  Future<void> loadExpiringSoonDays() async {
    try {
      expiringSoonDays = await api.getExpiringSoonDays();
      notifyListeners();
    } catch (_) {
      // Keep the built-in default (matches the backend's own fallback) --
      // the stock list's own error state already surfaces connectivity
      // issues, no need for a second one here.
    }
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await api.listStock(
        expiringWithinDays: expiringWithinDaysFilter,
        locationId: locationIdFilter,
        search: searchFilter.isEmpty ? null : searchFilter,
      );
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setExpiringFilter(int? days) async {
    expiringWithinDaysFilter = days;
    await refresh();
  }

  Future<void> setLocationFilter(int? locationId) async {
    locationIdFilter = locationId;
    await refresh();
  }

  Future<void> setSearchFilter(String value) async {
    searchFilter = value;
    await refresh();
  }

  Future<void> delete(int id) async {
    await api.deleteStock(id);
    await refresh();
  }

  Future<void> consume(int id, double amount) async {
    await api.consumeStock(id, amount);
    await refresh();
  }
}
