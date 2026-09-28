import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/emergency_alert.dart';

class FirebaseSyncService {
  static FirebaseDatabase? _db;

  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp();
      _db = FirebaseDatabase.instance;
      print("☁️ Firebase initialized successfully!");
    } catch (e) {
      print("⚠️ Firebase initialization notice: $e");
    }
  }

  /// Instantly publish alert AND create urgent emergency services dispatch ticket
  static Future<bool> publishAlertNow(EmergencyAlert alert, {String gatewayId = "Primary_Victim_Node"}) async {
    try {
      if (_db == null) {
        await initFirebase();
      }
      if (_db == null) return false;

      final syncLogBox = await Hive.openBox('firebase_sync_log');
      
      // 1. Store core incident data
      await _db!.ref('emergency_alerts/${alert.alertId}').set(alert.toJson());

      // 2. Dispatch urgent emergency services request ticket
      await _db!.ref('emergency_dispatch_requests/${alert.alertId}').set({
        'alert_id': alert.alertId,
        'victim_id': alert.senderId,
        'gateway_node_relayed_by': gatewayId,
        'incident_type': alert.alertType,
        'severity': alert.severity,
        'note': alert.description,
        'status': 'URGENT_DISPATCH_REQUESTED',
        'dispatch_targets': ['POLICE_112', 'AMBULANCE_108', 'FIRE_101', 'EMERGENCY_CONTACTS'],
        'coordinates': {
          'latitude': alert.location['lat'],
          'longitude': alert.location['lng'],
          'google_maps_link': 'https://www.google.com/maps/search/?api=1&query=${alert.location['lat']},${alert.location['lng']}',
        },
        'incident_timestamp': alert.timestamp,
        'cloud_received_timestamp': DateTime.now().toIso8601String(),
      });

      await syncLogBox.put(alert.alertId, DateTime.now().toIso8601String());
      print("☁️ Instantly published alert & dispatched emergency services for ${alert.alertId}!");
      return true;
    } catch (e) {
      print("⚠️ Instant Firebase publish skipped (Offline): $e");
      return false;
    }
  }

  /// Store-and-forward engine: Relays all offline-cached alerts when ANY node gets internet
  static Future<int> syncOfflineAlerts({String gatewayNodeId = "Mesh_Relay_Node_B"}) async {
    int syncedCount = 0;
    try {
      if (_db == null) {
        await initFirebase();
      }
      if (_db == null) return 0;

      final alertsBox = Hive.box('alerts');
      final syncLogBox = await Hive.openBox('firebase_sync_log');

      for (var key in alertsBox.keys) {
        final alertData = alertsBox.get(key);
        if (alertData != null && alertData is Map) {
          final alert = EmergencyAlert.fromJson(Map<String, dynamic>.from(alertData));
          
          if (!syncLogBox.containsKey(alert.alertId)) {
            // Upload to Cloud & Dispatch Authorities
            await publishAlertNow(alert, gatewayId: gatewayNodeId);
            syncedCount++;
            print("☁️ Synced offline alert ${alert.alertId} via Gateway $gatewayNodeId to Cloud DB & Emergency Dispatch!");
          }
        }
      }
    } catch (e) {
      print("⚠️ Firebase sync skipped (Offline Mode): $e");
    }
    return syncedCount;
  }
}
