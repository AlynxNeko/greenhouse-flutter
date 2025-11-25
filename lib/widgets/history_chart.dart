import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../models/status_model.dart';

class HistoryChart extends StatelessWidget {
  final String type; // 'temp' or 'hum'
  const HistoryChart({super.key, this.type = 'temp'});

  @override
  Widget build(BuildContext context) {
    final hist = context.watch<HistoryProvider>().items;

    if (hist.isEmpty) {
      return const SizedBox(height: 300, child: Center(child: Text("No Data")));
    }

    // Determine Value based on type
    double getValue(StatusModel d) => type == 'temp' ? d.temp : d.hum;
    
    // Dynamic Y-Axis Range Calculation
    double minVal = hist.map(getValue).reduce((a, b) => a < b ? a : b);
    double maxVal = hist.map(getValue).reduce((a, b) => a > b ? a : b);
    
    // Add padding so the line isn't stuck to the edge
    double padding = (maxVal - minVal) * 0.1;
    if (padding == 0) padding = 1.0; 

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        title: ChartTitle(text: type == 'temp' ? "Temperature History" : "Humidity History"),
        // X-Axis is now DateTime
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat.Hms(), // Show Hour:Min:Sec
          title: AxisTitle(text: "Time"),
          majorGridLines: const MajorGridLines(width: 0),
        ),
        // Y-Axis is dynamic
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: type == 'temp' ? "°C" : "%"),
          minimum: (minVal - padding).floorToDouble(),
          maximum: (maxVal + padding).ceilToDouble(),
        ),
        series: [
          LineSeries<StatusModel, DateTime>(
            dataSource: hist,
            xValueMapper: (d, i) => d.timestamp,
            yValueMapper: (d, i) => getValue(d),
            animationDuration: 500,
          )
        ],
      ),
    );
  }
}