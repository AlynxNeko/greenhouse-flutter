import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? connection;

  Future<bool> connect(String address) async {
    connection = await BluetoothConnection.toAddress(address);
    return connection!.isConnected;
  }

  Stream<String> listen() {
    return connection!.input!
        .map((data) => String.fromCharCodes(data))
        .asBroadcastStream();
  }

  void send(String msg) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(msg.codeUnits));
      connection!.output.allSent;
    }
  }

  void dispose() => connection?.dispose();
}
