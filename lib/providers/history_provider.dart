// [File: alynxneko/greenhouse-flutter/greenhouse-flutter-d19d01448f5e36d3c2a1b24fa94caff8ae934a29/lib/providers/history_provider.dart]
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/status_model.dart';

class HistoryProvider extends ChangeNotifier {
  final List<StatusModel> items = [];

  void add(StatusModel m) {
    items.add(m);
    notifyListeners();
  }

  // --- NEW CSV EXPORT ---
  Future<String> exportToCSV() async {
    if (items.isEmpty) return "No data to export";

    try {
      // 1. Build CSV String
      StringBuffer csvData = StringBuffer();
      csvData.writeln("Timestamp,Temp,Humidity,EMC,Rack,Fan,PredictedTime,Mode"); // Header
      
      // We don't have real timestamp in StatusModel yet, using Index or "Now"
      // Ideally add DateTime to StatusModel. Using current loop index for now.
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        csvData.writeln("$i,${item.temp},${item.hum},${item.emc},${item.rack},${item.fan},${item.predicted},${item.mode}");
      }

      // 2. Get Directory
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/greenhouse_history_${DateTime.now().millisecondsSinceEpoch}.csv";
      
      // 3. Write File
      final file = File(path);
      await file.writeAsString(csvData.toString());
      
      return "Saved to $path";
    } catch (e) {
      return "Error saving CSV: $e";
    }
  }
}