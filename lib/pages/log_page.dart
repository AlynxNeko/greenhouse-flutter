// lib/pages/log_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import 'full_history_page.dart'; // <--- Import New Page

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    // keeping the "live" in-memory items here for quick viewing
    final history = context.watch<HistoryProvider>();
    final items = history.items.reversed.toList(); 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Logs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Clear History",
            onPressed: () {
              history.clear();
            },
          ),
          // MODIFIED BUTTON
          IconButton(
            icon: const Icon(Icons.history), // Changed icon to history
            tooltip: "View All History",
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const FullHistoryPage())
              );
            },
          ),
        ],
      ),
      body: items.isEmpty 
        ? const Center(child: Text("No logs in this session.\nClick the History icon to see past data."))
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