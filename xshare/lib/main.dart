import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ui/send_page.dart';
import 'ui/receive_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SarShareApp());
}

class SarShareApp extends StatelessWidget {
  const SarShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAR SHARE',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Keep screen awake during transfers
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const SendPage(),
      const ReceivePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SAR SHARE'),
      ),
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.upload), label: 'Send'),
          NavigationDestination(icon: Icon(Icons.download), label: 'Receive'),
        ],
      ),
    );
  }
}