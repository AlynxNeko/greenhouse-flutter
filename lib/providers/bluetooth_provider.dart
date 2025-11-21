import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';
import 'status_provider.dart';

class BluetoothProvider extends ChangeNotifier {
  final bt = BluetoothService();
  bool isConnected = false;
  BluetoothDevice? device;

  Future<void> connect(BluetoothDevice d, StatusProvider status) async {
    device = d;
    isConnected = await bt.connect(d.address);

    if (isConnected) {
      bt.listen().listen((raw) {
        if (raw.startsWith("STATUS:")) {
          status.update(raw.replaceFirst("STATUS:", ""));
        }
      });
    }

    notifyListeners();
  }

  void send(String cmd) => bt.send(cmd);

  void disconnect() {
    bt.dispose();
    isConnected = false;
    notifyListeners();
  }
}
