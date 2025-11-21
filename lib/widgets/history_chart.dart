import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../providers/history_provider.dart';
import '../models/status_model.dart';

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key});

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<HistoryProvider>().items;

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        title: ChartTitle(text: "Temperature History"),
        primaryXAxis: NumericAxis(title: AxisTitle(text: "Index")),
        primaryYAxis: NumericAxis(title: AxisTitle(text: "°C")),
        series: [
          LineSeries<StatusModel, int>(
            dataSource: hist,
            xValueMapper: (d, i) => i,
            yValueMapper: (d, i) => d.temp,
          )
        ],
      ),
    );
  }
}
