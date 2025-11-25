import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();
    final items = history.items.reversed.toList(); // Show newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Logs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Clear History",
            onPressed: () {
              history.clear();
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: "Open CSV File",
            onPressed: () {
              history.openCsvFile();
            },
          ),
        ],
      ),
      body: items.isEmpty 
        ? const Center(child: Text("No logs yet."))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Time")),
                DataColumn(label: Text("Temp")),
                DataColumn(label: Text("Hum")),
                DataColumn(label: Text("EMC")),
                DataColumn(label: Text("Rack")),
              ],
              rows: items.map((e) {
                return DataRow(cells: [
                  DataCell(Text(DateFormat('HH:mm:ss').format(e.timestamp))),
                  DataCell(Text(e.temp.toStringAsFixed(1))),
                  DataCell(Text(e.hum.toStringAsFixed(1))),
                  DataCell(Text(e.emc.toStringAsFixed(1))),
                  DataCell(Text(e.rack.toString())),
                ]);
              }).toList(),
            ),
          ),
    );
  }
}