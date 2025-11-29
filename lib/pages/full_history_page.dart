import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../models/status_model.dart';

class FullHistoryPage extends StatefulWidget {
  const FullHistoryPage({super.key});

  @override
  State<FullHistoryPage> createState() => _FullHistoryPageState();
}

class _FullHistoryPageState extends State<FullHistoryPage> {
  late Future<List<StatusModel>> _logsFuture;

  @override
  void initState() {
    super.initState();
    // Load logs from disk when the page opens
    _logsFuture = context.read<HistoryProvider>().loadAllLogs();
  }

  // Helper method to group the list of logs by Date (ignoring time)
  Map<String, List<StatusModel>> _groupLogsByDay(List<StatusModel> logs) {
    final Map<String, List<StatusModel>> groups = {};
    
    for (var log in logs) {
      // Create a key like "2025-11-29"
      final dateKey = DateFormat('yyyy-MM-dd').format(log.timestamp);
      
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(log);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History Log"),
      ),
      body: FutureBuilder<List<StatusModel>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No history logs found."));
          }

          final allLogs = snapshot.data!;
          
          // 1. Group the logs
          final groupedLogs = _groupLogsByDay(allLogs);
          
          // 2. Sort the keys so the newest date is first
          final sortedDateKeys = groupedLogs.keys.toList()
            ..sort((a, b) => b.compareTo(a)); 

          return ListView.builder(
            itemCount: sortedDateKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedDateKeys[index];
              final dayLogs = groupedLogs[dateKey]!;
              final dateObj = DateTime.parse(dateKey);
              
              // Format the title: "Friday, Nov 29, 2025"
              final dateTitle = DateFormat('EEEE, MMM d, yyyy').format(dateObj);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ExpansionTile(
                  initiallyExpanded: index == 0, // Auto-expand only the first (newest) day
                  leading: const Icon(Icons.calendar_today, color: Colors.greenAccent),
                  title: Text(
                    dateTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${dayLogs.length} entries"),
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 15,
                        headingRowHeight: 40,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 40,
                        columns: const [
                          DataColumn(label: Text("Time")),
                          DataColumn(label: Text("Temp")),
                          DataColumn(label: Text("Hum")),
                          DataColumn(label: Text("EMC")),
                          DataColumn(label: Text("Fan")),
                          DataColumn(label: Text("Rack")),
                        ],
                        rows: dayLogs.map((e) {
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('HH:mm:ss').format(e.timestamp))),
                            DataCell(Text(e.temp.toStringAsFixed(1))),
                            DataCell(Text(e.hum.toStringAsFixed(1))),
                            DataCell(Text(e.emc.toStringAsFixed(1))),
                            DataCell(Text(e.fan ? "ON" : "OFF", 
                              style: TextStyle(color: e.fan ? Colors.green : Colors.grey))),
                            DataCell(Text(e.rack.toString())),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}