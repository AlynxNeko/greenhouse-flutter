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
    final bt = context.read<BluetoothProvider>();

    if (status == null) {
      bt.send("REQSTATUS");
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Connected"),
        actions: [
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              bt.disconnect();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(12),
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
              ElevatedButton(onPressed: () => bt.send("REQSTATUS"), child: Text("Refresh")),
              ElevatedButton(onPressed: () => bt.send("FANON"), child: Text("Fan ON")),
              ElevatedButton(onPressed: () => bt.send("FANOFF"), child: Text("Fan OFF")),
            ],
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => StepperPage(currentRack: status.rack),
              ));
            },
            child: Text("Stepper Control"),
          ),

          const SizedBox(height: 30),
          HistoryChart(),
        ],
      ),
    );
  }
}
