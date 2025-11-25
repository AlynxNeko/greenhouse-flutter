import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../models/status_model.dart';

class HistoryProvider extends ChangeNotifier {
  List<StatusModel> items = [];

  // 1. Add data and Auto-Save to CSV
  Future<void> add(StatusModel m) async {
    items.add(m);
    notifyListeners();
    await _appendToCsv(m);
  }

  // 2. Clear history and delete file
  Future<void> clear() async {
    items.clear();
    notifyListeners();
    final file = await _getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 3. The method your DashboardPage is looking for
  Future<String> exportToCSV() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      return "Logs saved to: ${file.path}";
    } else {
      return "No logs found to export.";
    }
  }

  // 4. Open the CSV file in an external app (Excel, Sheets, etc.)
  Future<void> openCsvFile() async {
    final file = await _getLocalFile();
    if (await file.exists()) {
      await OpenFilex.open(file.path);
    }
  }

  // --- Internal Helpers ---

  Future<String> get _localPath async {
    // On Android, this usually points to /storage/emulated/0/Android/data/com.example.greenhouse_app/files
    final directory = await getExternalStorageDirectory(); 
    return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
  }

  Future<File> _getLocalFile() async {
    final path = await _localPath;
    return File('$path/greenhouse_log.csv');
  }

  Future<void> _appendToCsv(StatusModel m) async {
    final file = await _getLocalFile();
    
    // If file doesn't exist, write the header first
    bool exists = await file.exists();
    if (!exists) {
      await file.writeAsString("Timestamp,Temp,Hum,EMC,Rack,Fan,Pred,Mode,RSSI,SNR\n");
    }

    // Append the new row
    List<dynamic> row = m.toList();
    String csvRow = const ListToCsvConverter().convert([row]);
    await file.writeAsString("$csvRow\n", mode: FileMode.append);
  }
}