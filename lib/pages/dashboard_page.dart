// [File: alynxneko/greenhouse-flutter/greenhouse-flutter-d19d01448f5e36d3c2a1b24fa94caff8ae934a29/lib/pages/dashboard_page.dart]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/status_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/history_provider.dart'; // Import HistoryProvider
import '../widgets/metrics_card.dart';
import 'stepper_page.dart';
import '../widgets/history_chart.dart';
import 'log_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  String _fmt(double val, String unit) {
    if (val.isNaN) return "-- $unit";
    return "${val.toStringAsFixed(1)} $unit";
  }

  // ... (Previous dialog code: _showInitialMoistureDialog) ...
  void _showInitialMoistureDialog(BuildContext context) { /* ... Keep existing code ... */ }

  void _showTestDialog(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Network Stress Test"),
        content: const Text("Run 10-packet Latency Test?\n(Takes approx 25-30 seconds)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Running Test... please wait 30s")),
              );
              
              // UPDATED: Interval set to 2500ms to be safe for LoRa SF10
              final result = await bt.runLatencyTest("REQSTATUS", 10, 2500);
              
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Test Result"),
                  content: Text(
                    "Success: ${result.successCount}/${result.totalCount}\n"
                    "Avg Latency: ${result.avgLatencyMs.toStringAsFixed(0)} ms"
                  ),
                )
              );
            },
            child: const Text("Run"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<StatusProvider>().status;
    final btProvider = context.read<BluetoothProvider>();

    if (status.rack == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        btProvider.send("REQSTATUS");
      });
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // ... (Dropdown code) ...
                // Add CSV Button here
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.speed, size: 16),
                      label: const Text("Test Net"),
                      onPressed: () => _showTestDialog(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900]),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text("Export CSV"),
                      onPressed: () async {
                        // This calls the method we just added
                        final msg = await context.read<HistoryProvider>().exportToCSV();
                        
                        // Show the result (e.g., the file path)
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),

        // --- SIGNAL INFO ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Chip(
              avatar: const Icon(Icons.wifi, size: 16),
              label: Text("RSSI: ${status.rssi} dBm"),
              backgroundColor: status.rssi > -90 ? Colors.green[900] : Colors.red[900],
            ),
            Chip(
              avatar: const Icon(Icons.signal_cellular_alt, size: 16),
              label: Text("SNR: ${status.snr} dB"),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // --- METRICS GRID ---
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            MetricsCard("Temperature", _fmt(status.temp, "°C")),
            MetricsCard("Humidity", _fmt(status.hum, "%")),
            MetricsCard("EMC", _fmt(status.emc, "%")),
            MetricsCard("Rack Pos", "${status.rack}/8"),
            MetricsCard("Pred. Time", "${status.predicted} min"),
            MetricsCard("Fan", status.fan ? "ON" : "OFF"),
          ],
        ),

        const SizedBox(height: 20),

        // --- CONTROLS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => btProvider.send("REQSTATUS"), child: const Text("Refresh")),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => StepperPage(currentRack: status.rack),
              )),
              child: const Text("Manual Control"),
            ),
          ],
        ), 
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => btProvider.send("FANON"), child: const Text("Fan ON")),
            ElevatedButton(onPressed: () => btProvider.send("FANOFF"), child: const Text("Fan OFF")),
          ],
        ),

        const SizedBox(height: 30),
        const Text("Temperature History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const HistoryChart(type: 'temp'), 
        
        const SizedBox(height: 20),
        const Text("Humidity History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const HistoryChart(type: 'hum'), // This now works with the fixed widget
        
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ... existing buttons ...
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart, size: 16),
              label: const Text("Logs"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LogPage()));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[900]),
            ),
          ],
        ),
        Card(
          color: Colors.red[900]!.withOpacity(0.2),
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Reset Data History"),
            subtitle: const Text("Clear all logs and graphs"),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // Confirmation Dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Clear History?"),
                    content: const Text("This will delete all saved CSV logs and reset the graphs. This cannot be undone."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          // CALL THE RESET FUNCTION
                          context.read<HistoryProvider>().clear();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("History Cleared!")),
                          );
                        },
                        child: const Text("Clear"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("Reset"),
            ),
          ),
        ),
      ],
    );
  }
}