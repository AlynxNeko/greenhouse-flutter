import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
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
    final path = await _localPath;
    final dir = Directory(path);
    if (await dir.exists()) {
      dir.listSync().forEach((entity) {
        if (entity is File && entity.path.endsWith(".csv")) {
          entity.deleteSync();
        }
      });
    }
  }

  Future<String> openTodayLog() async {
    final file = await _getTodayFile();
    if (await file.exists()) {
      final result = await OpenFilex.open(file.path);
      return "Membuka log: ${result.message}";
    } else {
      return "Belum ada data log hari ini.";
    }
  }

  // --- Internal Helpers ---

  Future<String> get _localPath async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      return directory?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  String _getFilename(DateTime date) {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    return 'greenhouse_log_$formattedDate.csv';
  }

  Future<File> _getTodayFile() async {
    final path = await _localPath;
    final filename = _getFilename(DateTime.now());
    return File('$path/$filename');
  }

  Future<void> _appendToCsv(StatusModel m) async {
    await _rotateLogs(); // Ensure old files are deleted

    final file = await _getTodayFile();
    bool exists = await file.exists();

    // AUTO-FIX: Check if the existing file has the old header
    if (exists) {
      try {
        final lines = await file.readAsLines();
        if (lines.isNotEmpty && !lines.first.contains("M1")) {
          // Header mismatch detected (Old format), reset file
          await file.delete();
          exists = false;
        }
      } catch (e) {
        // Read error, reset file safely
        exists = false; 
      }
    }
    
    if (!exists) {
      // Write correct header with M1-M8 columns
      await file.writeAsString("Timestamp,Temp,Hum,EMC,Rack,Fan,Pred,Mode,RSSI,SNR,M1,M2,M3,M4,M5,M6,M7,M8\n");
    }

    // Ensure we always have 8 columns for moisture data
    List<String> safeMData = List.from(m.mData);
    while (safeMData.length < 8) safeMData.add("0.0"); // Pad with 0.0
    if (safeMData.length > 8) safeMData = safeMData.sublist(0, 8); // Trim extra

    // Fan is boolean in model (true=ON), usually convert to 1/0 for CSV
    int fanInt = m.fan ? 1 : 0;

    String csvRow = "${m.timestamp.toIso8601String()},${m.temp},${m.hum},${m.emc},${m.rack},$fanInt,${m.predicted},${m.mode},${m.rssi},${m.snr},${safeMData.join(",")}";
    
    // flush: true ensures data is written immediately to disk
    await file.writeAsString("$csvRow\n", mode: FileMode.append, flush: true);
  }

  Future<void> _rotateLogs() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      if (!await dir.exists()) return;

      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 7));

      await for (var entity in dir.list()) {
        if (entity is File && entity.path.endsWith(".csv")) {
          final filename = entity.uri.pathSegments.last;
          final datePart = filename.replaceFirst('greenhouse_log_', '').replaceFirst('.csv', '');
          try {
            final fileDate = DateFormat('yyyy-MM-dd').parse(datePart);
            if (fileDate.isBefore(cutoff)) {
              print("Deleting old log: $filename");
              await entity.delete();
            }
          } catch (e) { /* ignore */ }
        }
      }
    } catch (e) {
      print("Error rotating logs: $e");
    }
  }
}