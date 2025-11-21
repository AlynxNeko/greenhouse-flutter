import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/bluetooth_provider.dart';
import 'providers/status_provider.dart';
import 'providers/history_provider.dart';
import 'pages/bluetooth_connect_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(
          create: (ctx) => StatusProvider(ctx.read<HistoryProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => BluetoothProvider()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const BluetoothConnectPage(),
    );
  }
}
