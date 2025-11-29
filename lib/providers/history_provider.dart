import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/status_model.dart';

class HistoryProvider extends ChangeNotifier {
  List<StatusModel> items = [];

  Future<void> add(StatusModel m) async {
    items.add(m);
    notifyListeners();
    await _appendToCsv(m);
  }

  Future<void> clear() async {
    items.clear();
    notifyListeners();
    final file = await _getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> exportToCSV() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      return "Logs saved to: ${file.path}";
    } else {
      return "No logs found to export.";
    }
  }

  Future<void> openCsvFile() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      // Just open the file; open_filex handles FileProvider on Android automatically
      await OpenFilex.open(file.path);
    }
  }

  // --- Internal Helpers ---

  Future<String> get _localPath async {
    // Use getExternalStorageDirectory for Android (visible to user/apps)
    // Fallback to ApplicationDocuments for iOS
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<File> _getLocalFile() async {
    final path = await _localPath;
    return File('$path/greenhouse_log.csv');
  }

  Future<void> _appendToCsv(StatusModel m) async {
    final file = await _getLocalFile();
    bool exists = await file.exists();
    
    // Manual CSV Construction to avoid converter issues with line endings
    if (!exists) {
      await file.writeAsString("Timestamp,Temp,Hum,EMC,Rack,Fan,Pred,Mode,RSSI,SNR\n");
    }

    // Format data as simple string line
    String csvRow = "${m.timestamp.toIso8601String()},${m.temp},${m.hum},${m.emc},${m.rack},${m.fan?1:0},${m.predicted},${m.mode},${m.rssi},${m.snr}";
    
    // Append with explicit Mode
    await file.writeAsString("$csvRow\n", mode: FileMode.append);
  }
}