import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api/client.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/stock_overview_screen.dart';
import 'state/settings_provider.dart';
import 'state/stock_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();
  runApp(VorratApp(settings: settings));
}

class VorratApp extends StatelessWidget {
  final SettingsProvider settings;

  const VorratApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ProxyProvider<SettingsProvider, ApiClient>(
          update: (_, settings, _) => ApiClient(settings),
        ),
        ChangeNotifierProxyProvider<ApiClient, StockProvider>(
          create: (context) => StockProvider(context.read<ApiClient>()),
          update: (_, api, previous) => previous ?? StockProvider(api),
        ),
      ],
      child: MaterialApp(
        title: 'Vorrat',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [StockOverviewScreen(), ScanScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.kitchen), label: 'Stock'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
