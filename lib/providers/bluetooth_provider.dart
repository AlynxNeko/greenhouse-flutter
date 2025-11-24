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

  // New method to request permissions (from your working code)
  Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }
    await FlutterBluetoothSerial.instance.requestEnable();
  }

  Future<bool> connect(BluetoothDevice d, StatusProvider status) async {
    if (!await Permission.bluetoothConnect.isGranted) {
      return false;
    }
    
    device = d;
    isConnected = await bt.connect(d.address);

    if (isConnected) {
      // Start listening to the broadcast stream only for status updates
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
    _dataSubscription = null;
    bt.dispose();
    isConnected = false;
    device = null;
    notifyListeners();
  }

  // Expose the underlying message stream for the DevChatPage to listen to
  Stream<String> get messageStream => bt.messageStream;

  // Fungsi Testing Latency & Reliability
  Future<TestResult> runLatencyTest(String command, int count, int intervalMs) async {
    int success = 0;
    int totalLatency = 0;
    
    for (int i = 0; i < count; i++) {
      int start = DateTime.now().millisecondsSinceEpoch;
      
      // Kirim perintah
      send(command);
      
      // Tunggu respons (sederhana: tunggu stream event berikutnya yang valid)
      try {
        // Kita tunggu max 2 detik untuk reply
        await messageStream.firstWhere((msg) => msg.startsWith("STATUS:")).timeout(const Duration(seconds: 2));
        
        int end = DateTime.now().millisecondsSinceEpoch;
        totalLatency += (end - start);
        success++;
      } catch (e) {
        // Timeout / Gagal
        print("Packet $i lost or timeout");
      }
      
      // Delay antar paket
      await Future.delayed(Duration(milliseconds: intervalMs));
    }
    
    double avg = success > 0 ? totalLatency / success : 0.0;
    return TestResult(success, count, avg);
  }
}