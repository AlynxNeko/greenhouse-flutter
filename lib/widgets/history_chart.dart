// [File: alynxneko/greenhouse-flutter/greenhouse-flutter-d19d01448f5e36d3c2a1b24fa94caff8ae934a29/lib/widgets/history_chart.dart]
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../providers/history_provider.dart';
import '../models/status_model.dart';

class HistoryChart extends StatelessWidget {
  final String type; // 'temp' or 'hum'
  const HistoryChart({super.key, this.type = 'temp'});

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<HistoryProvider>().items;
    final isTemp = type == 'temp';

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        title: ChartTitle(text: isTemp ? "Temperature History" : "Humidity History"),
        primaryXAxis: NumericAxis(title: AxisTitle(text: "Index")),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: isTemp ? "°C" : "%"),
          minimum: isTemp ? 20 : 0,
          maximum: isTemp ? 60 : 100,
        ),
        series: [
          LineSeries<StatusModel, int>(
            dataSource: hist,
            xValueMapper: (d, i) => i,
            yValueMapper: (d, i) => isTemp ? d.temp : d.hum,
            color: isTemp ? Colors.orange : Colors.blue,
            name: isTemp ? "Temp" : "Humidity",
          )
        ],
      ),
    );
  }
}