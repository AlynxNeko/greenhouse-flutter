import 'package:flutter/material.dart';
import '../models/status_model.dart';
import 'history_provider.dart';

class StatusProvider extends ChangeNotifier {
  StatusModel? status;

  final HistoryProvider history;

  StatusProvider(this.history);

  void update(String raw) {
    status = StatusModel.fromPacket(raw);
    history.add(status!);
    notifyListeners();
  }
}
