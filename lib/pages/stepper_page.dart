import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bluetooth_provider.dart';
import '../widgets/circle_rack.dart';

class StepperPage extends StatefulWidget {
  final int currentRack;
  const StepperPage({super.key, required this.currentRack});

  @override
  State<StepperPage> createState() => _StepperPageState();
}

class _StepperPageState extends State<StepperPage> {
  int targetRack = 1;
  final angleCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bt = context.read<BluetoothProvider>();

    return Scaffold(
      appBar: AppBar(title: Text("Stepper Control")),
      body: ListView(
        padding: EdgeInsets.all(12),
        children: [
          Text("Current Rack: ${widget.currentRack}", style: TextStyle(fontSize: 18)),

          DropdownButton<int>(
            value: targetRack,
            items: List.generate(8, (i) => DropdownMenuItem(
              value: i+1,
              child: Text("Rack ${i+1}"),
            )).toList(),
            onChanged: (v) => setState(() => targetRack = v!),
          ),

          ElevatedButton(
            onPressed: () {
              int diff = targetRack - widget.currentRack;
              int angle = (diff * 45) % 360;
              bt.send("STEP:$angle");
            },
            child: Text("Rotate to Rack $targetRack"),
          ),

          Divider(),

          TextField(
            controller: angleCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Rotate Degrees"),
          ),

          ElevatedButton(
            onPressed: () {
              bt.send("STEP:${angleCtrl.text}");
            },
            child: Text("Rotate"),
          ),

          Divider(),

          ElevatedButton(
            onPressed: () => bt.send("NEXT"),
            child: Text("Next Rack (45°)"),
          ),

          const SizedBox(height: 30),
          Center(child: CircleRack(current: widget.currentRack)),
        ],
      ),
    );
  }
}
