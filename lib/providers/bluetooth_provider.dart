// [File: alynxneko/greenhouse-flutter/greenhouse-flutter-d19d01448f5e36d3c2a1b24fa94caff8ae934a29/lib/providers/bluetooth_provider.dart]
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../services/bluetooth_service.dart';
import 'status_provider.dart';

class TestResult {
  final int successCount;
  final int totalCount;
  final double avgLatencyMs;
  
  TestResult(this.successCount, this.totalCount, this.avgLatencyMs);
}

class BluetoothProvider extends ChangeNotifier {
  final bt = BluetoothService();
  bool isConnected = false;
  BluetoothDevice? device;
  StreamSubscription<String>? _dataSubscription;

  Future<void> requestBluetoothPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();
    await FlutterBluetoothSerial.instance.requestEnable();
  }

  Future<bool> connect(BluetoothDevice d, StatusProvider status) async {
    // ... permissions ...
    device = d;
    isConnected = await bt.connect(d.address);

    if (isConnected) {
      _dataSubscription = bt.messageStream.listen((raw) {
        if (raw.startsWith("STATUS:")) {
          status.update(raw.replaceFirst("STATUS:", ""));
        }
      });
    }
    notifyListeners();
    return isConnected;
  }

  void send(String cmd) => bt.send(cmd);

  void disconnect() {
    _dataSubscription?.cancel();
    bt.dispose();
    isConnected = false;
    notifyListeners();
  }

  Stream<String> get messageStream => bt.messageStream;

  // UPDATED: Network Test with longer delays and robust waiting
  Future<TestResult> runLatencyTest(String command, int count, int intervalMs) async {
    int success = 0;
    int totalLatency = 0;
    
    // Use a broadcast subscription for the test to not interfere with main logic
    // Note: Doing this inside the loop allows us to catch the specific response
    
    for (int i = 0; i < count; i++) {
      int start = DateTime.now().millisecondsSinceEpoch;
      bool packetReceived = false;
      
      // 1. Send Command
      send(command);
      
      // 2. Wait for response (using a temporary subscription)
      final completer = Completer<void>();
      final sub = messageStream.listen((msg) {
        if (msg.startsWith("STATUS:") && !completer.isCompleted) {
          packetReceived = true;
          completer.complete();
        }
      });

      try {
        // Wait for response OR timeout (4 seconds max for LoRa roundtrip)
        await completer.future.timeout(const Duration(seconds: 4));
        int end = DateTime.now().millisecondsSinceEpoch;
        totalLatency += (end - start);
        success++;
      } catch (e) {
        print("Packet $i lost/timeout");
      } finally {
        sub.cancel();
      }
      
      // 3. Mandatory delay before next packet
      // Ensure intervalMs is at least 2000ms for LoRa SF10
      int safeInterval = intervalMs < 2000 ? 2000 : intervalMs;
      await Future.delayed(Duration(milliseconds: safeInterval));
    }
    
    double avg = success > 0 ? totalLatency / success : 0.0;
    return TestResult(success, count, avg);
  }
}