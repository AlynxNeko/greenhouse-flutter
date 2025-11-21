import 'dart:typed_data';
import 'dart:async'; // <--- ADDED
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothService {
  BluetoothConnection? connection;
  // Change to a broadcast controller so multiple listeners (Dashboard & Chat) can subscribe
  final StreamController<String> _messageController = StreamController<String>.broadcast(); 

  // Expose the stream
  Stream<String> get messageStream => _messageController.stream; // <--- ADDED

  Future<bool> connect(String address) async {
    connection = await BluetoothConnection.toAddress(address);
    if (connection!.isConnected) {
        // Pipe incoming data to the StreamController
        connection!.input!
            .map((data) => String.fromCharCodes(data).trim()) // Added trim()
            .listen(
              (raw) => _messageController.add(raw),
              onDone: () {
                // Handle stream completion (disconnect)
                if (!_messageController.isClosed) _messageController.close();
              },
              onError: (e) {
                print("Bluetooth Stream Error: $e");
              }
            );
    }
    return connection!.isConnected;
  }

  void send(String msg) {
    if (connection != null && connection!.isConnected) {
      connection!.output.add(Uint8List.fromList(msg.codeUnits));
      connection!.output.allSent;
    }
  }

  void dispose() {
    connection?.dispose();
    if (!_messageController.isClosed) _messageController.close();
  }
}