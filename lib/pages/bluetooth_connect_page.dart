import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';

import '../providers/bluetooth_provider.dart';
import '../providers/status_provider.dart';
import 'dashboard_page.dart';

class BluetoothConnectPage extends StatefulWidget {
  const BluetoothConnectPage({super.key});

  @override
  State<BluetoothConnectPage> createState() => _BluetoothConnectPageState();
}

class _BluetoothConnectPageState extends State<BluetoothConnectPage> {
  List<BluetoothDevice> devices = [];

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  Future<void> loadDevices() async {
    devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    final status = context.read<StatusProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Select Device")),
      body: ListView(
        children: devices.map((d) {
          return ListTile(
            title: Text(d.name ?? 'Unknown'),
            subtitle: Text(d.address),
            onTap: () async {
              await bt.connect(d, status);
              if (bt.isConnected) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
