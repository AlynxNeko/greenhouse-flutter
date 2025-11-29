import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';

class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch history changes
    final history = context.watch<HistoryProvider>();
    // Reverse to show newest at top
    final items = history.items.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Data"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Hapus Riwayat",
            onPressed: () {
              _showClearConfirmation(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_open),
            tooltip: "Buka File CSV",
            onPressed: () async {
              // FIX: Calls the updated method from HistoryProvider
              final msg = await context.read<HistoryProvider>().openTodayLog();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text("Belum ada data terekam.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  // Darker header row for better contrast
                  headingRowColor: MaterialStateProperty.resolveWith(
                      (states) => Colors.grey[900]),
                  columns: const [
                    DataColumn(label: Text("Waktu", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Suhu (°C)", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("RH (%)", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("EMC (%)", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Rak", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Mode", style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: items.map((e) {
                    return DataRow(cells: [
                      DataCell(Text(DateFormat('HH:mm:ss').format(e.timestamp))),
                      DataCell(Text(e.temp.toStringAsFixed(1))),
                      DataCell(Text(e.hum.toStringAsFixed(1))),
                      DataCell(Text(e.emc.toStringAsFixed(1))),
                      DataCell(Text(e.rack.toString())),
                      DataCell(Text(_getModeName(e.mode))),
                    ]);
                  }).toList(),
                ),
              ),
            ),
    );
  }

  // Helper to translate mode number to text
  String _getModeName(int mode) {
    switch (mode) {
      case 0: return "Auto";
      case 1: return "Semi";
      case 2: return "Notif";
      default: return "?";
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Semua Data?"),
        content: const Text("Tindakan ini akan menghapus grafik dan semua file CSV log secara permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              context.read<HistoryProvider>().clear();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Riwayat berhasil dihapus.")),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}