// lib/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/status_provider.dart';
import '../providers/bluetooth_provider.dart';
import '../widgets/metrics_card.dart';
import '../widgets/history_chart.dart';
import 'stepper_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<StatusProvider>().status;
    final btProvider = context.read<BluetoothProvider>();

    // Send initial request if the status rack is the placeholder value (0).
    // This runs only on the first frame and once after disconnection/reconnection.
    if (status.rack == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        btProvider.send("REQSTATUS");
      });
      
      // Show loading indicator until a real status (rack != 0) is received
      return const Center(child: CircularProgressIndicator()); 
    }

    // Render the actual dashboard using the current status
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        MetricsCard("Temperature", "${status.temp} °C"),
        MetricsCard("Humidity", "${status.hum} %"),
        MetricsCard("EMC", "${status.emc} %"),
        MetricsCard("Rack on Top", "${status.rack}/8"),
        MetricsCard("Fan", status.fan ? "ON" : "OFF"),
        MetricsCard("Predicted Done", "${status.predicted} mins"),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () => btProvider.send("REQSTATUS"), child: const Text("Refresh")),
            ElevatedButton(onPressed: () => btProvider.send("FANON"), child: const Text("Fan ON")),
            ElevatedButton(onPressed: () => btProvider.send("FANOFF"), child: const Text("Fan OFF")),
          ],
        ),

        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => StepperPage(currentRack: status.rack),
            ));
          },
          child: const Text("Stepper Control"),
        ),

        const SizedBox(height: 30),
        const HistoryChart(),
      ],
    );
  }
}