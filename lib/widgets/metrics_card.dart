import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  final String title, value;
  const MetricsCard(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: TextStyle(fontSize: 20)),
      ),
    );
  }
}
