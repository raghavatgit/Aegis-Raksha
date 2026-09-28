import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/location_helper.dart';
import '../../data/local/hive_storage_service.dart';
import '../../data/models/emergency_alert.dart';
import '../../services/emergency_services_dispatcher.dart';
import '../widgets/saved_alerts_list.dart';

class TrustedCircleScreen extends StatefulWidget {
  final List<EmergencyAlert> savedAlerts;
  final VoidCallback onReloadData;

  const TrustedCircleScreen({
    super.key,
    required this.savedAlerts,
    required this.onReloadData,
  });

  @override
  State<TrustedCircleScreen> createState() => _TrustedCircleScreenState();
}

class _TrustedCircleScreenState extends State<TrustedCircleScreen> {
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  void _loadContacts() {
    setState(() {
      _contacts = HiveStorageService.getEmergencyContacts();
    });
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add Trusted Contact",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Name (e.g. Mother, Partner)",
                labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Mobile Number",
                labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: relationCtrl,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                labelText: "Relation / Note",
                labelStyle: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBerry,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                await HiveStorageService.saveEmergencyContact(
                  nameCtrl.text.trim(),
                  phoneCtrl.text.trim(),
                  relationCtrl.text.trim().isEmpty ? "Guardian" : relationCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                _loadContacts();
              }
            },
            child: Text("Save Contact", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _shareLiveLocationToAll() async {
    try {
      final loc = await LocationHelper.getCurrentCoordinates();
      final lat = loc['lat'] ?? 0.0;
      final lng = loc['lng'] ?? 0.0;
      final mapsUrl = "https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}";

      if (_contacts.isNotEmpty) {
        final firstPhone = _contacts.first['phone'] ?? '112';
        EmergencyServicesDispatcher.sendEmergencySms(
          recipient: firstPhone,
          lat: lat,
          lng: lng,
          emergencyType: "LIVE_LOCATION_SHARE",
          note: "Sharing my live safety location: $mapsUrl",
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Trusted Circle",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    "People who receive your instant GPS distress alerts",
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.lightBlush,
                  foregroundColor: AppTheme.primaryBerry,
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                onPressed: _showAddContactDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Share Live Location Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB80046), Color(0xFFD81B60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBerry.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_location_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Share Live Location",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        "Send current GPS maps link to your circle via SMS",
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryBerry,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _shareLiveLocationToAll,
                  child: Text("Send", style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Contacts List
          Text(
            "Saved Guardians (${_contacts.length})",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final contact = _contacts[index];
              final name = contact['name'] ?? 'Contact';
              final phone = contact['phone'] ?? '';
              final relation = contact['relation'] ?? 'Guardian';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.blushPink.withOpacity(0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.lightBlush,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'G',
                        style: GoogleFonts.poppins(color: AppTheme.primaryBerry, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            "$phone • $relation",
                            style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.call, color: AppTheme.safeGreen, size: 20),
                      onPressed: () => EmergencyServicesDispatcher.dialNumber(phone),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message_outlined, color: AppTheme.primaryBerry, size: 20),
                      onPressed: () async {
                        final loc = await LocationHelper.getCurrentCoordinates();
                        EmergencyServicesDispatcher.sendEmergencySms(
                          recipient: phone,
                          lat: loc['lat'] ?? 0.0,
                          lng: loc['lng'] ?? 0.0,
                          emergencyType: "GUARDIAN_CHECKIN",
                          note: "I am sharing my current location with you.",
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Dispatched Alerts History
          SavedAlertsList(
            savedAlerts: widget.savedAlerts,
            onPreloadDemo: () async {
              await HiveStorageService.preloadDemoDataset();
              widget.onReloadData();
            },
            onClear: () async {
              await HiveStorageService.clearAlerts();
              widget.onReloadData();
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
