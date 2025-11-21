import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bluetooth_provider.dart';
import '../pages/dashboard_page.dart';
import '../pages/dev_chat_page.dart';
import '../pages/bluetooth_connect_page.dart';

// Enum to manage the view state
enum AppView { dashboard, chat }

class ConnectedScreen extends StatefulWidget {
  const ConnectedScreen({super.key});

  @override
  State<ConnectedScreen> createState() => _ConnectedScreenState();
}

class _ConnectedScreenState extends State<ConnectedScreen> {
  AppView _currentView = AppView.dashboard;

  // Handles navigation when the provider state changes (e.g. disconnected)
  void _onDisconnect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.read<BluetoothProvider>().isConnected && mounted) {
        // Navigate back to the initial connection page and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BluetoothConnectPage()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();
    
    // Safety check: if disconnected, navigate back
    if (!bt.isConnected) {
      _onDisconnect();
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Choose the body widget and title based on the current view state
    Widget bodyWidget;
    String titleText;
    switch (_currentView) {
      case AppView.dashboard:
        bodyWidget = const DashboardPage();
        titleText = "Greenhouse Dashboard";
        break;
      case AppView.chat:
        bodyWidget = const DevChatPage();
        titleText = "Developer Chat";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            tooltip: "Disconnect",
            onPressed: () {
              bt.disconnect();
            },
          )
        ],
      ),
      // The Sidebar is the Drawer widget
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Greenhouse App', style: TextStyle(fontSize: 24, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Device: ${bt.device?.name ?? 'Unknown'}', style: const TextStyle(color: Colors.greenAccent)),
                  Text('Address: ${bt.device?.address ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard Mode'),
              selected: _currentView == AppView.dashboard,
              onTap: () {
                setState(() => _currentView = AppView.dashboard);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Chat Mode (Dev)'),
              selected: _currentView == AppView.chat,
              onTap: () {
                setState(() => _currentView = AppView.chat);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: bodyWidget,
    );
  }
}