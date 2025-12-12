import 'package:flutter/material.dart';
import '../models/status_model.dart';
import 'history_provider.dart';
import '../services/notification_service.dart'; 

class StatusProvider extends ChangeNotifier {
  StatusModel status = StatusModel.initial(); 

  final HistoryProvider history;

  StatusProvider(this.history);

  void update(String raw) {
    // Keep reference to old status to compare alerts
    StatusModel oldStatus = status;
    
    // Parse new status
    status = StatusModel.fromPacket(raw);
    
    history.add(status); 
    notifyListeners();

    // --- NOTIFICATION LOGIC ---
    // Check if we are in SEMI (1) or NOTIFY (2) mode
    if (status.mode != 0) { 
      bool rotateNeeded = (status.alertCode & 1) != 0;
      bool fanNeeded = (status.alertCode & 2) != 0;
      
      bool oldRotate = (oldStatus.alertCode & 1) != 0;
      bool oldFan = (oldStatus.alertCode & 2) != 0;

      // Trigger only if the alert just appeared (prevent spamming)
      if (rotateNeeded && !oldRotate) {
        NotificationService.show("Action Required", "Time to rotate the racks!");
      }
      
      if (fanNeeded && !oldFan) {
         NotificationService.show("Humidity High", "Please turn on the fan.");
      }
    }
  }
}