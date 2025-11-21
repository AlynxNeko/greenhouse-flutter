import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../providers/bluetooth_provider.dart';
import '../providers/status_provider.dart';
import 'connected_screen.dart'; // <--- NEW IMPORT

class BluetoothConnectPage extends StatefulWidget {
  const BluetoothConnectPage({super.key});

  @override
  State<BluetoothConnectPage> createState() => _BluetoothConnectPageState();
}

class _BluetoothConnectPageState extends State<BluetoothConnectPage> {
  List<BluetoothDevice> devices = [];
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  Future<void> initBluetooth() async {
    await context.read<BluetoothProvider>().requestBluetoothPermissions();
    await getBondedDevices();
  }

  Future<void> getBondedDevices() async {
    if (await Permission.bluetoothScan.isGranted && await Permission.bluetoothConnect.isGranted) {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {});
    } else {
      setState(() {});
    }
  }

  void connect(BluetoothDevice d) async {
    if (isConnecting) return;
    setState(() => isConnecting = true);

    final bt = context.read<BluetoothProvider>();
    final status = context.read<StatusProvider>();
    
    final success = await bt.connect(d, status);

    if (mounted) {
      setState(() => isConnecting = false);
      if (success) {
        // Navigate to the main application screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConnectedScreen()), 
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to ${d.name ?? 'device'}.')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothProvider>();

    if (bt.isConnected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConnectedScreen()));
        });
        return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Device"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isConnecting ? null : getBondedDevices,
          )
        ],
      ),
      body: isConnecting
          ? const Center(child: CircularProgressIndicator())
          : devices.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("No paired devices found. Ensure Bluetooth is enabled, permissions are granted, and devices are paired."),
                ))
              : ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devices[index];
                    return ListTile(
                      title: Text(device.name ?? "Unknown Device"),
                      subtitle: Text(device.address),
                      onTap: () => connect(device),
                    );
                  },
                ),
    );
  }
}