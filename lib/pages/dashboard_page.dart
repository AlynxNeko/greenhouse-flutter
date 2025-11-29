import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/status_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../providers/history_provider.dart';
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

  void _showInitialMoistureDialog(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    final ctrl = TextEditingController();
    
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Set Kadar Air Awal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Masukkan estimasi kadar air awal (%):", style: TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl, 
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Contoh: 15.0",
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(label: const Text("Kering (10%)"), onPressed: () => ctrl.text = "10.0"),
                ActionChip(label: const Text("Normal (15%)"), onPressed: () => ctrl.text = "15.0"),
                ActionChip(label: const Text("Basah (20%)"), onPressed: () => ctrl.text = "20.0"),
              ],
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if(ctrl.text.isNotEmpty) {
                bt.send("SETMOIST:${ctrl.text}");
                Navigator.pop(ctx);
              }
            }, 
            child: const Text("Simpan")
          )
        ],
      )
    );
  }

  void _showTestDialog(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tes Jaringan LoRa"),
        content: const Text("Jalankan tes latensi 10 paket?\n(Membutuhkan waktu ±25-30 detik)"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sedang mengetes jaringan... mohon tunggu.")),
              );
              
              final result = await bt.runLatencyTest("REQSTATUS", 10, 2500);
              
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Hasil Tes"),
                    content: Text(
                      "Sukses: ${result.successCount}/${result.totalCount}\n"
                      "Rata-rata Latensi: ${result.avgLatencyMs.toStringAsFixed(0)} ms"
                    ),
                  )
                );
              }
            },
            child: const Text("Jalankan"),
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
      padding: const EdgeInsets.all(16),
      children: [
        // --- 1. HEADER & SIGNAL ---
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: const Color(0xFF1E1E1E),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Status Sinyal", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    Icon(Icons.wifi, color: status.rssi > -90 ? Colors.green : Colors.red),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SignalBadge(label: "RSSI", value: "${status.rssi} dBm"),
                    _SignalBadge(label: "SNR", value: "${status.snr} dB"),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // --- 2. METRICS GRID ---
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            MetricsCard("Suhu", _fmt(status.temp, "°C")),
            MetricsCard("Kelembaban", _fmt(status.hum, "%")),
            MetricsCard("Kadar Air (EMC)", _fmt(status.emc, "%")),
            MetricsCard("Posisi Rak", "${status.rack}/8"),
            MetricsCard("Estimasi Selesai", "${status.predicted} m"),
            MetricsCard("Mode", status.mode == 0 ? "AUTO" : (status.mode == 1 ? "SEMI" : "NOTIF")),
          ],
        ),
        const SizedBox(height: 20),

        // --- 3. CONTROL PANEL (PRETTY UI) ---
        const Text("Panel Kontrol", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        const SizedBox(height: 10),
        
        // Mode Selection
        _ControlTile(
          icon: Icons.settings_suggest,
          title: "Mode Sistem",
          subtitle: "Pilih logika operasi greenhouse",
          trailing: DropdownButton<int>(
            value: status.mode,
            dropdownColor: Colors.grey[850],
            underline: Container(),
            items: const [
              DropdownMenuItem(value: 0, child: Text("Otomatis")),
              DropdownMenuItem(value: 1, child: Text("Semi-Auto")),
              DropdownMenuItem(value: 2, child: Text("Notifikasi")),
            ],
            onChanged: (val) {
              if (val != null) btProvider.send("SETMODE:$val");
            },
          ),
        ),

        // Fan Toggle
        _ControlTile(
          icon: Icons.wind_power,
          title: "Kipas Pendingin",
          subtitle: !status.fan ? "Kipas sedang MENYALA" : "Kipas sedang MATI",
          trailing: Switch(
            value: !status.fan,
            activeColor: Colors.greenAccent,
            onChanged: (bool value) {
              // FIX: Send FANON when switch is TRUE, FANOFF when false
              btProvider.send(value ? "FANON" : "FANOFF");
            },
          ),
        ),

        // Set Moisture
        _ControlTile(
          icon: Icons.water_drop,
          title: "Kalibrasi Awal",
          subtitle: "Atur kadar air awal bahan",
          onTap: () => _showInitialMoistureDialog(context),
        ),

        // Manual Rack Control
        _ControlTile(
          icon: Icons.rotate_right,
          title: "Kontrol Rak Manual",
          subtitle: "Putar posisi rak secara manual",
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => StepperPage(currentRack: status.rack),
          )),
        ),

        // Network Test
        _ControlTile(
          icon: Icons.speed,
          title: "Tes Jaringan",
          subtitle: "Cek kesehatan koneksi LoRa",
          onTap: () => _showTestDialog(context),
        ),

        const SizedBox(height: 20),

        // --- 4. GRAPHS ---
        const Text("Grafik Riwayat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        const SizedBox(height: 10),
        const HistoryChart(type: 'temp'),
        const SizedBox(height: 10),
        const HistoryChart(type: 'hum'),

        const SizedBox(height: 20),

        // --- 5. DATA MANAGEMENT ---
        const Text("Manajemen Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
        const SizedBox(height: 10),
        
        Card(
          color: Colors.grey[900],
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_open, color: Colors.blueAccent),
                title: const Text("Buka Log Harian (CSV)"),
                subtitle: const Text("Lihat atau bagikan file log hari ini"),
                onTap: () async {
                  final msg = await context.read<HistoryProvider>().openTodayLog();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_view, color: Colors.purpleAccent),
                title: const Text("Tabel Log"),
                subtitle: const Text("Lihat data dalam tampilan tabel"),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LogPage()));
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text("Hapus Semua Riwayat"),
                subtitle: const Text("Bersihkan data grafik dan file log"),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Hapus Riwayat?"),
                      content: const Text("Tindakan ini akan menghapus semua file log CSV dan mereset grafik. Data tidak dapat dikembalikan."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            context.read<HistoryProvider>().clear();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Riwayat berhasil dihapus")),
                            );
                          },
                          child: const Text("Hapus"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

// --- Helper Widgets for Cleaner Code ---

class _SignalBadge extends StatelessWidget {
  final String label;
  final String value;
  const _SignalBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ControlTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}