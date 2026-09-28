import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';

enum EmergencyServiceType {
  police112(
    code: '112',
    title: 'Police & Emergency (112)',
    shortName: 'Police 112',
    iconName: 'local_police',
    category: 'POLICE',
    description: 'National Police, Fire & All-in-one Emergency Dispatch',
    targetAgency: 'POLICE_CONTROL_ROOM_112',
  ),
  police100(
    code: '100',
    title: 'Police Control Room (100)',
    shortName: 'Police PCR',
    iconName: 'security',
    category: 'POLICE',
    description: 'City & State Police Patrol Hotline',
    targetAgency: 'POLICE_PCR_100',
  ),
  womenHelpline(
    code: '1091',
    title: 'Women Safety Helpline (1091)',
    shortName: 'Women 1091',
    iconName: 'female',
    category: 'WOMEN_SAFETY',
    description: 'Emergency assistance for women in distress & harassment',
    targetAgency: 'WOMEN_SAFETY_CELL_1091',
  ),
  ambulance108(
    code: '108',
    title: 'Ambulance & Medical (108)',
    shortName: 'Ambulance 108',
    iconName: 'emergency',
    category: 'MEDICAL',
    description: 'Disaster & Medical Trauma Dispatch',
    targetAgency: 'AMBULANCE_108',
  ),
  fire101(
    code: '101',
    title: 'Fire & Rescue (101)',
    shortName: 'Fire 101',
    iconName: 'local_fire_department',
    category: 'FIRE',
    description: 'Fire hazard & building evacuation services',
    targetAgency: 'FIRE_DEPARTMENT_101',
  ),
  childline1098(
    code: '1098',
    title: 'Childline Emergency (1098)',
    shortName: 'Childline',
    iconName: 'child_care',
    category: 'CHILD_SAFETY',
    description: 'Child abuse & missing child rapid rescue',
    targetAgency: 'CHILDLINE_1098',
  ),
  roadAccident1073(
    code: '1073',
    title: 'National Highway Emergency (1073)',
    shortName: 'Highway Patrol',
    iconName: 'car_crash',
    category: 'HIGHWAY',
    description: 'High-speed transit highway trauma & escort support',
    targetAgency: 'HIGHWAY_PATROL_1073',
  ),
  railwayHelpline139(
    code: '139',
    title: 'Railway Security Helpline (139)',
    shortName: 'Railway Police',
    iconName: 'train',
    category: 'TRANSIT',
    description: 'RPF train & metro transit harassment response',
    targetAgency: 'RAILWAY_POLICE_139',
  ),
  disaster1070(
    code: '1070',
    title: 'Disaster Relief Hotline (1070)',
    shortName: 'Disaster 1070',
    iconName: 'flood',
    category: 'DISASTER',
    description: 'NDRF flood, earthquake & severe disaster evacuation hotline',
    targetAgency: 'DISASTER_MANAGEMENT_1070',
  );

  final String code;
  final String title;
  final String shortName;
  final String iconName;
  final String category;
  final String description;
  final String targetAgency;

  const EmergencyServiceType({
    required this.code,
    required this.title,
    required this.shortName,
    required this.iconName,
    required this.category,
    required this.description,
    required this.targetAgency,
  });
}

class EmergencyServicesDispatcher {
  /// Directly initiate a phone dial to an emergency authority
  static Future<bool> dialNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanNumber);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("EmergencyServicesDispatcher dialNumber error: $e");
    }
    return false;
  }

  /// Initiate call directly for an EmergencyServiceType
  static Future<bool> dialService(EmergencyServiceType service) async {
    return dialNumber(service.code);
  }

  /// Send an Emergency SOS SMS with live GPS coordinates
  static Future<bool> sendEmergencySms({
    required String recipient,
    required double lat,
    required double lng,
    String? emergencyType,
    String? customNote,
    String? note,
  }) async {
    final cleanRecipient = recipient.replaceAll(RegExp(r'[^0-9+]'), '');
    final mapsUrl = "https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}";
    final effectiveNote = customNote ?? note;

    final String messageBody =
        "EMERGENCY SOS ALERT!\n"
        "Type: ${emergencyType ?? 'Distress/Safety'}\n"
        "Live GPS: $mapsUrl\n"
        "${effectiveNote != null && effectiveNote.isNotEmpty ? 'Note: $effectiveNote\n' : ''}"
        "Sent via RakshaNet Zero-Internet Emergency Mesh";

    final Uri uri = Uri(
      scheme: 'sms',
      path: cleanRecipient,
      queryParameters: {'body': messageBody},
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("EmergencyServicesDispatcher sendEmergencySms error: $e");
    }
    return false;
  }

  /// Open GPS coordinates in Google Maps or default navigation app
  static Future<bool> openLocationInMaps({
    required double lat,
    required double lng,
  }) async {
    final Uri uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("EmergencyServicesDispatcher openLocationInMaps error: $e");
    }
    return false;
  }

  /// File an Urgent Emergency Dispatch Ticket into Firebase Realtime Database
  static Future<bool> fileEmergencyDispatchTicket({
    required String ticketId,
    required EmergencyServiceType serviceType,
    required double lat,
    required double lng,
    String? description,
    int? batteryLevel,
    String? senderDevice,
  }) async {
    try {
      final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
      final now = DateTime.now().toIso8601String();
      final mapsUrl = "https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}";

      final Map<String, dynamic> dispatchPayload = {
        'ticketId': ticketId,
        'serviceCode': serviceType.code,
        'serviceTitle': serviceType.title,
        'targetAgency': serviceType.targetAgency,
        'category': serviceType.category,
        'priority': 'CRITICAL_URGENT',
        'status': 'OPEN_PENDING_RESPONSE',
        'latitude': lat,
        'longitude': lng,
        'googleMapsUrl': mapsUrl,
        'deviceBattery': batteryLevel ?? 100,
        'senderDevice': senderDevice ?? 'Raksha-Net Mobile Node',
        'description': description ?? 'Immediate emergency services required at GPS location.',
        'createdAt': now,
        'source': 'RAKSHA_NET_HYBRID_ENGINE',
      };

      await dbRef.child('emergency_dispatch_requests').child(ticketId).set(dispatchPayload);
      return true;
    } catch (e) {
      debugPrint("EmergencyServicesDispatcher fileEmergencyDispatchTicket error: $e");
      return false;
    }
  }
}
