import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../services/bluetooth_service.dart';
import 'status_provider.dart';
import '../services/notification_service.dart'; // <--- Import

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

  Future<bool> connect(BluetoothDevice d, StatusProvider status) async {
    device = d;
    isConnected = await bt.connect(d.address);

    if (isConnected) {
      _dataSubscription = bt.messageStream.listen((raw) {
        // Trim whitespace to ensure clean matching
        final msg = raw.trim();

        if (msg.startsWith("STATUS:")) {
          status.update(msg.replaceFirst("STATUS:", ""));
        } 
        // --- NEW COMMANDS ---
        else if (msg == "DONE") {
          NotificationService.show(
            "Process Complete", 
            "The coffee beans are dry."
          );
        } 
        else if (msg == "NEEDTOSPIN") {
          NotificationService.show(
            "Action Required", 
            "Greenhouse needs to spin to the next rack!"
          );
        }
        
      });
    }
    notifyListeners();
    return isConnected;
  }

  Future<void> requestBluetoothPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.notification,
    ].request();
    await FlutterBluetoothSerial.instance.requestEnable();
  }

  void send(String cmd) => bt.send(cmd);

  void disconnect() {
    _dataSubscription?.cancel();
    bt.dispose();
    isConnected = false;
    notifyListeners();
  }

  Stream<String> get messageStream => bt.messageStream;

  // UPDATED: Network Test with Pause/Resume Auto logic
  Future<TestResult> runLatencyTest(String command, int count, int intervalMs) async {
    int success = 0;
    int totalLatency = 0;
    
    // 1. Disable Auto Send on Sensor Node
    send("PAUSEAUTO");
    // Give it a moment to process
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < count; i++) {
      int start = DateTime.now().millisecondsSinceEpoch;
      bool packetReceived = false;
      
      send(command);
      
      final completer = Completer<void>();
      // Temporary listener for this specific packet
      final sub = messageStream.listen((msg) {
        if (msg.startsWith("STATUS:") && !completer.isCompleted) {
          packetReceived = true;
          completer.complete();
        }
      });

      try {
        await completer.future.timeout(const Duration(seconds: 4));
        int end = DateTime.now().millisecondsSinceEpoch;
        totalLatency += (end - start);
        success++;
      } catch (e) {
        print("Packet $i lost/timeout");
      } finally {
        sub.cancel();
      }
      
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    // Delay before re-enabling auto send
    await Future.delayed(const Duration(milliseconds: 500));
    // 2. Re-enable Auto Send
    send("RESUMEAUTO");

    double avg = success > 0 ? totalLatency / success : 0.0;
    return TestResult(success, count, avg);
  }
}