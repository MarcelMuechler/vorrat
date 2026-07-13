import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _serverUrlKey = 'server_url';

class SettingsProvider extends ChangeNotifier {
  String _serverUrl = '';

  String get serverUrl => _serverUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString(_serverUrlKey) ?? '';
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    _serverUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, _serverUrl);
    notifyListeners();
  }
}
