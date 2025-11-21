import 'package:flutter/material.dart';
import '../models/status_model.dart';

class HistoryProvider extends ChangeNotifier {
  final List<StatusModel> items = [];

  void add(StatusModel m) {
    items.add(m);
    notifyListeners();
  }
}
