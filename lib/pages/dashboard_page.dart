import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/status_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/metrics_card.dart';
import 'stepper_page.dart';
import '../widgets/history_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Helper untuk menampilkan NaN dengan rapi
  String _fmt(double val, String unit) {
    if (val.isNaN) return "-- $unit";
    return "${val.toStringAsFixed(1)} $unit";
  }

  // Dialog untuk Input Kadar Air Awal
  void _showInitialMoistureDialog(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    final ctrl = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Set Initial Moisture"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan estimasi kadar air awal (%):"),
            TextField(
              controller: ctrl, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "e.g. 15.0"),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text("Dry (10%)"), onPressed: () => ctrl.text = "10.0"),
                ActionChip(label: const Text("Normal (15%)"), onPressed: () => ctrl.text = "15.0"),
                ActionChip(label: const Text("Wet (20%)"), onPressed: () => ctrl.text = "20.0"),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if(ctrl.text.isNotEmpty) {
                bt.send("SETMOIST:${ctrl.text}");
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Set")
          )
        ],
      )
    );
  }

  // Dialog untuk Test Latency
  void _showTestDialog(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Network Stress Test"),
        content: const Text("Kirim 10 paket 'REQSTATUS' dan hitung latency?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog awal
              // Tampilkan loading / progress
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Running Test... please wait")),
              );
              
              // Jalankan Test: 10x request, interval 500ms
              final result = await bt.runLatencyTest("REQSTATUS", 10, 500);
              
              // Tampilkan Hasil
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
            child: const Text("Run Test"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<StatusProvider>().status;
    final btProvider = context.read<BluetoothProvider>();

    // Initial Load
    if (status.rack == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        btProvider.send("REQSTATUS");
      });
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // --- HEADER CONTROL ---
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("System Mode:", style: TextStyle(color: Colors.grey)),
                    DropdownButton<int>(
                      value: status.mode, // 0, 1, 2
                      dropdownColor: Colors.grey[800],
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("Automatic")),
                        DropdownMenuItem(value: 1, child: Text("Semi-Auto")),
                        DropdownMenuItem(value: 2, child: Text("Notify Only")),
                      ],
                      onChanged: (val) {
                        if (val != null) btProvider.send("SETMODE:$val");
                      },
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.water_drop, size: 16),
                      label: const Text("Set Initial Moisture"),
                      onPressed: () => _showInitialMoistureDialog(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900]),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.speed, size: 16),
                      label: const Text("Test Net"),
                      onPressed: () => _showTestDialog(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900]),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

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
        
        // --- CHARTS ---
        const Text("Temperature History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const HistoryChart(type: 'temp'), // Perlu modifikasi sedikit di HistoryChart untuk support tipe
        
        const SizedBox(height: 20),
        
        const Text("Humidity History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const HistoryChart(type: 'hum'),
        
        const SizedBox(height: 50),
      ],
    );
  }
}