// lib/providers/status_provider.dart
import 'package:flutter/material.dart';
import '../models/status_model.dart';
import 'history_provider.dart';

class StatusProvider extends ChangeNotifier {
  // Change StatusModel? to StatusModel and initialize it using the new factory.
  StatusModel status = StatusModel.initial(); // <--- UPDATED

  final HistoryProvider history;

  StatusProvider(this.history);

  void update(String raw) {
    status = StatusModel.fromPacket(raw);
    history.add(status); // status is no longer nullable, so we remove the '!'
    notifyListeners();
  }
}