import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../models/emergency_alert.dart';

class HiveStorageService {
  static Future<void> initBoxes() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.boxAlerts);
    await Hive.openBox(AppConstants.boxRelayLog);
    await Hive.openBox(AppConstants.boxChatMessages);
    await Hive.openBox('emergency_contacts');
  }


  static List<EmergencyAlert> getSavedAlerts() {
    try {
      final box = Hive.box(AppConstants.boxAlerts);
      List<EmergencyAlert> loaded = [];
      for (var key in box.keys) {
        final val = box.get(key);
        if (val != null && val is Map) {
          loaded.add(EmergencyAlert.fromJson(Map<String, dynamic>.from(val)));
        }
      }
      return loaded.reversed.toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAlert(EmergencyAlert alert) async {
    final alertsBox = Hive.box(AppConstants.boxAlerts);
    final relayLogBox = Hive.box(AppConstants.boxRelayLog);

    await relayLogBox.put(alert.alertId, DateTime.now().toIso8601String());
    await alertsBox.put(alert.alertId, alert.toJson());
  }

  static Future<void> clearAlerts() async {
    await Hive.box(AppConstants.boxAlerts).clear();
  }

  static bool isAlertRelayed(String alertId) {
    return Hive.box(AppConstants.boxRelayLog).containsKey(alertId);
  }

  static bool hasAlert(String alertId) {
    try {
      final alertsBox = Hive.box(AppConstants.boxAlerts);
      return alertsBox.containsKey(alertId);
    } catch (_) {
      return false;
    }
  }

  static int getUnsyncedAlertsCount() {
    try {
      final alertsBox = Hive.box(AppConstants.boxAlerts);
      final syncLogBox = Hive.isBoxOpen('firebase_sync_log')
          ? Hive.box('firebase_sync_log')
          : null;
      if (syncLogBox == null) return alertsBox.length;

      int unsynced = 0;
      for (var key in alertsBox.keys) {
        if (!syncLogBox.containsKey(key)) {
          unsynced++;
        }
      }
      return unsynced;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markAlertAsSynced(String alertId) async {
    try {
      final syncLogBox = await Hive.openBox('firebase_sync_log');
      await syncLogBox.put(alertId, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<void> logRelayedAlert(String alertId) async {
    await Hive.box(AppConstants.boxRelayLog).put(alertId, DateTime.now().toIso8601String());
  }

  static List<Map<String, String>> getChatMessages() {
    try {
      final box = Hive.box(AppConstants.boxChatMessages);
      List<Map<String, String>> loaded = [];
      for (var key in box.keys) {
        final val = box.get(key);
        if (val != null && val is Map) {
          loaded.add(Map<String, String>.from(val));
        }
      }
      return loaded;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveChatMessage(String sender, String text) async {
    final box = Hive.box(AppConstants.boxChatMessages);
    final msgObj = {
      'sender': sender,
      'text': text,
      'time': DateTime.now().toIso8601String().substring(11, 16),
    };
    await box.add(msgObj);
  }

  static Future<void> preloadDemoDataset() async {
    final alertsBox = Hive.box(AppConstants.boxAlerts);
    final relayLogBox = Hive.box(AppConstants.boxRelayLog);

    List<EmergencyAlert> samples = [
      EmergencyAlert(
        alertId: "ALERT_DEMO_001",
        senderId: "Victim_Phone_A",
        alertType: AppConstants.typeMedical,
        severity: AppConstants.severityCritical,
        location: {'lat': 28.7585, 'lng': 77.1093},
        description: "🚨 Severe Road Accident near Tihar Gate 3!",
        timestamp: "2026-08-13 14:50:00",
        ttlHops: 4,
      ),
      EmergencyAlert(
        alertId: "ALERT_DEMO_002",
        senderId: "Node_Phone_B",
        alertType: AppConstants.typeSecurity,
        severity: AppConstants.severityCritical,
        location: {'lat': 28.7590, 'lng': 77.1105},
        description: "⚠️ Active Jammer Zone Security Alert!",
        timestamp: "2026-08-13 14:52:10",
        ttlHops: 3,
      ),
      EmergencyAlert(
        alertId: "ALERT_DEMO_003",
        senderId: "Student_Node_C",
        alertType: AppConstants.typeFire,
        severity: AppConstants.severityHigh,
        location: {'lat': 28.7570, 'lng': 77.1080},
        description: "🔥 Electrical Fire in Lab 3 Block",
        timestamp: "2026-08-13 14:55:00",
        ttlHops: 5,
      ),
      EmergencyAlert(
        alertId: "ALERT_DEMO_004",
        senderId: "Responder_Group_1",
        alertType: AppConstants.typeMedical,
        severity: AppConstants.severityModerate,
        location: {'lat': 28.7601, 'lng': 77.1120},
        description: "🩺 First-aid kit dispatched to location",
        timestamp: "2026-08-13 14:58:30",
        ttlHops: 2,
      ),
    ];

    for (var sample in samples) {
      await relayLogBox.put(sample.alertId, DateTime.now().toIso8601String());
      await alertsBox.put(sample.alertId, sample.toJson());
    }
  }

  static List<Map<String, String>> getEmergencyContacts() {
    try {
      final box = Hive.box('emergency_contacts');
      List<Map<String, String>> contacts = [];
      for (var key in box.keys) {
        final val = box.get(key);
        if (val != null && val is Map) {
          contacts.add(Map<String, String>.from(val));
        }
      }
      if (contacts.isEmpty) {
        // Default Emergency Contacts
        return [
          {'name': 'Police Control Room', 'phone': '112', 'relation': 'National Police'},
          {'name': 'Women Safety Helpline', 'phone': '1091', 'relation': 'Emergency Cell'},
        ];
      }
      return contacts;
    } catch (_) {
      return [
        {'name': 'Police Control Room', 'phone': '112', 'relation': 'National Police'},
      ];
    }
  }

  static Future<void> saveEmergencyContact(String name, String phone, String relation) async {
    final box = Hive.box('emergency_contacts');
    await box.add({
      'name': name,
      'phone': phone,
      'relation': relation,
    });
  }

  static Future<void> deleteEmergencyContact(int index) async {
    final box = Hive.box('emergency_contacts');
    await box.deleteAt(index);
  }
}

